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

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null
) {

    val passenger: User get() = request.passenger

}
