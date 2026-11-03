package me.rafaelpereira.caronaapp.repositories

import me.rafaelpereira.caronaapp.models.Message
import org.springframework.data.jpa.repository.EntityGraph
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository

@Repository
interface MessageRepository : JpaRepository<Message, Long> {

    /** Todas as mensagens enviadas ou recebidas pelo usuário, da mais recente para a mais antiga. */
    @EntityGraph(attributePaths = ["sender", "recipient"])
    @Query("select m from Message m where m.sender.id = :userId or m.recipient.id = :userId order by m.createdAt desc, m.id desc")
    fun findAllOf(userId: Long): List<Message>

    /** Conversa entre dois usuários, em ordem cronológica. */
    @EntityGraph(attributePaths = ["sender", "recipient"])
    @Query(
        """
        select m from Message m
        where (m.sender.id = :userId and m.recipient.id = :otherId)
           or (m.sender.id = :otherId and m.recipient.id = :userId)
        order by m.createdAt asc, m.id asc
        """
    )
    fun findConversation(userId: Long, otherId: Long): List<Message>

    fun existsBySenderIdAndRecipientId(senderId: Long, recipientId: Long): Boolean

}
