package me.rafaelpereira.caronaapp.controllers

import jakarta.validation.Valid
import me.rafaelpereira.caronaapp.config.userId
import me.rafaelpereira.caronaapp.controllers.dto.ConversationDto
import me.rafaelpereira.caronaapp.controllers.dto.MessageResponseDto
import me.rafaelpereira.caronaapp.controllers.dto.SendMessageDto
import me.rafaelpereira.caronaapp.services.MessageService
import org.springframework.http.HttpStatus
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController

/**
 * Mensagens diretas. O envio é por aqui; quem estiver conectado em `/ws/messages`
 * recebe a mensagem em tempo real (ver [me.rafaelpereira.caronaapp.websocket.MessageSocketHandler]).
 */
@RestController
@RequestMapping("/messages")
@PreAuthorize("hasAuthority('message:send')")
class MessageController(
    private val messageService: MessageService
) {

    @GetMapping
    fun conversations(@AuthenticationPrincipal jwt: Jwt): List<ConversationDto> =
        messageService.conversations(jwt.userId)

    @GetMapping("/{userId}")
    fun conversation(@AuthenticationPrincipal jwt: Jwt, @PathVariable userId: Long): List<MessageResponseDto> =
        messageService.conversation(jwt.userId, userId)

    @PostMapping("/{userId}")
    @ResponseStatus(HttpStatus.CREATED)
    fun send(
        @AuthenticationPrincipal jwt: Jwt,
        @PathVariable userId: Long,
        @Valid @RequestBody dto: SendMessageDto
    ): MessageResponseDto = messageService.send(jwt.userId, userId, dto)

}
