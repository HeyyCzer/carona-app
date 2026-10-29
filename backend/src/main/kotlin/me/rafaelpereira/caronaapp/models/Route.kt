package me.rafaelpereira.caronaapp.models

import jakarta.persistence.AttributeOverride
import jakarta.persistence.CollectionTable
import jakarta.persistence.Column
import jakarta.persistence.ElementCollection
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
import java.time.DayOfWeek
import java.time.Instant
import java.time.LocalTime

/**
 * Rota recorrente publicada por um motorista. As caronas ([Ride]) de cada dia são geradas a partir dela.
 */
@Entity
@Table(name = "routes")
class Route(
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "driver_id")
    var driver: User,

    @Embedded
    @AttributeOverride(name = "label", column = Column(name = "origin_label"))
    @AttributeOverride(name = "latitude", column = Column(name = "origin_latitude"))
    @AttributeOverride(name = "longitude", column = Column(name = "origin_longitude"))
    var origin: Location,

    @Embedded
    @AttributeOverride(name = "label", column = Column(name = "destination_label"))
    @AttributeOverride(name = "latitude", column = Column(name = "destination_latitude"))
    @AttributeOverride(name = "longitude", column = Column(name = "destination_longitude"))
    var destination: Location,

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "route_weekdays", joinColumns = [JoinColumn(name = "route_id")])
    @Enumerated(EnumType.STRING)
    @Column(name = "weekday", nullable = false)
    var weekdays: MutableSet<DayOfWeek>,

    @Column(nullable = false)
    var outboundTime: LocalTime,

    var returnTime: LocalTime?,

    /** Trajeto pelas ruas da ida; nulo se o OSRM não respondeu, e aí vale a linha reta. */
    @Embedded
    @AttributeOverride(name = "polyline", column = Column(name = "outbound_polyline", columnDefinition = "TEXT"))
    @AttributeOverride(name = "distanceMeters", column = Column(name = "outbound_distance_meters"))
    @AttributeOverride(name = "durationSeconds", column = Column(name = "outbound_duration_seconds"))
    var outboundPath: RoadPath? = null,

    /** Trajeto pelas ruas da volta, que pode diferir da ida por causa das mãos de direção. */
    @Embedded
    @AttributeOverride(name = "polyline", column = Column(name = "return_polyline", columnDefinition = "TEXT"))
    @AttributeOverride(name = "distanceMeters", column = Column(name = "return_distance_meters"))
    @AttributeOverride(name = "durationSeconds", column = Column(name = "return_duration_seconds"))
    var returnPath: RoadPath? = null,

    @Column(nullable = false)
    var maxDetourMeters: Int,

    @Column(nullable = false)
    var seats: Int,

    @Column(nullable = false)
    var priceCents: Int,

    @Column(nullable = false)
    var active: Boolean = true,

    @Column(nullable = false)
    val createdAt: Instant = Instant.now(),

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null
) {

    fun departureTime(direction: RideDirection): LocalTime? = when (direction) {
        RideDirection.OUTBOUND -> outboundTime
        RideDirection.RETURN -> returnTime
    }

    fun path(direction: RideDirection): RoadPath? = when (direction) {
        RideDirection.OUTBOUND -> outboundPath
        RideDirection.RETURN -> returnPath
    }

}
