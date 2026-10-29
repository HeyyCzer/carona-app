package me.rafaelpereira.caronaapp.controllers.dto

import me.rafaelpereira.caronaapp.models.RideDirection
import java.time.LocalDate

data class EarningsResponseDto(
    val from: LocalDate,
    val to: LocalDate,
    val totalCents: Int,
    val ridesCount: Int,
    val passengersCount: Int,
    val rides: List<EarningsRideDto>
)

data class EarningsRideDto(
    val rideId: Long,
    val date: LocalDate,
    val direction: RideDirection,
    val passengers: Int,
    val totalCents: Int
)
