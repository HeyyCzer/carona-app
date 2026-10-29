package me.rafaelpereira.caronaapp.config

import org.springframework.boot.context.properties.ConfigurationProperties
import java.time.Duration

@ConfigurationProperties("app.jwt")
data class JwtProperties(
    val secret: String,
    val expiration: Duration = Duration.ofHours(24),
    val issuer: String = "carona-app"
)
