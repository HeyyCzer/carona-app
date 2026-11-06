package me.rafaelpereira.caronaapp.controllers

import me.rafaelpereira.caronaapp.services.BookingService
import me.rafaelpereira.caronaapp.support.MutableClock
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.test.context.TestConfiguration
import org.springframework.boot.test.web.server.LocalServerPort
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Primary
import org.springframework.http.HttpMethod
import org.springframework.http.MediaType
import org.springframework.test.context.TestPropertySource
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.ResultActionsDsl
import org.springframework.test.web.servlet.delete
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.multipart
import org.springframework.test.web.servlet.post
import org.springframework.web.socket.CloseStatus
import org.springframework.web.socket.TextMessage
import org.springframework.web.socket.WebSocketHttpHeaders
import org.springframework.web.socket.WebSocketSession
import org.springframework.web.socket.client.standard.StandardWebSocketClient
import org.springframework.web.socket.handler.TextWebSocketHandler
import tools.jackson.databind.JsonNode
import tools.jackson.databind.ObjectMapper
import java.net.URI
import java.time.Instant
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import java.util.UUID
import java.util.concurrent.CompletableFuture
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/** Confirmação de presença, embarque com código, rastreamento do carro e fotos de perfil. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
@TestPropertySource(
    properties = [
        "spring.datasource.url=jdbc:sqlite:file:trip-test?mode=memory&cache=shared",
        "app.routing.osrm-url=",
        "app.avatars.dir=build/test-avatars",
        // O teste chama o job de expiração na hora certa
        "app.rides.expiration-check-interval=1h"
    ]
)
class TripFlowTests {

    @TestConfiguration
    class ClockConfig {
        @Bean
        @Primary
        fun mutableClock() = MutableClock(Instant.now(), ZoneId.of("America/Sao_Paulo"))
    }

    @Autowired
    lateinit var mockMvc: MockMvc

    @Autowired
    lateinit var objectMapper: ObjectMapper

    @Autowired
    lateinit var clock: MutableClock

    @Autowired
    lateinit var bookingService: BookingService

    @LocalServerPort
    var port: Int = 0

    private val day = LocalDate.now(ZoneId.of("America/Sao_Paulo")).plusDays(2)

    // Mesmo trajeto do RideFlowTests deslocado 2° ao norte, para as buscas não se misturarem
    private val routeJson = """
        {
          "origin": {"label": "Casa", "latitude": -18.8113, "longitude": -49.3758},
          "destination": {"label": "Unirp", "latitude": -18.7850, "longitude": -49.3600},
          "weekdays": ["MONDAY","TUESDAY","WEDNESDAY","THURSDAY","FRIDAY","SATURDAY","SUNDAY"],
          "outboundTime": "07:00",
          "maxDetourMeters": 300,
          "seats": 3,
          "priceCents": 600
        }
    """.trimIndent()

    private data class Account(val id: Long, val token: String)

    private fun at(hour: Int, minute: Int = 0) = clock.set(day.atTime(LocalTime.of(hour, minute)))

    private fun register(): Account {
        val body = mockMvc.post("/register") {
            contentType = MediaType.APPLICATION_JSON
            content = """{"name":"Teste","email":"${UUID.randomUUID()}@test.com","password":"senha12345"}"""
        }.andExpect { status { isCreated() } }.andReturn().response.contentAsString
        val json = objectMapper.readTree(body)
        return Account(json["user"]["id"].asLong(), json["accessToken"].asString())
    }

    private fun ResultActionsDsl.json(): JsonNode =
        objectMapper.readTree(andReturn().response.contentAsString)

    private fun post(path: String, account: Account, json: String? = null) = mockMvc.post(path) {
        header("Authorization", "Bearer ${account.token}")
        if (json != null) {
            contentType = MediaType.APPLICATION_JSON
            content = json
        }
    }

    private fun get(path: String, account: Account) = mockMvc.get(path) {
        header("Authorization", "Bearer ${account.token}")
    }

    /** Vaga do passageiro na carona [rideId], como vem de `/bookings/mine`. */
    private fun booking(passenger: Account, rideId: Long): JsonNode =
        get("/bookings/mine", passenger).json().first { it["ride"]["id"].asLong() == rideId }

    private fun location(lat: Double) = """{"latitude": $lat, "longitude": -49.37, "heading": 45, "speedMps": 8.5}"""

    /** Motorista com uma rota e três passageiros com vaga aceita na ida de [day]. */
    private fun rideWithPassengers(): Triple<Account, Long, List<Account>> {
        val driver = register()
        post("/routes", driver, routeJson).andExpect { status { isCreated() } }

        val passengers = List(3) { register() }
        var rideId = 0L
        for (passenger in passengers) {
            val result = get(
                "/rides/search?originLat=-18.79815&originLng=-49.3674&destinationLat=-18.7852&destinationLng=-49.3601&date=$day",
                passenger
            ).json().first { it["ride"]["driver"]["id"].asLong() == driver.id }
            rideId = result["ride"]["id"].asLong()
            val requestId = post(
                "/rides/$rideId/requests",
                passenger,
                """{"pickup": ${result["pickupPoint"]}, "recurring": false}"""
            ).json()["id"].asLong()
            post("/ride-requests/$requestId/accept", driver).andExpect { status { isOk() } }
        }
        return Triple(driver, rideId, passengers)
    }

    @Test
    fun `passageiro confirma presenca, embarca com codigo e so ele conta como concluido`() {
        at(3)
        val (driver, rideId, passengers) = rideWithPassengers()
        val (boards, noShow, silent) = passengers
        val stranger = register()

        // Antes da janela (abre 3 h antes da saída): só reservada
        assertEquals("RESERVED", booking(boards, rideId)["stage"].asString())
        assertTrue(booking(boards, rideId)["boardingCode"].isNull)
        post("/bookings/${booking(boards, rideId)["id"].asLong()}/confirm", boards).andExpect { status { isConflict() } }

        at(5)
        assertEquals("AWAITING_CONFIRMATION", booking(boards, rideId)["stage"].asString())
        val code = post("/bookings/${booking(boards, rideId)["id"].asLong()}/confirm", boards).andExpect {
            status { isOk() }
            jsonPath("$.stage") { value("CONFIRMED") }
        }.json()["boardingCode"].asString()
        assertTrue(code.matches(Regex("\\d{4}")), "código de embarque inválido: $code")
        val noShowCode = post("/bookings/${booking(noShow, rideId)["id"].asLong()}/confirm", noShow)
            .json()["boardingCode"].asString()
        assertNotEquals(code, noShowCode)
        post("/bookings/${booking(silent, rideId)["id"].asLong()}/confirm", stranger).andExpect { status { isForbidden() } }

        // Ainda longe da saída: não dá para rastrear nem embarcar
        post("/rides/$rideId/location", driver, location(-18.81)).andExpect { status { isConflict() } }
        post("/rides/$rideId/board", driver, """{"code": "$code"}""").andExpect { status { isConflict() } }

        // Passou do prazo (30 min antes): quem não confirmou perde a vaga
        at(6, 40)
        bookingService.expireUnconfirmed()
        val silentBooking = booking(silent, rideId)
        assertEquals("NOT_CONFIRMED", silentBooking["stage"].asString())
        assertEquals("CANCELLED", silentBooking["status"].asString())
        assertEquals(1, silentBooking["ride"]["seatsAvailable"].asInt())
        post("/bookings/${silentBooking["id"].asLong()}/confirm", silent).andExpect { status { isConflict() } }

        get("/rides/$rideId/passengers", driver).andExpect {
            status { isOk() }
            jsonPath("$.length()") { value(2) }
            jsonPath("$[0].stage") { value("CONFIRMED") }
            jsonPath("$[0].bookingId") { exists() }
        }
        get("/rides/$rideId/passengers", boards).andExpect {
            jsonPath("$[0].stage") { doesNotExist() }
            jsonPath("$[0].bookingId") { doesNotExist() }
        }

        // Rastreamento: motorista envia a posição, passageiros ativos veem; quem não confirmou e estranhos não
        get("/rides/$rideId/location", boards).andExpect { status { isNoContent() } }
        post("/rides/$rideId/location", boards, location(-18.81)).andExpect { status { isForbidden() } }
        post("/rides/$rideId/location", driver, location(-18.81)).andExpect { status { isOk() } }
        get("/rides/$rideId/location", boards).andExpect {
            status { isOk() }
            jsonPath("$.latitude") { value(-18.81) }
            jsonPath("$.heading") { value(45.0) }
        }
        get("/rides/$rideId/location", silent).andExpect { status { isForbidden() } }
        get("/rides/$rideId/location", stranger).andExpect { status { isForbidden() } }

        // Embarque: código errado não vale, o certo registra uma vez só
        val wrong = if (code == "0000") "1111" else "0000"
        if (wrong != noShowCode) {
            post("/rides/$rideId/board", driver, """{"code": "$wrong"}""").andExpect { status { isUnprocessableContent() } }
        }
        post("/rides/$rideId/board", driver, """{"code": "12"}""").andExpect { status { isBadRequest() } }
        post("/rides/$rideId/board", boards, """{"code": "$code"}""").andExpect { status { isForbidden() } }
        post("/rides/$rideId/board", driver, """{"code": "$code"}""").andExpect {
            status { isOk() }
            jsonPath("$.passenger.id") { value(boards.id) }
            jsonPath("$.stage") { value("BOARDED") }
        }
        post("/rides/$rideId/board", driver, """{"code": "$code"}""").andExpect { status { isConflict() } }
        assertEquals("BOARDED", booking(boards, rideId)["stage"].asString())
        post("/bookings/${booking(boards, rideId)["id"].asLong()}/cancel", boards).andExpect { status { isConflict() } }

        at(7, 30)
        get("/rides/driving/in-progress", driver).andExpect {
            jsonPath("$[?(@.id == $rideId)]") { exists() }
        }
        post("/rides/$rideId/complete", driver).andExpect { status { isOk() } }
        get("/rides/driving/in-progress", driver).andExpect {
            jsonPath("$[?(@.id == $rideId)]") { doesNotExist() }
        }

        // Só quem embarcou aparece como concluída e entra nos recebimentos
        assertEquals("COMPLETED", booking(boards, rideId)["stage"].asString())
        assertEquals("NO_SHOW", booking(noShow, rideId)["stage"].asString())
        assertEquals("NOT_CONFIRMED", booking(silent, rideId)["stage"].asString())
        get("/earnings?from=$day&to=$day", driver).andExpect {
            jsonPath("$.totalCents") { value(600) }
            jsonPath("$.passengersCount") { value(1) }
        }
        get("/rides/$rideId/location", boards).andExpect { status { isNoContent() } }
    }

    @Test
    fun `posicao do carro chega pelo websocket so para quem esta na carona`() {
        at(5)
        val (driver, rideId, passengers) = rideWithPassengers()
        val passenger = passengers.first()
        val stranger = register()
        post("/bookings/${booking(passenger, rideId)["id"].asLong()}/confirm", passenger).andExpect { status { isOk() } }

        at(6, 45)
        post("/rides/$rideId/location", driver, location(-18.80)).andExpect { status { isOk() } }

        val inbox = LinkedBlockingQueue<String>()
        val socket = connect(passenger, rideId, inbox)
        val strangerClosed = CompletableFuture<CloseStatus>()
        val strangerSocket = connect(stranger, rideId, LinkedBlockingQueue(), strangerClosed)
        try {
            // Ao conectar, já recebe a última posição
            val first = assertNotNull(inbox.poll(5, TimeUnit.SECONDS), "não recebeu a posição atual")
            assertEquals(-18.80, objectMapper.readTree(first)["latitude"].asDouble())

            post("/rides/$rideId/location", driver, location(-18.79)).andExpect { status { isOk() } }
            val update = assertNotNull(inbox.poll(5, TimeUnit.SECONDS), "não recebeu a posição nova")
            assertEquals(-18.79, objectMapper.readTree(update)["latitude"].asDouble())
            assertEquals(rideId, objectMapper.readTree(update)["rideId"].asLong())

            assertEquals(CloseStatus.POLICY_VIOLATION.code, strangerClosed.get(5, TimeUnit.SECONDS).code)
        } finally {
            socket.close()
            if (strangerSocket.isOpen) strangerSocket.close()
        }
    }

    private fun connect(
        account: Account,
        rideId: Long,
        queue: LinkedBlockingQueue<String>,
        closed: CompletableFuture<CloseStatus>? = null
    ): WebSocketSession =
        StandardWebSocketClient().execute(
            object : TextWebSocketHandler() {
                override fun handleTextMessage(session: WebSocketSession, message: TextMessage) {
                    queue.add(message.payload)
                }

                override fun afterConnectionClosed(session: WebSocketSession, status: CloseStatus) {
                    closed?.complete(status)
                }
            },
            WebSocketHttpHeaders(),
            URI("ws://localhost:$port/ws/tracking?rideId=$rideId&token=${account.token}")
        ).get(5, TimeUnit.SECONDS)

    @Test
    fun `foto de perfil fica na pasta de avatares com o id do usuario`() {
        val user = register()
        val other = register()
        // PNG de 1x1 pixel
        val png = byteArrayOf(
            0x89.toByte(), 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52
        )

        val avatarUrl = mockMvc.multipart(HttpMethod.PUT, "/me/avatar") {
            header("Authorization", "Bearer ${user.token}")
            file("file", png)
        }.andExpect {
            status { isOk() }
            jsonPath("$.avatarUrl") { exists() }
        }.json()["avatarUrl"].asString()
        assertTrue(avatarUrl.startsWith("/users/${user.id}/avatar?v="))
        assertTrue(java.nio.file.Files.exists(java.nio.file.Path.of("build/test-avatars/${user.id}.png")))

        get("/me", user).andExpect { jsonPath("$.avatarUrl") { value(avatarUrl) } }
        val served = get("/users/${user.id}/avatar", other).andExpect {
            status { isOk() }
            content { contentType(MediaType.IMAGE_PNG) }
        }.andReturn().response.contentAsByteArray
        assertContentEquals(png, served)
        mockMvc.get("/users/${user.id}/avatar").andExpect { status { isUnauthorized() } }

        mockMvc.multipart(HttpMethod.PUT, "/me/avatar") {
            header("Authorization", "Bearer ${user.token}")
            file("file", "não é uma foto".toByteArray())
        }.andExpect { status { isUnsupportedMediaType() } }

        mockMvc.delete("/me/avatar") { header("Authorization", "Bearer ${user.token}") }.andExpect {
            status { isOk() }
            jsonPath("$.avatarUrl") { doesNotExist() }
        }
        get("/users/${user.id}/avatar", other).andExpect { status { isNotFound() } }
    }

}
