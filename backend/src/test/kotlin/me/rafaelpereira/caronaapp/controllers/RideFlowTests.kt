package me.rafaelpereira.caronaapp.controllers

import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc
import org.springframework.http.MediaType
import org.springframework.test.context.TestPropertySource
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.ResultActionsDsl
import org.springframework.test.web.servlet.delete
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.post
import tools.jackson.databind.JsonNode
import tools.jackson.databind.ObjectMapper
import java.time.LocalDate
import java.time.ZoneId
import java.util.UUID

@SpringBootTest
@AutoConfigureMockMvc
@TestPropertySource(properties = ["spring.datasource.url=jdbc:sqlite:file:test?mode=memory&cache=shared"])
class RideFlowTests {

    @Autowired
    lateinit var mockMvc: MockMvc

    @Autowired
    lateinit var objectMapper: ObjectMapper

    private val tomorrow = LocalDate.now(ZoneId.of("America/Sao_Paulo")).plusDays(1)

    // Casa (R. das Acácias) -> Unirp, e um passageiro a ~50 m do trajeto indo para o mesmo destino
    private val routeJson = """
        {
          "origin": {"label": "Casa - R. das Acácias, 214", "latitude": -20.8113, "longitude": -49.3758},
          "destination": {"label": "Unirp - Unidade III", "latitude": -20.7850, "longitude": -49.3600},
          "weekdays": ["MONDAY","TUESDAY","WEDNESDAY","THURSDAY","FRIDAY","SATURDAY","SUNDAY"],
          "outboundTime": "07:00",
          "returnTime": "22:30",
          "maxDetourMeters": 300,
          "seats": 1,
          "priceCents": 600
        }
    """.trimIndent()

    private fun register(): String {
        val body = mockMvc.post("/register") {
            contentType = MediaType.APPLICATION_JSON
            content = """{"name":"Teste","email":"${UUID.randomUUID()}@test.com","password":"senha12345"}"""
        }.andExpect { status { isCreated() } }.andReturn().response.contentAsString
        return objectMapper.readTree(body)["accessToken"].asString()
    }

    private fun ResultActionsDsl.json(): JsonNode =
        objectMapper.readTree(andReturn().response.contentAsString)

    private fun search(token: String) = mockMvc.get("/rides/search") {
        header("Authorization", "Bearer $token")
        param("originLat", "-20.79815")
        param("originLng", "-49.3674")
        param("destinationLat", "-20.7852")
        param("destinationLng", "-49.3601")
        param("date", tomorrow.toString())
    }

    private fun post(path: String, token: String, json: String? = null) = mockMvc.post(path) {
        header("Authorization", "Bearer $token")
        if (json != null) {
            contentType = MediaType.APPLICATION_JSON
            content = json
        }
    }

    private fun get(path: String, token: String) = mockMvc.get(path) {
        header("Authorization", "Bearer $token")
    }

    @Test
    fun `fluxo completo de rota, pedido de vaga, aceite e cancelamento`() {
        val driver = register()
        val passenger = register()

        post("/routes", driver, routeJson).andExpect {
            status { isCreated() }
            jsonPath("$.weekdays.length()") { value(7) }
        }

        // Só a ida passa perto da origem e do destino no sentido certo
        val results = search(passenger).andExpect {
            status { isOk() }
            jsonPath("$.length()") { value(1) }
            jsonPath("$[0].ride.direction") { value("OUTBOUND") }
            jsonPath("$[0].ride.seatsAvailable") { value(1) }
        }.json()
        val rideId = results[0]["ride"]["id"].asLong()
        val pickup = results[0]["pickupPoint"].toString()

        val requestJson = """{"pickup": $pickup, "recurring": true}"""
        post("/rides/$rideId/requests", driver, requestJson).andExpect { status { isUnprocessableContent() } }

        val requestId = post("/rides/$rideId/requests", passenger, requestJson).andExpect {
            status { isCreated() }
            jsonPath("$.status") { value("PENDING") }
            jsonPath("$.weekdays.length()") { value(7) }
        }.json()["id"].asLong()
        post("/rides/$rideId/requests", passenger, requestJson).andExpect { status { isConflict() } }

        get("/ride-requests/received", driver).andExpect { jsonPath("$.length()") { value(1) } }
        post("/ride-requests/$requestId/accept", passenger).andExpect { status { isForbidden() } }
        post("/ride-requests/$requestId/accept", driver).andExpect {
            status { isOk() }
            jsonPath("$.status") { value("ACCEPTED") }
        }

        // Pedido recorrente reserva vaga em todas as próximas idas
        val bookings = get("/bookings/mine", passenger).andExpect { status { isOk() } }.json()
        check(bookings.size() >= 14) { "esperava reservas recorrentes, veio ${bookings.size()}" }
        check(bookings.all { it["ride"]["direction"].asString() == "OUTBOUND" })

        // Lotou (1 vaga): some da busca
        search(register()).andExpect { jsonPath("$.length()") { value(0) } }

        // "Não vou" libera a vaga de amanhã
        val tomorrowBooking = bookings.first { it["ride"]["id"].asLong() == rideId }["id"].asLong()
        post("/bookings/$tomorrowBooking/cancel", passenger).andExpect {
            status { isOk() }
            jsonPath("$.status") { value("CANCELLED") }
            jsonPath("$.ride.seatsAvailable") { value(1) }
        }

        get("/rides/driving", driver).andExpect { status { isOk() } }
        post("/rides/$rideId/complete", driver).andExpect { status { isConflict() } }
        get("/earnings", driver).andExpect {
            status { isOk() }
            jsonPath("$.totalCents") { value(0) }
        }
    }

    @Test
    fun `motorista desativa rota e as caronas somem da busca`() {
        val driver = register()
        val routeId = post("/routes", driver, routeJson).json()["id"].asLong()

        mockMvc.delete("/routes/$routeId") { header("Authorization", "Bearer $driver") }
            .andExpect { status { isNoContent() } }
        get("/routes/mine", driver).andExpect { jsonPath("$.length()") { value(0) } }
        get("/rides/driving", driver).andExpect { jsonPath("$.length()") { value(0) } }
    }

    @Test
    fun `rotas sem token retornam 401`() {
        mockMvc.get("/routes/mine").andExpect { status { isUnauthorized() } }
    }

}
