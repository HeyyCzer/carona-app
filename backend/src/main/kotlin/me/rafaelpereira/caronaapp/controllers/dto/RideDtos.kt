package me.rafaelpereira.caronaapp.controllers.dto

import jakarta.validation.constraints.DecimalMax
import jakarta.validation.constraints.DecimalMin
import me.rafaelpereira.caronaapp.models.BookingStage
import me.rafaelpereira.caronaapp.models.Ride
import me.rafaelpereira.caronaapp.models.RideDirection
import me.rafaelpereira.caronaapp.models.RideStatus
import me.rafaelpereira.caronaapp.utils.Polyline
import java.time.Instant
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

/**
 * Passageiro com vaga confirmada. O ponto de embarque, a vaga e a situação do embarque
 * só vão para o motorista.
 */
data class RidePassengerDto(
    val passenger: PersonDto,
    val pickup: LocationDto?,
    val bookingId: Long? = null,
    val stage: BookingStage? = null
)

data class UpdateLocationDto(
    @field:DecimalMin("-90") @field:DecimalMax("90")
    val latitude: Double,
    @field:DecimalMin("-180") @field:DecimalMax("180")
    val longitude: Double,
    @field:DecimalMin("0") @field:DecimalMax("360")
    val heading: Double? = null,
    @field:DecimalMin("0")
    val speedMps: Double? = null
)

/** Posição do carro, como vem de `GET /rides/{id}/location` e do WebSocket `/ws/tracking`. */
data class RideLocationDto(
    val rideId: Long,
    val latitude: Double,
    val longitude: Double,
    val heading: Double?,
    val speedMps: Double?,
    val updatedAt: Instant
) {
    companion object {
        fun from(ride: Ride): RideLocationDto? = ride.driverLocation?.let {
            RideLocationDto(ride.id!!, it.latitude, it.longitude, it.heading, it.speedMps, it.updatedAt)
        }
    }
}
