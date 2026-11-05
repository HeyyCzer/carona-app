package me.rafaelpereira.caronaapp.services

import me.rafaelpereira.caronaapp.controllers.dto.LocationDto
import me.rafaelpereira.caronaapp.controllers.dto.PersonDto
import me.rafaelpereira.caronaapp.controllers.dto.RidePassengerDto
import me.rafaelpereira.caronaapp.controllers.dto.RideResponseDto
import me.rafaelpereira.caronaapp.controllers.dto.RideSearchResultDto
import me.rafaelpereira.caronaapp.models.Booking
import me.rafaelpereira.caronaapp.models.BookingStatus
import me.rafaelpereira.caronaapp.models.Location
import me.rafaelpereira.caronaapp.models.Ride
import me.rafaelpereira.caronaapp.models.RideDirection
import me.rafaelpereira.caronaapp.models.RideRequest
import me.rafaelpereira.caronaapp.models.RideRequestStatus
import me.rafaelpereira.caronaapp.models.RideStatus
import me.rafaelpereira.caronaapp.models.Route
import me.rafaelpereira.caronaapp.repositories.BookingRepository
import me.rafaelpereira.caronaapp.repositories.RideRepository
import me.rafaelpereira.caronaapp.repositories.RideRequestRepository
import me.rafaelpereira.caronaapp.repositories.RouteRepository
import me.rafaelpereira.caronaapp.utils.Geo
import org.slf4j.LoggerFactory
import org.springframework.data.repository.findByIdOrNull
import org.springframework.http.HttpStatus
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.server.ResponseStatusException
import java.security.SecureRandom
import java.time.Clock
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger
import kotlin.math.roundToInt

