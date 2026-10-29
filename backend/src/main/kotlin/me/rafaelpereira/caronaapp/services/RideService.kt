package me.rafaelpereira.caronaapp.services

import me.rafaelpereira.caronaapp.controllers.dto.LocationDto
import me.rafaelpereira.caronaapp.controllers.dto.RideResponseDto
import me.rafaelpereira.caronaapp.controllers.dto.RideSearchResultDto
import me.rafaelpereira.caronaapp.models.Booking
import me.rafaelpereira.caronaapp.models.BookingStatus
import me.rafaelpereira.caronaapp.models.Location
import me.rafaelpereira.caronaapp.models.Ride
import me.rafaelpereira.caronaapp.models.RideDirection
import me.rafaelpereira.caronaapp.models.RideRequest
import me.rafaelpereira.caronaapp.models.RideRequestStatus
import me.rafaelpereira.caronaapp.models.RideStatus
import me.rafaelpereira.caronaapp.models.Route
import me.rafaelpereira.caronaapp.repositories.BookingRepository
import me.rafaelpereira.caronaapp.repositories.RideRepository
import me.rafaelpereira.caronaapp.repositories.RideRequestRepository
import me.rafaelpereira.caronaapp.repositories.RouteRepository
import me.rafaelpereira.caronaapp.utils.Geo
import org.springframework.data.repository.findByIdOrNull
import org.springframework.http.HttpStatus
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.server.ResponseStatusException
import java.time.Clock
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import kotlin.math.roundToInt

