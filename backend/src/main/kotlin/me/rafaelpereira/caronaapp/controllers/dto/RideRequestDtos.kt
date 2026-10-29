package me.rafaelpereira.caronaapp.controllers.dto

import jakarta.validation.Valid
import me.rafaelpereira.caronaapp.models.RideRequestStatus
import java.time.DayOfWeek
import java.time.Instant

data class CreateRideRequestDto(
    @field:Valid
    val pickup: LocationDto,
    val recurring: Boolean = false
)

data class RideRequestResponseDto(
    val id: Long,
    val ride: RideResponseDto,
    val passenger: PersonDto,
    val recurring: Boolean,
    val weekdays: List<DayOfWeek>,
    val pickup: LocationDto,
    val detourMeters: Int,
    val detourMinutes: Long,
    val status: RideRequestStatus,
    val createdAt: Instant
)
