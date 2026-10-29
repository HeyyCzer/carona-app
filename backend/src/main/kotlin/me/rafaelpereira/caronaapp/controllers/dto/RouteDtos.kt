package me.rafaelpereira.caronaapp.controllers.dto

import jakarta.validation.Valid
import jakarta.validation.constraints.Max
import jakarta.validation.constraints.Min
import jakarta.validation.constraints.NotEmpty
import me.rafaelpereira.caronaapp.models.Route
import me.rafaelpereira.caronaapp.utils.Geo
import java.time.DayOfWeek
import java.time.LocalTime

data class CreateRouteDto(
    @field:Valid
    val origin: LocationDto,
    @field:Valid
    val destination: LocationDto,
    @field:NotEmpty
    val weekdays: Set<DayOfWeek>,
    val outboundTime: LocalTime,
    val returnTime: LocalTime? = null,
    @field:Min(0) @field:Max(2000)
    val maxDetourMeters: Int = 300,
    @field:Min(1) @field:Max(8)
    val seats: Int,
    @field:Min(0) @field:Max(100_00)
    val priceCents: Int
)

data class RouteResponseDto(
    val id: Long,
    val origin: LocationDto,
    val destination: LocationDto,
    val distanceMeters: Int,
    val weekdays: List<DayOfWeek>,
    val outboundTime: LocalTime,
    val returnTime: LocalTime?,
    val maxDetourMeters: Int,
    val maxDetourMinutes: Long,
    val seats: Int,
    val priceCents: Int,
    val active: Boolean
) {
    companion object {
        fun from(route: Route) = RouteResponseDto(
            id = route.id!!,
            origin = LocationDto.from(route.origin),
            destination = LocationDto.from(route.destination),
            distanceMeters = Geo.roadDistanceMeters(route.origin, route.destination),
            weekdays = route.weekdays.sorted(),
            outboundTime = route.outboundTime,
            returnTime = route.returnTime,
            maxDetourMeters = route.maxDetourMeters,
            maxDetourMinutes = Geo.travelMinutes(route.maxDetourMeters),
            seats = route.seats,
            priceCents = route.priceCents,
            active = route.active
        )
    }
}
