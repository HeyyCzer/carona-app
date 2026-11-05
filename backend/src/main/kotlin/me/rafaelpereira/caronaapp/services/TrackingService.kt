package me.rafaelpereira.caronaapp.services

import me.rafaelpereira.caronaapp.controllers.dto.RideLocationDto
import me.rafaelpereira.caronaapp.controllers.dto.UpdateLocationDto
import me.rafaelpereira.caronaapp.models.BookingStatus
import me.rafaelpereira.caronaapp.models.Ride
import me.rafaelpereira.caronaapp.models.VehicleLocation
import me.rafaelpereira.caronaapp.repositories.BookingRepository
import org.springframework.context.ApplicationEventPublisher
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.server.ResponseStatusException
import java.time.Clock

/** Publicado quando o motorista envia uma posição nova; entregue pelo WebSocket depois do commit. */
data class RideLocationEvent(val location: RideLocationDto)

/**
 * Acompanhamento do carro em tempo real: o app do motorista envia a posição durante a viagem
 * e os passageiros da carona recebem cada atualização pelo WebSocket `/ws/tracking`.
 */
@Service
class TrackingService(
    private val rideService: RideService,
    private val bookingRepository: BookingRepository,
    private val rules: RideRules,
    private val events: ApplicationEventPublisher,
    private val clock: Clock
) {

    @Transactional
    fun update(driverId: Long, rideId: Long, dto: UpdateLocationDto): RideLocationDto {
        val ride = rideService.findRide(rideId)
        if (ride.driver.id != driverId) {
            throw ResponseStatusException(HttpStatus.FORBIDDEN, "Você não é o motorista dessa carona")
        }
        if (!rules.isInProgressWindow(ride)) {
            throw ResponseStatusException(HttpStatus.CONFLICT, "A localização só é compartilhada durante a viagem")
        }

        ride.driverLocation = VehicleLocation(dto.latitude, dto.longitude, dto.heading, dto.speedMps, clock.instant())
        val location = RideLocationDto.from(ride)!!
        events.publishEvent(RideLocationEvent(location))
        return location
    }

    /** Última posição conhecida, ou nula se a viagem não está em andamento ou o motorista ainda não enviou nenhuma. */
    @Transactional(readOnly = true)
    fun get(userId: Long, rideId: Long): RideLocationDto? {
        val ride = rideService.findRide(rideId)
        if (!canWatch(userId, ride)) {
            throw ResponseStatusException(HttpStatus.FORBIDDEN, "Você não está nessa carona")
        }
        return if (rules.isInProgressWindow(ride)) RideLocationDto.from(ride) else null
    }

    @Transactional(readOnly = true)
    fun canWatch(userId: Long, rideId: Long): Boolean =
        runCatching { rideService.findRide(rideId) }.getOrNull()?.let { canWatch(userId, it) } ?: false

    /** O motorista e os passageiros com vaga ativa (quem cancelou ou não confirmou não acompanha). */
    private fun canWatch(userId: Long, ride: Ride): Boolean =
        ride.driver.id == userId ||
            bookingRepository.existsByRideIdAndRequestPassengerIdAndStatus(ride.id!!, userId, BookingStatus.CONFIRMED)

}
