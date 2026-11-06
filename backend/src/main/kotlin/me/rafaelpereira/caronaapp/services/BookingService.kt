package me.rafaelpereira.caronaapp.services

import me.rafaelpereira.caronaapp.controllers.dto.BookingResponseDto
import me.rafaelpereira.caronaapp.controllers.dto.LocationDto
import me.rafaelpereira.caronaapp.models.Booking
import me.rafaelpereira.caronaapp.models.BookingStage
import me.rafaelpereira.caronaapp.models.BookingStatus
import me.rafaelpereira.caronaapp.models.RideStatus
import me.rafaelpereira.caronaapp.repositories.BookingRepository
import org.slf4j.LoggerFactory
import org.springframework.data.repository.findByIdOrNull
import org.springframework.http.HttpStatus
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.server.ResponseStatusException
import java.time.Clock
import java.time.LocalDate
import java.time.format.DateTimeFormatter

@Service
class BookingService(
    private val bookingRepository: BookingRepository,
    private val rideService: RideService,
    private val rules: RideRules,
    private val clock: Clock
) {

    private val log = LoggerFactory.getLogger(javaClass)

    /** Vagas do passageiro de hoje em diante ("Minhas caronas"). */
    @Transactional(readOnly = true)
    fun mine(passengerId: Long): List<BookingResponseDto> =
        bookingRepository
            .findByRequestPassengerIdAndRideDateGreaterThanEqualOrderByRideDateAscRideDepartureTimeAsc(
                passengerId, LocalDate.now(clock)
            )
            .map(::toResponse)

    /** "Vou": confirma a presença, dentro da janela de poucas horas antes da saída, e libera o código de embarque. */
    @Transactional
    fun confirm(passengerId: Long, id: Long): BookingResponseDto {
        val booking = findOwn(passengerId, id)
        val ride = booking.ride
        if (booking.status != BookingStatus.CONFIRMED || ride.status != RideStatus.SCHEDULED) {
            throw ResponseStatusException(HttpStatus.CONFLICT, "Essa vaga não está mais ativa")
        }
        if (booking.presenceConfirmedAt == null) {
            if (rules.isConfirmationOver(ride)) {
                throw ResponseStatusException(HttpStatus.CONFLICT, "O prazo para confirmar a presença já acabou")
            }
            if (!rules.isConfirmationOpen(ride)) {
                val opensAt = rules.confirmationOpensAt(ride).format(DateTimeFormatter.ofPattern("dd/MM 'às' HH:mm"))
                throw ResponseStatusException(HttpStatus.CONFLICT, "A confirmação abre em $opensAt")
            }
            rideService.confirmPresence(booking)
        }
        return toResponse(booking)
    }

    /** "Não vou": libera a vaga de um dia sem cancelar o pedido recorrente. */
    @Transactional
    fun cancel(passengerId: Long, id: Long): BookingResponseDto {
        val booking = findOwn(passengerId, id)
        if (booking.status != BookingStatus.CONFIRMED || booking.boardedAt != null || rideService.hasDeparted(booking.ride)) {
            throw ResponseStatusException(HttpStatus.CONFLICT, "Essa vaga não pode mais ser cancelada")
        }

        booking.status = BookingStatus.CANCELLED
        return toResponse(booking)
    }

    /** Quem não confirmou a presença até o prazo perde a vaga, que volta a ficar livre na busca. */
    @Scheduled(fixedDelayString = "\${app.rides.expiration-check-interval:60s}")
    @Transactional
    fun expireUnconfirmed() {
        val today = LocalDate.now(clock)
        val expired = bookingRepository
            .findByStatusAndPresenceConfirmedAtIsNullAndRideStatusAndRideDateBetween(
                BookingStatus.CONFIRMED, RideStatus.SCHEDULED, today.minusDays(1), today.plusDays(1)
            )
            .filter { rules.isConfirmationOver(it.ride) }
        expired.forEach {
            it.status = BookingStatus.CANCELLED
            it.expiredAt = clock.instant()
        }
        if (expired.isNotEmpty()) log.info("{} vaga(s) liberada(s) por falta de confirmação", expired.size)
    }

    private fun findOwn(passengerId: Long, id: Long): Booking {
        val booking = bookingRepository.findByIdOrNull(id)
            ?: throw ResponseStatusException(HttpStatus.NOT_FOUND, "Vaga não encontrada")
        if (booking.passenger.id != passengerId) {
            throw ResponseStatusException(HttpStatus.FORBIDDEN, "Essa vaga não é sua")
        }
        return booking
    }

    private fun toResponse(booking: Booking): BookingResponseDto {
        val stage = rules.stage(booking)
        return BookingResponseDto(
            id = booking.id!!,
            requestId = booking.request.id!!,
            ride = rideService.toResponse(booking.ride),
            pickup = LocationDto.from(booking.request.pickup),
            priceCents = booking.priceCents,
            status = booking.status,
            stage = stage,
            confirmationOpensAt = rules.confirmationOpensAt(booking.ride),
            confirmationDeadline = rules.confirmationDeadline(booking.ride),
            presenceConfirmedAt = booking.presenceConfirmedAt,
            boardingCode = booking.boardingCode.takeIf { stage == BookingStage.CONFIRMED },
            boardedAt = booking.boardedAt
        )
    }

}
