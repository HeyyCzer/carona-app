package me.rafaelpereira.caronaapp.repositories

import me.rafaelpereira.caronaapp.models.Ride
import me.rafaelpereira.caronaapp.models.RideDirection
import me.rafaelpereira.caronaapp.models.RideStatus
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.time.LocalDate

@Repository
interface RideRepository : JpaRepository<Ride, Long> {

    fun existsByRouteIdAndDateAndDirection(routeId: Long, date: LocalDate, direction: RideDirection): Boolean

    fun findByDateAndStatusOrderByDepartureTimeAsc(date: LocalDate, status: RideStatus): List<Ride>

    fun findByRouteIdAndDateGreaterThanEqualAndStatus(routeId: Long, date: LocalDate, status: RideStatus): List<Ride>

    fun findByRouteIdAndDirectionAndDateGreaterThanEqualAndStatusOrderByDateAsc(
        routeId: Long,
        direction: RideDirection,
        date: LocalDate,
        status: RideStatus
    ): List<Ride>

    fun findByRouteDriverIdAndDateGreaterThanEqualAndStatusOrderByDateAscDepartureTimeAsc(
        driverId: Long,
        date: LocalDate,
        status: RideStatus
    ): List<Ride>

}
