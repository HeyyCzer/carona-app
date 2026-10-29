package me.rafaelpereira.caronaapp.services

import me.rafaelpereira.caronaapp.controllers.dto.EarningsResponseDto
import me.rafaelpereira.caronaapp.controllers.dto.EarningsRideDto
import me.rafaelpereira.caronaapp.models.BookingStatus
import me.rafaelpereira.caronaapp.models.RideStatus
import me.rafaelpereira.caronaapp.repositories.BookingRepository
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.server.ResponseStatusException
import java.time.Clock
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.temporal.TemporalAdjusters

/**
 * Recebimentos do motorista: soma das vagas confirmadas em caronas concluídas.
 * O pagamento em si (Pix) acontece fora do app.
 */
@Service
class EarningsService(
    private val bookingRepository: BookingRepository,
    private val clock: Clock
) {

    @Transactional(readOnly = true)
    fun get(driverId: Long, from: LocalDate?, to: LocalDate?): EarningsResponseDto {
        val start = from ?: LocalDate.now(clock).with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
        val end = to ?: start.plusDays(6)
        if (end.isBefore(start)) {
            throw ResponseStatusException(HttpStatus.BAD_REQUEST, "A data final deve ser depois da inicial")
        }

        val rides = bookingRepository
            .findByRideRouteDriverIdAndRideStatusAndStatusAndRideDateBetween(
                driverId, RideStatus.COMPLETED, BookingStatus.CONFIRMED, start, end
            )
            .groupBy { it.ride }
            .map { (ride, bookings) ->
                EarningsRideDto(
                    rideId = ride.id!!,
                    date = ride.date,
                    direction = ride.direction,
                    passengers = bookings.size,
                    totalCents = bookings.sumOf { it.priceCents }
                )
            }
            .sortedWith(compareBy({ it.date }, { it.direction }))

        return EarningsResponseDto(
            from = start,
            to = end,
            totalCents = rides.sumOf { it.totalCents },
            ridesCount = rides.size,
            passengersCount = rides.sumOf { it.passengers },
            rides = rides
        )
    }

}
