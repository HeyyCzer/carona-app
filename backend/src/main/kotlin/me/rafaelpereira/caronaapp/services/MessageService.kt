package me.rafaelpereira.caronaapp.services

import me.rafaelpereira.caronaapp.controllers.dto.ConversationDto
import me.rafaelpereira.caronaapp.controllers.dto.MessageResponseDto
import me.rafaelpereira.caronaapp.controllers.dto.PersonDto
import me.rafaelpereira.caronaapp.controllers.dto.SendMessageDto
import me.rafaelpereira.caronaapp.models.Message
import me.rafaelpereira.caronaapp.repositories.MessageRepository
import me.rafaelpereira.caronaapp.repositories.RideRequestRepository
import me.rafaelpereira.caronaapp.repositories.UserRepository
import org.springframework.context.ApplicationEventPublisher
import org.springframework.data.repository.findByIdOrNull
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.server.ResponseStatusException

/** Publicado ao salvar uma mensagem; entregue pelo WebSocket depois do commit. */
data class MessageSentEvent(val message: MessageResponseDto)

@Service
class MessageService(
    private val messageRepository: MessageRepository,
    private val rideRequestRepository: RideRequestRepository,
    private val userRepository: UserRepository,
    private val events: ApplicationEventPublisher
) {

    /** Uma entrada por pessoa com quem o usuário já trocou mensagens, da conversa mais recente para a mais antiga. */
    @Transactional(readOnly = true)
    fun conversations(userId: Long): List<ConversationDto> =
        messageRepository.findAllOf(userId)
            .distinctBy { if (it.sender.id == userId) it.recipient.id else it.sender.id }
            .map {
                val other = if (it.sender.id == userId) it.recipient else it.sender
                ConversationDto(PersonDto.from(other), MessageResponseDto.from(it))
            }

    @Transactional(readOnly = true)
    fun conversation(userId: Long, otherId: Long): List<MessageResponseDto> =
        messageRepository.findConversation(userId, otherId).map(MessageResponseDto::from)

    @Transactional
    fun send(senderId: Long, recipientId: Long, dto: SendMessageDto): MessageResponseDto {
        if (senderId == recipientId) {
            throw ResponseStatusException(HttpStatus.UNPROCESSABLE_CONTENT, "Você não pode mandar mensagem para si mesmo")
        }
        val recipient = userRepository.findByIdOrNull(recipientId)
            ?: throw ResponseStatusException(HttpStatus.NOT_FOUND, "Usuário não encontrado")
        if (!canTalk(senderId, recipientId)) {
            throw ResponseStatusException(
                HttpStatus.FORBIDDEN,
                "Você só pode conversar com motoristas e passageiros das suas caronas"
            )
        }

        val message = messageRepository.save(
            Message(
                sender = userRepository.getReferenceById(senderId),
                recipient = recipient,
                content = dto.content.trim()
            )
        )
        return MessageResponseDto.from(message).also { events.publishEvent(MessageSentEvent(it)) }
    }

    /**
     * Duas pessoas podem conversar se uma já pediu vaga numa rota da outra
     * (ou se já existe conversa entre elas, para ninguém ficar sem poder responder).
     */
    private fun canTalk(a: Long, b: Long): Boolean =
        rideRequestRepository.existsByPassengerIdAndRideRouteDriverId(a, b) ||
            rideRequestRepository.existsByPassengerIdAndRideRouteDriverId(b, a) ||
            messageRepository.existsBySenderIdAndRecipientId(b, a)

}
