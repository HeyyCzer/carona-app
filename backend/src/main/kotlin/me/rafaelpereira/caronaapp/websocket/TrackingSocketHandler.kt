package me.rafaelpereira.caronaapp.websocket

import me.rafaelpereira.caronaapp.services.RideLocationEvent
import me.rafaelpereira.caronaapp.services.TrackingService
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import org.springframework.transaction.event.TransactionalEventListener
import org.springframework.web.socket.CloseStatus
import org.springframework.web.socket.TextMessage
import org.springframework.web.socket.WebSocketSession
import org.springframework.web.socket.handler.ConcurrentWebSocketSessionDecorator
import org.springframework.web.socket.handler.TextWebSocketHandler
import org.springframework.web.util.UriComponentsBuilder
import tools.jackson.databind.ObjectMapper
import java.io.IOException
import java.util.concurrent.ConcurrentHashMap

/**
 * Canal `/ws/tracking?rideId=...`: só servidor -> cliente. Ao conectar, manda a última posição
 * conhecida; depois, cada posição nova do motorista, no mesmo JSON de `GET /rides/{id}/location`.
 * Só o motorista e os passageiros com vaga ativa na carona podem conectar.
 */
@Component
class TrackingSocketHandler(
    private val trackingService: TrackingService,
    private val objectMapper: ObjectMapper
) : TextWebSocketHandler() {

    private val log = LoggerFactory.getLogger(javaClass)

    /** Conexões abertas por carona. */
    private val sessions = ConcurrentHashMap<Long, MutableMap<String, WebSocketSession>>()

    override fun afterConnectionEstablished(session: WebSocketSession) {
        val rideId = session.uri?.let { UriComponentsBuilder.fromUri(it).build().queryParams.getFirst("rideId") }
            ?.toLongOrNull()
        val userId = session.attributes[JwtHandshakeInterceptor.USER_ID] as Long
        if (rideId == null || !trackingService.canWatch(userId, rideId)) {
            session.close(CloseStatus.POLICY_VIOLATION.withReason("Você não está nessa carona"))
            return
        }

        session.attributes[RIDE_ID] = rideId
        val safe = ConcurrentWebSocketSessionDecorator(session, SEND_TIME_LIMIT_MS, BUFFER_SIZE_LIMIT)
        sessions.computeIfAbsent(rideId) { ConcurrentHashMap() }[session.id] = safe
        trackingService.get(userId, rideId)?.let { send(safe, TextMessage(objectMapper.writeValueAsString(it))) }
    }

    override fun afterConnectionClosed(session: WebSocketSession, status: CloseStatus) {
        val rideId = session.attributes[RIDE_ID] as Long? ?: return
        sessions.computeIfPresent(rideId) { _, rideSessions ->
            rideSessions.remove(session.id)
            rideSessions.ifEmpty { null }
        }
    }

    @TransactionalEventListener
    fun onLocation(event: RideLocationEvent) {
        val payload = TextMessage(objectMapper.writeValueAsString(event.location))
        sessions[event.location.rideId]?.values?.forEach { send(it, payload) }
    }

    private fun send(session: WebSocketSession, payload: TextMessage) {
        try {
            if (session.isOpen) session.sendMessage(payload)
        } catch (e: IOException) {
            log.debug("Falha ao enviar posição pelo WebSocket {}", session.id, e)
        } catch (e: IllegalStateException) {
            log.debug("Falha ao enviar posição pelo WebSocket {}", session.id, e)
        }
    }

    companion object {
        private const val RIDE_ID = "rideId"
        private const val SEND_TIME_LIMIT_MS = 10_000
        private const val BUFFER_SIZE_LIMIT = 64 * 1024
    }

}
