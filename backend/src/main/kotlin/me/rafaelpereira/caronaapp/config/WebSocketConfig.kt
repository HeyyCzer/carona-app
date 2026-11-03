package me.rafaelpereira.caronaapp.config

import me.rafaelpereira.caronaapp.websocket.JwtHandshakeInterceptor
import me.rafaelpereira.caronaapp.websocket.MessageSocketHandler
import org.springframework.context.annotation.Configuration
import org.springframework.web.socket.config.annotation.EnableWebSocket
import org.springframework.web.socket.config.annotation.WebSocketConfigurer
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry

@Configuration
@EnableWebSocket
class WebSocketConfig(
    private val messageSocketHandler: MessageSocketHandler,
    private val jwtHandshakeInterceptor: JwtHandshakeInterceptor
) : WebSocketConfigurer {

    override fun registerWebSocketHandlers(registry: WebSocketHandlerRegistry) {
        registry.addHandler(messageSocketHandler, "/ws/messages")
            .addInterceptors(jwtHandshakeInterceptor)
            // A autenticação é pelo token, não por cookie, então qualquer origem pode conectar
            .setAllowedOriginPatterns("*")
    }

}
