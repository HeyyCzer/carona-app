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

    fun findByRequestIdAndStatus(requestId: Long, status: BookingStatus): List<Booking>

    fun findByRequestPassengerIdAndRideDateGreaterThanEqualOrderByRideDateAscRideDepartureTimeAsc(
        passengerId: Long,
        date: LocalDate
    ): List<Booking>

    fun findByRideRouteDriverIdAndRideStatusAndStatusAndRideDateBetween(
        driverId: Long,
        rideStatus: RideStatus,
        status: BookingStatus,
        from: LocalDate,
        to: LocalDate
    ): List<Booking>

}
