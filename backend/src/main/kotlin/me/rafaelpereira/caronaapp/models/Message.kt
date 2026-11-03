package me.rafaelpereira.caronaapp.models

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.FetchType
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Index
import jakarta.persistence.JoinColumn
import jakarta.persistence.ManyToOne
import jakarta.persistence.Table
import java.time.Instant

/** Mensagem direta entre dois usuários que compartilham uma carona (motorista e passageiro). */
@Entity
@Table(
    name = "messages",
    indexes = [
        Index(columnList = "sender_id, recipient_id"),
        Index(columnList = "recipient_id, sender_id")
    ]
)
class Message(
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "sender_id")
    var sender: User,

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "recipient_id")
    var recipient: User,

    @Column(nullable = false, length = 2000)
    var content: String,

    @Column(nullable = false)
    val createdAt: Instant = Instant.now(),

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null
)
