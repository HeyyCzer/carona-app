package me.rafaelpereira.caronaapp.controllers

import me.rafaelpereira.caronaapp.config.userId
import me.rafaelpereira.caronaapp.controllers.dto.UserResponseDto
import me.rafaelpereira.caronaapp.services.AvatarService
import org.springframework.http.CacheControl
import org.springframework.http.MediaType
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.multipart.MultipartFile
import java.time.Duration

@RestController
class AvatarController(
    private val avatarService: AvatarService
) {

    /** Troca a foto de perfil (multipart, campo `file`). */
    @PutMapping("/me/avatar", consumes = [MediaType.MULTIPART_FORM_DATA_VALUE])
    fun upload(@AuthenticationPrincipal jwt: Jwt, @RequestParam file: MultipartFile): UserResponseDto =
        avatarService.upload(jwt.userId, file.bytes)

    @DeleteMapping("/me/avatar")
    fun delete(@AuthenticationPrincipal jwt: Jwt): UserResponseDto =
        avatarService.delete(jwt.userId)

    /** A URL que vem no `avatarUrl` muda a cada foto nova, então o app pode guardar em cache à vontade. */
    @GetMapping("/users/{id}/avatar")
    fun get(@PathVariable id: Long): ResponseEntity<ByteArray> {
        val avatar = avatarService.get(id)
        return ResponseEntity.ok()
            .contentType(avatar.mediaType)
            .cacheControl(CacheControl.maxAge(Duration.ofDays(30)).cachePrivate())
            .body(avatar.bytes)
    }

}
