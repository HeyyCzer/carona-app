package me.rafaelpereira.caronaapp.services

import me.rafaelpereira.caronaapp.controllers.dto.CreateRideRequestDto
import me.rafaelpereira.caronaapp.controllers.dto.LocationDto
import me.rafaelpereira.caronaapp.controllers.dto.PersonDto
import me.rafaelpereira.caronaapp.controllers.dto.RideRequestResponseDto
import me.rafaelpereira.caronaapp.models.BookingStatus
import me.rafaelpereira.caronaapp.models.RideRequest
import me.rafaelpereira.caronaapp.models.RideRequestStatus
import me.rafaelpereira.caronaapp.models.RideStatus
import me.rafaelpereira.caronaapp.repositories.BookingRepository
import me.rafaelpereira.caronaapp.repositories.RideRepository
import me.rafaelpereira.caronaapp.repositories.RideRequestRepository
import me.rafaelpereira.caronaapp.repositories.UserRepository
import me.rafaelpereira.caronaapp.utils.Geo
import org.springframework.data.repository.findByIdOrNull
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.server.ResponseStatusException

@Service
class RideRequestService(
    private val rideRequestRepository: RideRequestRepository,
    private val rideRepository: RideRepository,
    private val bookingRepository: BookingRepository,
    private val userRepository: UserRepository,
    private val rideService: RideService
) {

    @Transactional
    fun create(passengerId: Long, rideId: Long, dto: CreateRideRequestDto): RideRequestResponseDto {
        val ride = rideService.findRide(rideId)

        if (ride.driver.id == passengerId) {
            throw ResponseStatusException(HttpStatus.UNPROCESSABLE_CONTENT, "Você não pode pedir vaga na sua própria carona")
        }
        if (ride.status != RideStatus.SCHEDULED || rideService.hasDeparted(ride)) {
            throw ResponseStatusException(HttpStatus.CONFLICT, "Essa carona não está mais disponível")
        }
        if (rideService.seatsAvailable(ride) <= 0) {
            throw ResponseStatusException(HttpStatus.CONFLICT, "Essa carona está lotada")
        }
        if (bookingRepository.existsByRideIdAndRequestPassengerIdAndStatus(rideId, passengerId, BookingStatus.CONFIRMED)) {
            throw ResponseStatusException(HttpStatus.CONFLICT, "Você já tem vaga nessa carona")
        }
        if (rideRequestRepository.existsByRideIdAndPassengerIdAndStatus(rideId, passengerId, RideRequestStatus.PENDING)) {
            throw ResponseStatusException(HttpStatus.CONFLICT, "Você já pediu vaga nessa carona")
        }

        val pickup = dto.pickup.toModel()
        val request = rideRequestRepository.save(
            RideRequest(
                passenger = userRepository.getReferenceById(passengerId),
                ride = ride,
                recurring = dto.recurring,
                pickup = pickup,
                detourMeters = Geo.detourMeters(ride.from, ride.to, pickup)
            )
        )
        return toResponse(request)
    }

    /** Pedidos recebidos nas rotas do motorista (por padrão, os pendentes). */
    @Transactional(readOnly = true)
    fun received(driverId: Long, status: RideRequestStatus?): List<RideRequestResponseDto> =
        rideRequestRepository
            .findByRideRouteDriverIdAndStatusOrderByCreatedAtAsc(driverId, status ?: RideRequestStatus.PENDING)
            .map(::toResponse)

    @Transactional(readOnly = true)
    fun mine(passengerId: Long): List<RideRequestResponseDto> =
        rideRequestRepository.findByPassengerIdOrderByCreatedAtDesc(passengerId).map(::toResponse)

    /**
     * Aceita o pedido e reserva as vagas: só na carona pedida ou, se recorrente,
     * em todas as próximas caronas da rota no mesmo sentido que ainda têm lugar.
     */
    @Transactional
    fun accept(driverId: Long, id: Long): RideRequestResponseDto {
        val request = findPendingAsDriver(driverId, id)

        val rides = if (request.recurring) {
            rideRepository.findByRouteIdAndDirectionAndDateGreaterThanEqualAndStatusOrderByDateAsc(
                request.route.id!!, request.ride.direction, request.ride.date, RideStatus.SCHEDULED
            )
        } else {
            listOf(request.ride)
        }
        val booked = rides.count { rideService.tryBook(it, request) }
        if (booked == 0) {
            throw ResponseStatusException(HttpStatus.CONFLICT, "Não há vagas disponíveis para esse pedido")
        }

        request.status = RideRequestStatus.ACCEPTED
        return toResponse(request)
    }

    @Transactional
    fun reject(driverId: Long, id: Long): RideRequestResponseDto {
        val request = findPendingAsDriver(driverId, id)
        request.status = RideRequestStatus.REJECTED
        return toResponse(request)
    }

    /** Passageiro desiste do pedido; as vagas futuras já reservadas por ele são liberadas. */
    @Transactional
    fun cancel(passengerId: Long, id: Long): RideRequestResponseDto {
        val request = findRequest(id)
        if (request.passenger.id != passengerId) {
            throw ResponseStatusException(HttpStatus.FORBIDDEN, "Esse pedido não é seu")
        }
        if (request.status != RideRequestStatus.PENDING && request.status != RideRequestStatus.ACCEPTED) {
            throw ResponseStatusException(HttpStatus.CONFLICT, "Esse pedido não pode mais ser cancelado")
        }

        request.status = RideRequestStatus.CANCELLED
        bookingRepository.findByRequestIdAndStatus(id, BookingStatus.CONFIRMED)
            .filter { !rideService.hasDeparted(it.ride) }
            .forEach { it.status = BookingStatus.CANCELLED }
        return toResponse(request)
    }

    private fun findRequest(id: Long): RideRequest = rideRequestRepository.findByIdOrNull(id)
        ?: throw ResponseStatusException(HttpStatus.NOT_FOUND, "Pedido não encontrado")

    private fun findPendingAsDriver(driverId: Long, id: Long): RideRequest {
        val request = findRequest(id)
        if (request.route.driver.id != driverId) {
            throw ResponseStatusException(HttpStatus.FORBIDDEN, "Esse pedido não é para uma rota sua")
        }
        if (request.status != RideRequestStatus.PENDING) {
            throw ResponseStatusException(HttpStatus.CONFLICT, "Esse pedido já foi respondido")
        }
        return request
    }

    private fun toResponse(request: RideRequest) = RideRequestResponseDto(
        id = request.id!!,
        ride = rideService.toResponse(request.ride),
        passenger = PersonDto.from(request.passenger),
        recurring = request.recurring,
        weekdays = if (request.recurring) request.route.weekdays.sorted() else listOf(request.ride.date.dayOfWeek),
        pickup = LocationDto.from(request.pickup),
        detourMeters = request.detourMeters,
        detourMinutes = Geo.travelMinutes(request.detourMeters),
        status = request.status,
        createdAt = request.createdAt
    )

}
