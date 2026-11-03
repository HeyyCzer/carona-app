package me.rafaelpereira.caronaapp.websocket

import me.rafaelpereira.caronaapp.services.MessageSentEvent
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import org.springframework.transaction.event.TransactionalEventListener
import org.springframework.web.socket.CloseStatus
import org.springframework.web.socket.TextMessage
import org.springframework.web.socket.WebSocketSession
import org.springframework.web.socket.handler.ConcurrentWebSocketSessionDecorator
import org.springframework.web.socket.handler.TextWebSocketHandler
import tools.jackson.databind.ObjectMapper
import java.io.IOException
import java.util.concurrent.ConcurrentHashMap

/**
 * Canal `/ws/messages`: só servidor -> cliente. Cada mensagem salva é enviada para todas as
 * conexões do destinatário e do remetente (para sincronizar outros aparelhos da mesma conta),
 * no mesmo JSON de `GET /messages/{userId}`.
 */
@Component
class MessageSocketHandler(
    private val objectMapper: ObjectMapper
) : TextWebSocketHandler() {

    private val log = LoggerFactory.getLogger(javaClass)

    /** Conexões abertas por usuário (o mesmo usuário pode estar em vários aparelhos). */
    private val sessions = ConcurrentHashMap<Long, MutableMap<String, WebSocketSession>>()

    override fun afterConnectionEstablished(session: WebSocketSession) {
        // O decorator serializa os envios: o Tomcat não aceita dois envios simultâneos na mesma sessão
        val safe = ConcurrentWebSocketSessionDecorator(session, SEND_TIME_LIMIT_MS, BUFFER_SIZE_LIMIT)
        sessions.computeIfAbsent(session.userId) { ConcurrentHashMap() }[session.id] = safe
    }

    override fun afterConnectionClosed(session: WebSocketSession, status: CloseStatus) {
        sessions.computeIfPresent(session.userId) { _, userSessions ->
            userSessions.remove(session.id)
            userSessions.ifEmpty { null }
        }
    }

    @TransactionalEventListener
    fun onMessageSent(event: MessageSentEvent) {
        val payload = TextMessage(objectMapper.writeValueAsString(event.message))
        listOf(event.message.to.id, event.message.from.id).distinct().forEach { userId ->
            sessions[userId]?.values?.forEach { send(it, payload) }
        }
    }

    private fun send(session: WebSocketSession, payload: TextMessage) {
        try {
            if (session.isOpen) session.sendMessage(payload)
        } catch (e: IOException) {
            log.debug("Falha ao enviar mensagem pelo WebSocket {}", session.id, e)
        } catch (e: IllegalStateException) {
            log.debug("Falha ao enviar mensagem pelo WebSocket {}", session.id, e)
        }
    }

    private val WebSocketSession.userId: Long
        get() = attributes[JwtHandshakeInterceptor.USER_ID] as Long

    companion object {
        private const val SEND_TIME_LIMIT_MS = 10_000
        private const val BUFFER_SIZE_LIMIT = 512 * 1024
    }

}
