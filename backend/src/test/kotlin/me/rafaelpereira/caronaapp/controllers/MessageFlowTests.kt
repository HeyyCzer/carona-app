package me.rafaelpereira.caronaapp.controllers

import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.test.web.server.LocalServerPort
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc
import org.springframework.http.MediaType
import org.springframework.test.context.TestPropertySource
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.ResultActionsDsl
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.post
import org.springframework.web.socket.TextMessage
import org.springframework.web.socket.WebSocketHttpHeaders
import org.springframework.web.socket.WebSocketSession
import org.springframework.web.socket.client.standard.StandardWebSocketClient
import org.springframework.web.socket.handler.TextWebSocketHandler
import tools.jackson.databind.JsonNode
import tools.jackson.databind.ObjectMapper
import java.net.URI
import java.time.LocalDate
import java.time.ZoneId
import java.util.UUID
import java.util.concurrent.ExecutionException
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNotNull

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
@TestPropertySource(
    properties = ["spring.datasource.url=jdbc:sqlite:file:test?mode=memory&cache=shared", "app.routing.osrm-url="]
)
class MessageFlowTests {

    @Autowired
    lateinit var mockMvc: MockMvc

    @Autowired
    lateinit var objectMapper: ObjectMapper

    @LocalServerPort
    var port: Int = 0

    private val tomorrow = LocalDate.now(ZoneId.of("America/Sao_Paulo")).plusDays(1)

    // Mesmo trajeto do RideFlowTests deslocado 1° ao norte, para as buscas de um não acharem as rotas do outro
    private val routeJson = """
        {
          "origin": {"label": "Casa", "latitude": -19.8113, "longitude": -49.3758},
          "destination": {"label": "Unirp", "latitude": -19.7850, "longitude": -49.3600},
          "weekdays": ["MONDAY","TUESDAY","WEDNESDAY","THURSDAY","FRIDAY","SATURDAY","SUNDAY"],
          "outboundTime": "07:00",
          "returnTime": "22:30",
          "maxDetourMeters": 300,
          "seats": 1,
          "priceCents": 600
        }
    """.trimIndent()

    private data class Account(val id: Long, val token: String)

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

    private fun post(path: String, account: Account, json: String) = mockMvc.post(path) {
        header("Authorization", "Bearer ${account.token}")
        contentType = MediaType.APPLICATION_JSON
        content = json
    }

    private fun get(path: String, account: Account) = mockMvc.get(path) {
        header("Authorization", "Bearer ${account.token}")
    }

    private fun send(from: Account, to: Account, text: String) =
        post("/messages/${to.id}", from, """{"content":"$text"}""")

    /** Motorista com uma rota e passageiro que pediu vaga nela. */
    private fun driverAndPassenger(): Pair<Account, Account> {
        val driver = register()
        val passenger = register()
        post("/routes", driver, routeJson).andExpect { status { isCreated() } }

        val ride = get("/rides/search?originLat=-19.79815&originLng=-49.3674&destinationLat=-19.7852&destinationLng=-49.3601&date=$tomorrow", passenger)
            .json()
            .first { it["ride"]["driver"]["id"].asLong() == driver.id }
        post(
            "/rides/${ride["ride"]["id"].asLong()}/requests",
            passenger,
            """{"pickup": ${ride["pickupPoint"]}, "recurring": false}"""
        ).andExpect { status { isCreated() } }
        return driver to passenger
    }

    private fun connect(account: Account, queue: LinkedBlockingQueue<String>): WebSocketSession =
        StandardWebSocketClient().execute(
            object : TextWebSocketHandler() {
                override fun handleTextMessage(session: WebSocketSession, message: TextMessage) {
                    queue.add(message.payload)
                }
            },
            WebSocketHttpHeaders(),
            URI("ws://localhost:$port/ws/messages?token=${account.token}")
        ).get(5, TimeUnit.SECONDS)

    @Test
    fun `motorista e passageiro conversam e estranhos nao`() {
        val (driver, passenger) = driverAndPassenger()
        val stranger = register()

        send(passenger, driver, "Oi, pode me pegar na esquina?").andExpect {
            status { isCreated() }
            jsonPath("$.from.id") { value(passenger.id) }
            jsonPath("$.to.id") { value(driver.id) }
        }
        send(driver, passenger, "Posso sim!").andExpect { status { isCreated() } }

        get("/messages/${passenger.id}", driver).andExpect {
            status { isOk() }
            jsonPath("$.length()") { value(2) }
            jsonPath("$[0].content") { value("Oi, pode me pegar na esquina?") }
            jsonPath("$[1].content") { value("Posso sim!") }
        }
        get("/messages", passenger).andExpect {
            status { isOk() }
            jsonPath("$.length()") { value(1) }
            jsonPath("$[0].person.id") { value(driver.id) }
            jsonPath("$[0].lastMessage.content") { value("Posso sim!") }
        }

        send(stranger, driver, "Oi").andExpect { status { isForbidden() } }
        send(driver, driver, "Oi").andExpect { status { isUnprocessableContent() } }
        send(driver, passenger, "   ").andExpect { status { isBadRequest() } }
        post("/messages/999999", driver, """{"content":"Oi"}""").andExpect { status { isNotFound() } }
        get("/messages/${driver.id}", stranger).andExpect { jsonPath("$.length()") { value(0) } }
    }

    @Test
    fun `mensagem chega pelo websocket para destinatario e remetente`() {
        val (driver, passenger) = driverAndPassenger()
        val driverInbox = LinkedBlockingQueue<String>()
        val passengerInbox = LinkedBlockingQueue<String>()
        val driverSocket = connect(driver, driverInbox)
        val passengerSocket = connect(passenger, passengerInbox)

        try {
            send(passenger, driver, "Já estou no ponto").andExpect { status { isCreated() } }

            val received = assertNotNull(driverInbox.poll(5, TimeUnit.SECONDS), "motorista não recebeu a mensagem")
            assertEquals("Já estou no ponto", objectMapper.readTree(received)["content"].asString())
            assertEquals(passenger.id, objectMapper.readTree(received)["from"]["id"].asLong())
            assertNotNull(passengerInbox.poll(5, TimeUnit.SECONDS), "remetente não recebeu a própria mensagem")
        } finally {
            driverSocket.close()
            passengerSocket.close()
        }
    }

    @Test
    fun `websocket sem token valido e recusado`() {
        val queue = LinkedBlockingQueue<String>()
        assertFailsWith<ExecutionException> { connect(Account(0, "invalido"), queue) }
    }

}
