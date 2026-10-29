package me.rafaelpereira.caronaapp.controllers.dto

import me.rafaelpereira.caronaapp.models.Ride
import me.rafaelpereira.caronaapp.models.RideDirection
import me.rafaelpereira.caronaapp.models.RideStatus
import me.rafaelpereira.caronaapp.utils.Polyline
import java.time.LocalDate
import java.time.LocalTime

data class RideResponseDto(
    val id: Long,
    val routeId: Long,
    val direction: RideDirection,
    val date: LocalDate,
    val departureTime: LocalTime,
    val estimatedArrivalTime: LocalTime,
    val status: RideStatus,
    val distanceMeters: Int,
    /** Trajeto em encoded polyline (precisão 5): pelas ruas ou, sem OSRM, a linha reta. */
    val path: String,
    val from: LocationDto,
    val to: LocationDto,
    val driver: PersonDto,
    val priceCents: Int,
    val seats: Int,
    val seatsAvailable: Int
) {
    companion object {
        fun from(ride: Ride, seatsAvailable: Int) = RideResponseDto(
            id = ride.id!!,
            routeId = ride.route.id!!,
            direction = ride.direction,
            date = ride.date,
            departureTime = ride.departureTime,
            estimatedArrivalTime = ride.departureTime.plusMinutes(ride.travelMinutes()),
            status = ride.status,
            distanceMeters = ride.distanceMeters,
            path = ride.roadPath?.polyline ?: Polyline.encode(listOf(ride.from, ride.to)),
            from = LocationDto.from(ride.from),
            to = LocationDto.from(ride.to),
            driver = PersonDto.from(ride.driver),
            priceCents = ride.priceCents,
            seats = ride.seats,
            seatsAvailable = seatsAvailable
        )
    }
}

data class RideSearchResultDto(
    val ride: RideResponseDto,
    /** Distância em linha reta da origem do passageiro até o ponto de embarque sugerido, no trajeto. */
    val distanceFromYouMeters: Int,
    val pickupPoint: LocationDto,
    val estimatedPickupTime: LocalTime
)
