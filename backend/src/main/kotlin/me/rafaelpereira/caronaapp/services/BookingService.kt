package me.rafaelpereira.caronaapp.services

import me.rafaelpereira.caronaapp.controllers.dto.BookingResponseDto
import me.rafaelpereira.caronaapp.controllers.dto.LocationDto
import me.rafaelpereira.caronaapp.models.Booking
import me.rafaelpereira.caronaapp.models.BookingStatus
import me.rafaelpereira.caronaapp.repositories.BookingRepository
import org.springframework.data.repository.findByIdOrNull
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.server.ResponseStatusException
import java.time.Clock
import java.time.LocalDate

@Service
class BookingService(
    private val bookingRepository: BookingRepository,
    private val rideService: RideService,
    private val clock: Clock
) {

    /** Vagas do passageiro de hoje em diante ("Minhas caronas"). */
    @Transactional(readOnly = true)
    fun mine(passengerId: Long): List<BookingResponseDto> =
        bookingRepository
            .findByRequestPassengerIdAndRideDateGreaterThanEqualOrderByRideDateAscRideDepartureTimeAsc(
                passengerId, LocalDate.now(clock)
            )
            .map(::toResponse)

    /** "Não vou": libera a vaga de um dia sem cancelar o pedido recorrente. */
    @Transactional
    fun cancel(passengerId: Long, id: Long): BookingResponseDto {
        val booking = bookingRepository.findByIdOrNull(id)
            ?: throw ResponseStatusException(HttpStatus.NOT_FOUND, "Vaga não encontrada")
        if (booking.passenger.id != passengerId) {
            throw ResponseStatusException(HttpStatus.FORBIDDEN, "Essa vaga não é sua")
        }
        if (booking.status != BookingStatus.CONFIRMED || rideService.hasDeparted(booking.ride)) {
            throw ResponseStatusException(HttpStatus.CONFLICT, "Essa vaga não pode mais ser cancelada")
        }

        booking.status = BookingStatus.CANCELLED
        return toResponse(booking)
    }

    private fun toResponse(booking: Booking) = BookingResponseDto(
        id = booking.id!!,
        requestId = booking.request.id!!,
        ride = rideService.toResponse(booking.ride),
        pickup = LocationDto.from(booking.request.pickup),
        priceCents = booking.priceCents,
        status = booking.status
    )

}
