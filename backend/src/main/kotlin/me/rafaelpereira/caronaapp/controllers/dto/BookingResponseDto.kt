package me.rafaelpereira.caronaapp.controllers.dto

import me.rafaelpereira.caronaapp.models.BookingStatus

data class BookingResponseDto(
    val id: Long,
    val requestId: Long,
    val ride: RideResponseDto,
    val pickup: LocationDto,
    val priceCents: Int,
    val status: BookingStatus
)
