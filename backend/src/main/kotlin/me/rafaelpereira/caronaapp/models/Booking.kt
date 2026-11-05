package me.rafaelpereira.caronaapp.models

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.FetchType
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.JoinColumn
import jakarta.persistence.ManyToOne
import jakarta.persistence.Table
import java.time.Instant

/**
 * Vaga confirmada de um passageiro em uma [Ride], criada quando o motorista aceita o [RideRequest].
 * Pode ser cancelada individualmente ("Não vou") sem cancelar o pedido recorrente.
 *
 * Poucas horas antes da saída o passageiro precisa confirmar que vai ([presenceConfirmedAt]);
 * quem não confirma até o prazo perde a vaga ([expiredAt], com status [BookingStatus.CANCELLED]).
 * Ao confirmar, ele recebe o [boardingCode] que o motorista digita para registrar o embarque ([boardedAt]).
 */
@Entity
@Table(name = "bookings")
class Booking(
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "ride_id")
    var ride: Ride,

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "request_id")
    var request: RideRequest,

    @Column(nullable = false)
    var priceCents: Int,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    var status: BookingStatus = BookingStatus.CONFIRMED,

    @Column(nullable = false)
    val createdAt: Instant = Instant.now(),

    var presenceConfirmedAt: Instant? = null,

    /** Quando a vaga foi liberada por falta de confirmação; nulo se o passageiro cancelou por conta própria. */
    var expiredAt: Instant? = null,

    @Column(length = 4)
    var boardingCode: String? = null,

    var boardedAt: Instant? = null,

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null
) {

    val passenger: User get() = request.passenger

}