@Service
class RideService(
    private val rideRepository: RideRepository,
    private val routeRepository: RouteRepository,
    private val rideRequestRepository: RideRequestRepository,
    private val bookingRepository: BookingRepository,
    private val clock: Clock
) {

    /**
     * Cria as caronas da rota para os próximos [GENERATION_DAYS] dias, ignorando as que já existem,
     * e já reserva vaga para os passageiros com pedido recorrente aceito.
     */
    @Transactional
    fun generateRides(route: Route) {
        if (!route.active) return
        val today = LocalDate.now(clock)

        for (offset in 0..GENERATION_DAYS) {
            val date = today.plusDays(offset)
            if (date.dayOfWeek !in route.weekdays) continue

            for (direction in RideDirection.entries) {
                val departure = route.departureTime(direction) ?: continue
                if (!LocalDateTime.of(date, departure).isAfter(LocalDateTime.now(clock))) continue
                if (rideRepository.existsByRouteIdAndDateAndDirection(route.id!!, date, direction)) continue

                val ride = rideRepository.save(
                    Ride(route, direction, date, departure, route.seats, route.priceCents)
                )
                rideRequestRepository
                    .findByRideRouteIdAndRideDirectionAndStatusAndRecurringTrue(
                        route.id!!, direction, RideRequestStatus.ACCEPTED
                    )
                    .filter { !it.ride.date.isAfter(date) }
                    .forEach { tryBook(ride, it) }
            }
        }
    }

    @Scheduled(cron = "0 0 3 * * *", zone = "\${app.timezone}")
    @Transactional
    fun generateAllRides() {
        routeRepository.findByActiveTrue().forEach(::generateRides)
    }

    /** Reserva uma vaga na carona para o pedido, se ainda houver lugar. */
    fun tryBook(ride: Ride, request: RideRequest): Boolean {
        if (ride.status != RideStatus.SCHEDULED || hasDeparted(ride) || seatsAvailable(ride) <= 0) return false
        if (bookingRepository.existsByRideIdAndRequestPassengerIdAndStatus(
                ride.id!!, request.passenger.id!!, BookingStatus.CONFIRMED
            )
        ) return false

        bookingRepository.save(Booking(ride, request, ride.priceCents))
        return true
    }

    /**
     * Caronas do dia que passam perto da origem e do destino do passageiro, no sentido certo.
     * "Perto" é o desvio máximo que o motorista aceita, medido até a linha reta do trajeto.
     */
    @Transactional(readOnly = true)
    fun search(userId: Long, origin: Location, destination: Location, date: LocalDate?): List<RideSearchResultDto> {
        val searchDate = date ?: LocalDate.now(clock)

        return rideRepository.findByDateAndStatusOrderByDepartureTimeAsc(searchDate, RideStatus.SCHEDULED)
            .asSequence()
            .filter { it.driver.id != userId && !hasDeparted(it) }
            .mapNotNull { ride ->
                val pickup = Geo.project(origin, ride.from, ride.to)
                val dropoff = Geo.project(destination, ride.from, ride.to)
                val maxDistance = ride.route.maxDetourMeters
                if (pickup.distanceMeters > maxDistance || dropoff.distanceMeters > maxDistance) return@mapNotNull null
                if (pickup.fraction > dropoff.fraction) return@mapNotNull null

                val seatsAvailable = seatsAvailable(ride)
                if (seatsAvailable <= 0) return@mapNotNull null

                RideSearchResultDto(
                    ride = RideResponseDto.from(ride, seatsAvailable),
                    distanceFromYouMeters = pickup.distanceMeters.roundToInt(),
                    pickupPoint = LocationDto.from(pickup.point),
                    estimatedPickupTime = ride.departureTime.plusMinutes(
                        Geo.travelMinutes(Geo.roadDistanceMeters(ride.from, pickup.point))
                    )
                )
            }
            .toList()
    }

    @Transactional(readOnly = true)
    fun get(id: Long): RideResponseDto = toResponse(findRide(id))

    /** Próximas caronas em que o usuário é o motorista. */
    @Transactional(readOnly = true)
    fun upcomingAsDriver(driverId: Long): List<RideResponseDto> =
        rideRepository.findByRouteDriverIdAndDateGreaterThanEqualAndStatusOrderByDateAscDepartureTimeAsc(
            driverId, LocalDate.now(clock), RideStatus.SCHEDULED
        )
            .filter { !hasDeparted(it) }
            .map(::toResponse)

    @Transactional
    fun cancel(driverId: Long, id: Long): RideResponseDto {
        val ride = findRide(id)
        requireDriver(ride, driverId)
        if (ride.status != RideStatus.SCHEDULED || hasDeparted(ride)) {
            throw ResponseStatusException(HttpStatus.CONFLICT, "Só é possível cancelar caronas que ainda não saíram")
        }
        ride.status = RideStatus.CANCELLED
        return toResponse(ride)
    }

    /** Marca a carona como realizada; as vagas confirmadas passam a contar nos recebimentos. */
    @Transactional
    fun complete(driverId: Long, id: Long): RideResponseDto {
        val ride = findRide(id)
        requireDriver(ride, driverId)
        if (ride.status != RideStatus.SCHEDULED || !hasDeparted(ride)) {
            throw ResponseStatusException(HttpStatus.CONFLICT, "Só é possível concluir caronas que já saíram")
        }
        ride.status = RideStatus.COMPLETED
        return toResponse(ride)
    }

    fun findRide(id: Long): Ride = rideRepository.findByIdOrNull(id)
        ?: throw ResponseStatusException(HttpStatus.NOT_FOUND, "Carona não encontrada")

    fun seatsAvailable(ride: Ride): Int =
        ride.seats - bookingRepository.countByRideIdAndStatus(ride.id!!, BookingStatus.CONFIRMED).toInt()

    fun hasDeparted(ride: Ride): Boolean =
        !LocalDateTime.of(ride.date, ride.departureTime).isAfter(LocalDateTime.now(clock))

    fun toResponse(ride: Ride) = RideResponseDto.from(ride, seatsAvailable(ride))

    private fun requireDriver(ride: Ride, userId: Long) {
        if (ride.driver.id != userId) {
            throw ResponseStatusException(HttpStatus.FORBIDDEN, "Você não é o motorista dessa carona")
        }
    }

    companion object {
        const val GENERATION_DAYS = 14L
    }

}
