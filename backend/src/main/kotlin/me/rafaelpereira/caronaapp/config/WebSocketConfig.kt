package me.rafaelpereira.caronaapp.config

import me.rafaelpereira.caronaapp.models.Permission
import me.rafaelpereira.caronaapp.websocket.JwtHandshakeInterceptor
import me.rafaelpereira.caronaapp.websocket.MessageSocketHandler
import me.rafaelpereira.caronaapp.websocket.TrackingSocketHandler
import org.springframework.context.annotation.Configuration
import org.springframework.security.oauth2.jwt.JwtDecoder
import org.springframework.web.socket.config.annotation.EnableWebSocket
import org.springframework.web.socket.config.annotation.WebSocketConfigurer
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry

@Configuration
@EnableWebSocket
class WebSocketConfig(
    private val messageSocketHandler: MessageSocketHandler,
    private val trackingSocketHandler: TrackingSocketHandler,
    private val jwtDecoder: JwtDecoder
) : WebSocketConfigurer {

    override fun registerWebSocketHandlers(registry: WebSocketHandlerRegistry) {
        // A autenticação é pelo token, não por cookie, então qualquer origem pode conectar
        registry.addHandler(messageSocketHandler, "/ws/messages")
            .addInterceptors(JwtHandshakeInterceptor(jwtDecoder, Permission.MESSAGE_SEND))
            .setAllowedOriginPatterns("*")
        registry.addHandler(trackingSocketHandler, "/ws/tracking")
            .addInterceptors(JwtHandshakeInterceptor(jwtDecoder, Permission.RIDE_SEARCH))
            .setAllowedOriginPatterns("*")
    }

}
