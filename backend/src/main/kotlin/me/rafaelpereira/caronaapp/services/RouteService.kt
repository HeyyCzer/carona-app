package me.rafaelpereira.caronaapp.services

import me.rafaelpereira.caronaapp.controllers.dto.CreateRouteDto
import me.rafaelpereira.caronaapp.controllers.dto.RouteResponseDto
import me.rafaelpereira.caronaapp.models.RideRequestStatus
import me.rafaelpereira.caronaapp.models.RideStatus
import me.rafaelpereira.caronaapp.models.Route
import me.rafaelpereira.caronaapp.repositories.RideRepository
import me.rafaelpereira.caronaapp.repositories.RideRequestRepository
import me.rafaelpereira.caronaapp.repositories.RouteRepository
import me.rafaelpereira.caronaapp.repositories.UserRepository
import org.springframework.data.repository.findByIdOrNull
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.server.ResponseStatusException
import java.time.Clock
import java.time.LocalDate

@Service
class RouteService(
    private val routeRepository: RouteRepository,
    private val rideRepository: RideRepository,
    private val rideRequestRepository: RideRequestRepository,
    private val userRepository: UserRepository,
    private val rideService: RideService,
    private val clock: Clock
) {

    @Transactional
    fun create(driverId: Long, dto: CreateRouteDto): RouteResponseDto {
        val route = routeRepository.save(
            Route(
                driver = userRepository.getReferenceById(driverId),
                origin = dto.origin.toModel(),
                destination = dto.destination.toModel(),
                weekdays = dto.weekdays.toMutableSet(),
                outboundTime = dto.outboundTime,
                returnTime = dto.returnTime,
                maxDetourMeters = dto.maxDetourMeters,
                seats = dto.seats,
                priceCents = dto.priceCents
            )
        )
        rideService.generateRides(route)
        return RouteResponseDto.from(route)
    }

    @Transactional(readOnly = true)
    fun mine(driverId: Long): List<RouteResponseDto> =
        routeRepository.findByDriverIdAndActiveTrueOrderByCreatedAtDesc(driverId).map(RouteResponseDto::from)

    @Transactional(readOnly = true)
    fun get(driverId: Long, id: Long): RouteResponseDto = RouteResponseDto.from(findOwnRoute(driverId, id))

    /** Desativa a rota, cancelando as próximas caronas e recusando os pedidos pendentes. */
    @Transactional
    fun deactivate(driverId: Long, id: Long) {
        val route = findOwnRoute(driverId, id)
        route.active = false

        rideRepository.findByRouteIdAndDateGreaterThanEqualAndStatus(id, LocalDate.now(clock), RideStatus.SCHEDULED)
            .filter { !rideService.hasDeparted(it) }
            .forEach { it.status = RideStatus.CANCELLED }
        rideRequestRepository.findByRideRouteIdAndStatus(id, RideRequestStatus.PENDING)
            .forEach { it.status = RideRequestStatus.REJECTED }
    }

    private fun findOwnRoute(driverId: Long, id: Long): Route {
        val route = routeRepository.findByIdOrNull(id)
            ?: throw ResponseStatusException(HttpStatus.NOT_FOUND, "Rota não encontrada")
        if (route.driver.id != driverId) {
            throw ResponseStatusException(HttpStatus.FORBIDDEN, "Essa rota não é sua")
        }
        return route
    }

}