@Service
class RideService(
    private val rideRepository: RideRepository,
    private val routeRepository: RouteRepository,
    private val rideRequestRepository: RideRequestRepository,
    private val bookingRepository: BookingRepository,
    private val rules: RideRules,
    private val clock: Clock
) {

    private val log = LoggerFactory.getLogger(javaClass)
    private val random = SecureRandom()

    /** Códigos errados digitados por carona, para impedir que o motorista teste todos. */
    private val failedBoardings = ConcurrentHashMap<Long, AtomicInteger>()

    /**
     * Cria as caronas da rota para os próximos [GENERATION_DAYS] dias, ignorando as que já existem,
     * e já reserva vaga para os passageiros com pedido recorrente aceito.
     */
    @Transactional
    fun generateRides(route: Route) {
        if (!route.active) return
        val today = LocalDate.now(clock)

        for (offset in 0..GENERATION_DAYS) {
            val date = today.plusDays(offset)
            if (date.dayOfWeek !in route.weekdays) continue

            for (direction in RideDirection.entries) {
                val departure = route.departureTime(direction) ?: continue
                if (!LocalDateTime.of(date, departure).isAfter(LocalDateTime.now(clock))) continue
                if (rideRepository.existsByRouteIdAndDateAndDirection(route.id!!, date, direction)) continue

                val ride = rideRepository.save(
                    Ride(route, direction, date, departure, route.seats, route.priceCents)
                )
                rideRequestRepository
                    .findByRideRouteIdAndRideDirectionAndStatusAndRecurringTrue(
                        route.id!!, direction, RideRequestStatus.ACCEPTED
                    )
                    .filter { !it.ride.date.isAfter(date) }
                    .forEach { tryBook(ride, it) }
            }
        }
    }

    @Scheduled(cron = "0 0 3 * * *", zone = "\${app.timezone}")
    @Transactional
    fun generateAllRides() {
        routeRepository.findByActiveTrue().forEach(::generateRides)
    }

    /** Reserva uma vaga na carona para o pedido, se ainda houver lugar. */
    fun tryBook(ride: Ride, request: RideRequest): Boolean {
        if (ride.status != RideStatus.SCHEDULED || hasDeparted(ride) || seatsAvailable(ride) <= 0) return false
        if (bookingRepository.existsByRideIdAndRequestPassengerIdAndStatus(
                ride.id!!, request.passenger.id!!, BookingStatus.CONFIRMED
            )
        ) return false

        val booking = Booking(ride, request, ride.priceCents)
        // Vaga aceita depois do prazo de confirmação: não dá mais tempo de confirmar, então já vale
        if (rules.isConfirmationOver(ride)) confirmPresence(booking)
        bookingRepository.save(booking)
        return true
    }

    /** Registra a presença e gera um código de embarque de 4 dígitos, único entre as vagas da carona. */
    fun confirmPresence(booking: Booking) {
        if (booking.presenceConfirmedAt != null) return
        val taken = booking.ride.id?.let { rideId ->
            bookingRepository.findByRideIdAndStatusOrderByCreatedAtAsc(rideId, BookingStatus.CONFIRMED)
                .mapNotNull { it.boardingCode }
                .toSet()
        }.orEmpty()
        var code: String
        do {
            code = "%04d".format(random.nextInt(10_000))
        } while (code in taken)

        booking.boardingCode = code
        booking.presenceConfirmedAt = clock.instant()
    }

    /**
     * Caronas do dia que passam perto da origem e do destino do passageiro, no sentido certo.
     * "Perto" é o desvio máximo que o motorista aceita, medido até o trajeto pelas ruas (ou a linha reta, sem OSRM).
     */
    @Transactional(readOnly = true)
    fun search(userId: Long, origin: Location, destination: Location, date: LocalDate?): List<RideSearchResultDto> {
        val searchDate = date ?: LocalDate.now(clock)
        log.debug(
            "Busca do usuário {} em {}: origem ({}, {}) → destino ({}, {})",
            userId, searchDate, origin.latitude, origin.longitude, destination.latitude, destination.longitude
        )

        return rideRepository.findByDateAndStatusOrderByDepartureTimeAsc(searchDate, RideStatus.SCHEDULED)
            .asSequence()
            .filter { it.driver.id != userId && !hasDeparted(it) }
            .mapNotNull { ride ->
                val path = ride.pathPoints()
                val pickup = Geo.project(origin, path)
                val dropoff = Geo.project(destination, path)
                val maxDistance = ride.route.maxDetourMeters
                val seatsAvailable = seatsAvailable(ride)
                val rejection = when {
                    pickup.distanceMeters > maxDistance -> "origem longe demais"
                    dropoff.distanceMeters > maxDistance -> "destino longe demais"
                    pickup.fraction > dropoff.fraction -> "sentido contrário"
                    seatsAvailable <= 0 -> "sem vagas"
                    else -> null
                }
                log.debug(
                    "  carona {} ({} {}): origem a {} m, destino a {} m, limite {} m, embarque em {}% do trajeto → {}",
                    ride.id, ride.direction, ride.departureTime,
                    pickup.distanceMeters.roundToInt(), dropoff.distanceMeters.roundToInt(), maxDistance,
                    (pickup.fraction * 100).roundToInt(), rejection?.let { "descartada: $it" } ?: "OK"
                )
                if (rejection != null) return@mapNotNull null

                RideSearchResultDto(
                    ride = RideResponseDto.from(ride, seatsAvailable),
                    distanceFromYouMeters = pickup.distanceMeters.roundToInt(),
                    pickupPoint = LocationDto.from(pickup.point),
                    estimatedPickupTime = ride.departureTime.plusMinutes(ride.travelMinutes(pickup.fraction))
                )
            }
            .toList()
    }

    @Transactional(readOnly = true)
    fun get(id: Long): RideResponseDto = toResponse(findRide(id))

    /** Passageiros confirmados, na ordem em que entraram. Só o motorista e quem está na carona podem ver. */
    @Transactional(readOnly = true)
    fun passengers(userId: Long, id: Long): List<RidePassengerDto> {
        val ride = findRide(id)
        val bookings = bookingRepository.findByRideIdAndStatusOrderByCreatedAtAsc(id, BookingStatus.CONFIRMED)
        val isDriver = ride.driver.id == userId
        if (!isDriver && bookings.none { it.passenger.id == userId }) {
            throw ResponseStatusException(HttpStatus.FORBIDDEN, "Você não está nessa carona")
        }
        return bookings.map { toPassenger(it, isDriver) }
    }

    /**
     * O motorista digita o código que o passageiro mostra no app para registrar o embarque.
     * Só vale para quem confirmou a presença, e só a partir de pouco antes da saída.
     */
    @Transactional
    fun board(driverId: Long, id: Long, code: String): RidePassengerDto {
        val ride = findRide(id)
        requireDriver(ride, driverId)
        if (!rules.isInProgressWindow(ride)) {
            throw ResponseStatusException(HttpStatus.CONFLICT, "O embarque só pode ser registrado perto da hora da saída")
        }
        val failures = failedBoardings.computeIfAbsent(id) { AtomicInteger() }
        if (failures.get() >= MAX_FAILED_BOARDINGS) {
            throw ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "Muitos códigos errados. Peça ao passageiro para conferir o código.")
        }

        val booking = bookingRepository.findByRideIdAndStatusOrderByCreatedAtAsc(id, BookingStatus.CONFIRMED)
            .firstOrNull { it.presenceConfirmedAt != null && it.boardingCode == code }
        if (booking == null) {
            failures.incrementAndGet()
            throw ResponseStatusException(HttpStatus.UNPROCESSABLE_CONTENT, "Código inválido")
        }
        if (booking.boardedAt != null) {
            throw ResponseStatusException(HttpStatus.CONFLICT, "${booking.passenger.name} já embarcou")
        }

        booking.boardedAt = clock.instant()
        return toPassenger(booking, isDriver = true)
    }

    /** Próximas caronas em que o usuário é o motorista. */
    @Transactional(readOnly = true)
    fun upcomingAsDriver(driverId: Long): List<RideResponseDto> =
        rideRepository.findByRouteDriverIdAndDateGreaterThanEqualAndStatusOrderByDateAscDepartureTimeAsc(
            driverId, LocalDate.now(clock), RideStatus.SCHEDULED
        )
            .filter { !hasDeparted(it) }
            .map(::toResponse)

    /**
     * Caronas do motorista que já saíram e ainda não foram concluídas nem canceladas
     * (em andamento ou esperando ele marcar como concluída), dos últimos [IN_PROGRESS_DAYS] dias.
     */
    @Transactional(readOnly = true)
    fun inProgressAsDriver(driverId: Long): List<RideResponseDto> {
        val today = LocalDate.now(clock)
        return rideRepository.findByRouteDriverIdAndDateBetweenAndStatusOrderByDateAscDepartureTimeAsc(
            driverId, today.minusDays(IN_PROGRESS_DAYS), today, RideStatus.SCHEDULED
        )
            .filter(::hasDeparted)
            .map(::toResponse)
    }

    @Transactional
    fun cancel(driverId: Long, id: Long): RideResponseDto {
        val ride = findRide(id)
        requireDriver(ride, driverId)
        if (ride.status != RideStatus.SCHEDULED || hasDeparted(ride)) {
            throw ResponseStatusException(HttpStatus.CONFLICT, "Só é possível cancelar caronas que ainda não saíram")
        }
        ride.status = RideStatus.CANCELLED
        return toResponse(ride)
    }

    /** Marca a carona como realizada; as vagas confirmadas passam a contar nos recebimentos. */
    @Transactional
    fun complete(driverId: Long, id: Long): RideResponseDto {
        val ride = findRide(id)
        requireDriver(ride, driverId)
        if (ride.status != RideStatus.SCHEDULED || !hasDeparted(ride)) {
            throw ResponseStatusException(HttpStatus.CONFLICT, "Só é possível concluir caronas que já saíram")
        }
        ride.status = RideStatus.COMPLETED
        return toResponse(ride)
    }

    fun findRide(id: Long): Ride = rideRepository.findByIdOrNull(id)
        ?: throw ResponseStatusException(HttpStatus.NOT_FOUND, "Carona não encontrada")

    fun seatsAvailable(ride: Ride): Int =
        ride.seats - bookingRepository.countByRideIdAndStatus(ride.id!!, BookingStatus.CONFIRMED).toInt()

    fun hasDeparted(ride: Ride): Boolean = !ride.departure.isAfter(LocalDateTime.now(clock))

    fun toResponse(ride: Ride) = RideResponseDto.from(ride, seatsAvailable(ride))

    private fun toPassenger(booking: Booking, isDriver: Boolean) = RidePassengerDto(
        passenger = PersonDto.from(booking.passenger),
        pickup = if (isDriver) LocationDto.from(booking.request.pickup) else null,
        bookingId = if (isDriver) booking.id else null,
        stage = if (isDriver) rules.stage(booking) else null
    )

    private fun requireDriver(ride: Ride, userId: Long) {
        if (ride.driver.id != userId) {
            throw ResponseStatusException(HttpStatus.FORBIDDEN, "Você não é o motorista dessa carona")
        }
    }

    companion object {
        const val GENERATION_DAYS = 14L
        const val IN_PROGRESS_DAYS = 7L
        private const val MAX_FAILED_BOARDINGS = 10
    }

}
