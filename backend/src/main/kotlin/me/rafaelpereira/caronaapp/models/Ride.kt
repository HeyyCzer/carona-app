package me.rafaelpereira.caronaapp.models

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
import jakarta.persistence.UniqueConstraint
import me.rafaelpereira.caronaapp.utils.Geo
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import kotlin.math.ceil
import kotlin.math.roundToInt

/**
 * Uma ocorrência concreta de uma [Route]: um dia e um sentido (ida ou volta).
 * Vagas e preço são copiados da rota no momento em que a carona é gerada.
 */
@Entity
@Table(
    name = "rides",
    uniqueConstraints = [UniqueConstraint(columnNames = ["route_id", "ride_date", "direction"])]
)
class Ride(
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "route_id")
    var route: Route,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    var direction: RideDirection,

    @Column(name = "ride_date", nullable = false)
    var date: LocalDate,

    @Column(nullable = false)
    var departureTime: LocalTime,

    @Column(nullable = false)
    var seats: Int,

    @Column(nullable = false)
    var priceCents: Int,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    var status: RideStatus = RideStatus.SCHEDULED,

    /** Última posição enviada pelo motorista durante a viagem. */
    @Embedded
    var driverLocation: VehicleLocation? = null,

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null
) {

    val driver: User get() = route.driver

    val from: Location
        get() = if (direction == RideDirection.OUTBOUND) route.origin else route.destination

    val to: Location
        get() = if (direction == RideDirection.OUTBOUND) route.destination else route.origin

    val roadPath: RoadPath? get() = route.path(direction)

    val departure: LocalDateTime get() = LocalDateTime.of(date, departureTime)

    /** Pontos do trajeto pelas ruas ou, sem ele, a linha reta entre a saída e a chegada. */
    fun pathPoints(): List<Location> = roadPath?.points() ?: listOf(from, to)

    val distanceMeters: Int get() = roadPath?.distanceMeters ?: Geo.roadDistanceMeters(from, to)

    /** Minutos de viagem até a parte [fraction] do trajeto (1 = chegada). */
    fun travelMinutes(fraction: Double = 1.0): Long {
        val path = roadPath ?: return Geo.travelMinutes((Geo.roadDistanceMeters(from, to) * fraction).roundToInt())
        return ceil(path.durationSeconds * fraction / 60).toLong()
    }

}
