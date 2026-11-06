package me.rafaelpereira.caronaapp.config

import org.springframework.boot.context.properties.ConfigurationProperties
import org.springframework.util.unit.DataSize

/** Pasta onde ficam as fotos de perfil, uma por usuário, com o id do usuário como nome do arquivo. */
@ConfigurationProperties("app.avatars")
data class AvatarProperties(
    val dir: String = "avatars",
    val maxSize: DataSize = DataSize.ofMegabytes(5)
)
