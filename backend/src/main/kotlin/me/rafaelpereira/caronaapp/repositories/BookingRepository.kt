package me.rafaelpereira.caronaapp.repositories

import me.rafaelpereira.caronaapp.models.Booking
import me.rafaelpereira.caronaapp.models.BookingStatus
import me.rafaelpereira.caronaapp.models.RideStatus
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.time.LocalDate

@Repository
interface BookingRepository : JpaRepository<Booking, Long> {

    fun countByRideIdAndStatus(rideId: Long, status: BookingStatus): Long

    fun existsByRideIdAndRequestPassengerIdAndStatus(rideId: Long, passengerId: Long, status: BookingStatus): Boolean

    fun findByRideIdAndStatusOrderByCreatedAtAsc(rideId: Long, status: BookingStatus): List<Booking>

    fun findByRequestIdAndStatus(requestId: Long, status: BookingStatus): List<Booking>

    fun findByRequestPassengerIdAndRideDateGreaterThanEqualOrderByRideDateAscRideDepartureTimeAsc(
        passengerId: Long,
        date: LocalDate
    ): List<Booking>

    /** Vagas em que o passageiro embarcou de fato (o motorista conferiu o código). */
    fun findByRideRouteDriverIdAndRideStatusAndStatusAndBoardedAtIsNotNullAndRideDateBetween(
        driverId: Long,
        rideStatus: RideStatus,
        status: BookingStatus,
        from: LocalDate,
        to: LocalDate
    ): List<Booking>

    /** Vagas que ainda esperam a confirmação de presença, em caronas agendadas entre as datas. */
    fun findByStatusAndPresenceConfirmedAtIsNullAndRideStatusAndRideDateBetween(
        status: BookingStatus,
        rideStatus: RideStatus,
        from: LocalDate,
        to: LocalDate
    ): List<Booking>

}
