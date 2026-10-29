package me.rafaelpereira.caronaapp.services

import me.rafaelpereira.caronaapp.config.JwtProperties
import me.rafaelpereira.caronaapp.config.SecurityConfig
import me.rafaelpereira.caronaapp.models.User
import org.springframework.security.oauth2.jose.jws.MacAlgorithm
import org.springframework.security.oauth2.jwt.JwsHeader
import org.springframework.security.oauth2.jwt.JwtClaimsSet
import org.springframework.security.oauth2.jwt.JwtEncoder
import org.springframework.security.oauth2.jwt.JwtEncoderParameters
import org.springframework.stereotype.Service
import java.time.Instant

@Service
class TokenService(
    private val jwtEncoder: JwtEncoder,
    private val jwtProperties: JwtProperties
) {

    fun generate(user: User): String {
        val now = Instant.now()
        val authorities = user.roles.map { it.authority } + user.permissions.map { it.authority }

        val claims = JwtClaimsSet.builder()
            .issuer(jwtProperties.issuer)
            .subject(user.id.toString())
            .issuedAt(now)
            .expiresAt(now.plus(jwtProperties.expiration))
            .claim("name", user.name)
            .claim("email", user.email)
            .claim(SecurityConfig.AUTHORITIES_CLAIM, authorities)
            .build()

        val header = JwsHeader.with(MacAlgorithm.HS256).build()
        return jwtEncoder.encode(JwtEncoderParameters.from(header, claims)).tokenValue
    }

    val expiresInSeconds: Long
        get() = jwtProperties.expiration.seconds

}
