package me.rafaelpereira.caronaapp.models

import jakarta.persistence.AttributeOverride
import jakarta.persistence.Column
import jakarta.persistence.Embedded
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
 * Pedido de vaga feito a partir de uma [Ride]. Se [recurring], vale para todos os dias da rota
 * no mesmo sentido a partir da data dessa carona ("Repetir toda semana").
 */
@Entity
@Table(name = "ride_requests")
class RideRequest(
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "passenger_id")
    var passenger: User,

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "ride_id")
    var ride: Ride,

    @Column(nullable = false)
    var recurring: Boolean,

    @Embedded
    @AttributeOverride(name = "label", column = Column(name = "pickup_label"))
    @AttributeOverride(name = "latitude", column = Column(name = "pickup_latitude"))
    @AttributeOverride(name = "longitude", column = Column(name = "pickup_longitude"))
    var pickup: Location,

    @Column(nullable = false)
    var detourMeters: Int,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    var status: RideRequestStatus = RideRequestStatus.PENDING,

    @Column(nullable = false)
    val createdAt: Instant = Instant.now(),

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null
) {

    val route: Route get() = ride.route

}
