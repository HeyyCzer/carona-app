package me.rafaelpereira.caronaapp.services

import me.rafaelpereira.caronaapp.config.RideRulesProperties
import me.rafaelpereira.caronaapp.models.Booking
import me.rafaelpereira.caronaapp.models.BookingStage
import me.rafaelpereira.caronaapp.models.BookingStatus
import me.rafaelpereira.caronaapp.models.Ride
import me.rafaelpereira.caronaapp.models.RideStatus
import org.springframework.stereotype.Component
import java.time.Clock
import java.time.LocalDateTime

/** Regras de tempo de uma carona: janela de confirmação de presença, embarque e rastreamento. */
@Component
class RideRules(
    private val properties: RideRulesProperties,
    private val clock: Clock
) {

    fun now(): LocalDateTime = LocalDateTime.now(clock)

    fun confirmationOpensAt(ride: Ride): LocalDateTime = ride.departure.minus(properties.confirmationOpensBefore)

    fun confirmationDeadline(ride: Ride): LocalDateTime = ride.departure.minus(properties.confirmationDeadlineBefore)

    fun isConfirmationOpen(ride: Ride): Boolean {
        val now = now()
        return !now.isBefore(confirmationOpensAt(ride)) && now.isBefore(confirmationDeadline(ride))
    }

    fun isConfirmationOver(ride: Ride): Boolean = !now().isBefore(confirmationDeadline(ride))

    /** Período em que o motorista compartilha a posição e confere os códigos de embarque. */
    fun isInProgressWindow(ride: Ride): Boolean {
        if (ride.status != RideStatus.SCHEDULED) return false
        val now = now()
        return !now.isBefore(ride.departure.minus(properties.trackingStartsBefore)) &&
            now.isBefore(ride.departure.plus(properties.trackingMaxDuration))
    }

    fun stage(booking: Booking): BookingStage {
        val ride = booking.ride
        return when {
            booking.status == BookingStatus.CANCELLED ->
                if (booking.expiredAt != null) BookingStage.NOT_CONFIRMED else BookingStage.CANCELLED
            ride.status == RideStatus.CANCELLED -> BookingStage.RIDE_CANCELLED
            ride.status == RideStatus.COMPLETED ->
                if (booking.boardedAt != null) BookingStage.COMPLETED else BookingStage.NO_SHOW
            booking.boardedAt != null -> BookingStage.BOARDED
            booking.presenceConfirmedAt != null -> BookingStage.CONFIRMED
            // O job que libera as vagas roda a cada minuto; até lá, já mostra como não confirmada
            isConfirmationOver(ride) -> BookingStage.NOT_CONFIRMED
            now().isBefore(confirmationOpensAt(ride)) -> BookingStage.RESERVED
            else -> BookingStage.AWAITING_CONFIRMATION
        }
    }

}
