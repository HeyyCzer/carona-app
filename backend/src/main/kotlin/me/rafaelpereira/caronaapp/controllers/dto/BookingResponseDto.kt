package me.rafaelpereira.caronaapp.controllers.dto

import jakarta.validation.constraints.Pattern
import me.rafaelpereira.caronaapp.models.BookingStage
import me.rafaelpereira.caronaapp.models.BookingStatus
import java.time.Instant
import java.time.LocalDateTime

data class BookingResponseDto(
    val id: Long,
    val requestId: Long,
    val ride: RideResponseDto,
    val pickup: LocationDto,
    val priceCents: Int,
    val status: BookingStatus,
    /** Situação da vaga para mostrar ao passageiro; só [BookingStage.COMPLETED] é viagem feita. */
    val stage: BookingStage,
    /** A partir de quando dá para confirmar a presença (horário local, como a saída da carona). */
    val confirmationOpensAt: LocalDateTime,
    /** Prazo para confirmar a presença; depois dele a vaga é liberada. */
    val confirmationDeadline: LocalDateTime,
    val presenceConfirmedAt: Instant?,
    /** Código que o passageiro mostra ao motorista no embarque; só aparece depois de confirmar a presença. */
    val boardingCode: String?,
    val boardedAt: Instant?
)

data class BoardDto(
    @field:Pattern(regexp = "\\d{4}", message = "O código tem 4 dígitos")
    val code: String
)
