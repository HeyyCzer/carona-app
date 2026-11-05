package me.rafaelpereira.caronaapp.websocket

import me.rafaelpereira.caronaapp.config.SecurityConfig
import me.rafaelpereira.caronaapp.config.userId
import me.rafaelpereira.caronaapp.models.Permission
import org.springframework.http.HttpHeaders
import org.springframework.http.HttpStatus
import org.springframework.http.server.ServerHttpRequest
import org.springframework.http.server.ServerHttpResponse
import org.springframework.security.oauth2.jwt.JwtDecoder
import org.springframework.security.oauth2.jwt.JwtException
import org.springframework.web.socket.WebSocketHandler
import org.springframework.web.socket.server.HandshakeInterceptor
import org.springframework.web.util.UriComponentsBuilder

/**
 * Autentica o handshake do WebSocket com o mesmo JWT da API. O token pode vir no header
 * `Authorization: Bearer ...` ou, para clientes que não conseguem mandar headers, em `?token=...`.
 * Cada canal exige uma permissão ([requiredPermission]).
 */
class JwtHandshakeInterceptor(
    private val jwtDecoder: JwtDecoder,
    private val requiredPermission: Permission
) : HandshakeInterceptor {

    override fun beforeHandshake(
        request: ServerHttpRequest,
        response: ServerHttpResponse,
        wsHandler: WebSocketHandler,
        attributes: MutableMap<String, Any>
    ): Boolean {
        val token = request.headers.getFirst(HttpHeaders.AUTHORIZATION)?.removePrefix("Bearer ")
            ?: UriComponentsBuilder.fromUri(request.uri).build().queryParams.getFirst("token")

        val jwt = try {
            token?.let(jwtDecoder::decode)
        } catch (_: JwtException) {
            null
        }
        if (jwt == null) {
            response.setStatusCode(HttpStatus.UNAUTHORIZED)
            return false
        }
        if (requiredPermission.authority !in jwt.getClaimAsStringList(SecurityConfig.AUTHORITIES_CLAIM).orEmpty()) {
            response.setStatusCode(HttpStatus.FORBIDDEN)
            return false
        }

        attributes[USER_ID] = jwt.userId
        return true
    }

    override fun afterHandshake(
        request: ServerHttpRequest,
        response: ServerHttpResponse,
        wsHandler: WebSocketHandler,
        exception: Exception?
    ) = Unit

    companion object {
        const val USER_ID = "userId"
    }

}
