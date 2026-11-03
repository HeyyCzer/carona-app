package me.rafaelpereira.caronaapp.controllers.dto

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size
import me.rafaelpereira.caronaapp.models.Message
import java.time.Instant

data class SendMessageDto(
    @field:NotBlank
    @field:Size(max = 2000)
    val content: String
)

data class MessageResponseDto(
    val id: Long,
    val from: PersonDto,
    val to: PersonDto,
    val content: String,
    val createdAt: Instant
) {
    companion object {
        fun from(message: Message) = MessageResponseDto(
            id = message.id!!,
            from = PersonDto.from(message.sender),
            to = PersonDto.from(message.recipient),
            content = message.content,
            createdAt = message.createdAt
        )
    }
}

/** Uma conversa na lista de mensagens: a outra pessoa e a última mensagem trocada. */
data class ConversationDto(
    val person: PersonDto,
    val lastMessage: MessageResponseDto
)
