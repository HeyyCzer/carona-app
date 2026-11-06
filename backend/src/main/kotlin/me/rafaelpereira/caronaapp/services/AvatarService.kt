package me.rafaelpereira.caronaapp.services

import me.rafaelpereira.caronaapp.config.AvatarProperties
import me.rafaelpereira.caronaapp.controllers.dto.UserResponseDto
import me.rafaelpereira.caronaapp.models.User
import me.rafaelpereira.caronaapp.repositories.UserRepository
import org.springframework.data.repository.findByIdOrNull
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.server.ResponseStatusException
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption
import java.time.Clock

/** Foto lida da pasta de avatares, pronta para servir. */
class Avatar(val bytes: ByteArray, val mediaType: MediaType)

/**
 * Fotos de perfil na pasta [AvatarProperties.dir], uma por usuário: `{id}.jpg`, `{id}.png` ou `{id}.webp`.
 * O tipo é conferido pelos primeiros bytes do arquivo, não pelo que o cliente diz.
 */
@Service
class AvatarService(
    private val userRepository: UserRepository,
    private val properties: AvatarProperties,
    private val clock: Clock
) {

    private val dir: Path get() = Path.of(properties.dir)

    @Transactional
    fun upload(userId: Long, bytes: ByteArray): UserResponseDto {
        if (bytes.isEmpty()) {
            throw ResponseStatusException(HttpStatus.BAD_REQUEST, "Envie uma foto")
        }
        if (bytes.size > properties.maxSize.toBytes()) {
            throw ResponseStatusException(HttpStatus.CONTENT_TOO_LARGE, "A foto deve ter até ${properties.maxSize.toMegabytes()} MB")
        }
        val format = ImageFormat.detect(bytes)
            ?: throw ResponseStatusException(HttpStatus.UNSUPPORTED_MEDIA_TYPE, "Use uma foto JPEG, PNG ou WebP")
        val user = findUser(userId)

        Files.createDirectories(dir)
        // Grava num temporário e move, para ninguém ler uma foto pela metade
        val temp = Files.createTempFile(dir, "$userId-", ".tmp")
        try {
            Files.write(temp, bytes)
            Files.move(temp, file(userId, format), StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE)
        } finally {
            Files.deleteIfExists(temp)
        }
        ImageFormat.entries.filter { it != format }.forEach { Files.deleteIfExists(file(userId, it)) }

        user.avatarUpdatedAt = clock.instant()
        return UserResponseDto.from(user)
    }

    @Transactional
    fun delete(userId: Long): UserResponseDto {
        val user = findUser(userId)
        ImageFormat.entries.forEach { Files.deleteIfExists(file(userId, it)) }
        user.avatarUpdatedAt = null
        return UserResponseDto.from(user)
    }

    fun get(userId: Long): Avatar {
        for (format in ImageFormat.entries) {
            val path = file(userId, format)
            if (Files.isRegularFile(path)) return Avatar(Files.readAllBytes(path), format.mediaType)
        }
        throw ResponseStatusException(HttpStatus.NOT_FOUND, "Essa pessoa não tem foto")
    }

    private fun file(userId: Long, format: ImageFormat): Path = dir.resolve("$userId.${format.extension}")

    private fun findUser(id: Long): User = userRepository.findByIdOrNull(id)
        ?: throw ResponseStatusException(HttpStatus.NOT_FOUND, "Usuário não encontrado")

    enum class ImageFormat(val extension: String, val mediaType: MediaType) {
        JPEG("jpg", MediaType.IMAGE_JPEG),
        PNG("png", MediaType.IMAGE_PNG),
        WEBP("webp", MediaType.parseMediaType("image/webp"));

        companion object {
            fun detect(bytes: ByteArray): ImageFormat? = when {
                bytes.startsWith(0xFF, 0xD8, 0xFF) -> JPEG
                bytes.startsWith(0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A) -> PNG
                bytes.size >= 12 && bytes.startsWith(0x52, 0x49, 0x46, 0x46) &&
                    String(bytes, 8, 4, Charsets.US_ASCII) == "WEBP" -> WEBP
                else -> null
            }

            private fun ByteArray.startsWith(vararg prefix: Int): Boolean =
                size >= prefix.size && prefix.indices.all { this[it] == prefix[it].toByte() }
        }
    }

}
