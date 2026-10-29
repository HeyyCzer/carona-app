package me.rafaelpereira.caronaapp.repositories

import me.rafaelpereira.caronaapp.models.RideDirection
import me.rafaelpereira.caronaapp.models.RideRequest
import me.rafaelpereira.caronaapp.models.RideRequestStatus
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface RideRequestRepository : JpaRepository<RideRequest, Long> {

    fun existsByRideIdAndPassengerIdAndStatus(rideId: Long, passengerId: Long, status: RideRequestStatus): Boolean

    fun findByPassengerIdOrderByCreatedAtDesc(passengerId: Long): List<RideRequest>

    fun findByRideRouteDriverIdAndStatusOrderByCreatedAtAsc(driverId: Long, status: RideRequestStatus): List<RideRequest>

    fun findByRideRouteIdAndStatus(routeId: Long, status: RideRequestStatus): List<RideRequest>

    fun findByRideRouteIdAndRideDirectionAndStatusAndRecurringTrue(
        routeId: Long,
        direction: RideDirection,
        status: RideRequestStatus
    ): List<RideRequest>

}
