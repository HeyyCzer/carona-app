package me.rafaelpereira.caronaapp.models

import jakarta.persistence.Column
import jakarta.persistence.Embeddable
import java.time.Instant

/** Posição do carro durante a viagem, enviada pelo app do motorista. */
@Embeddable
class VehicleLocation(
    @Column(name = "vehicle_latitude")
    var latitude: Double,

    @Column(name = "vehicle_longitude")
    var longitude: Double,

    /** Direção em graus (0 = norte), quando o GPS informa. */
    @Column(name = "vehicle_heading")
    var heading: Double? = null,

    /** Velocidade em m/s, quando o GPS informa. */
    @Column(name = "vehicle_speed")
    var speedMps: Double? = null,

    @Column(name = "vehicle_updated_at")
    var updatedAt: Instant
)
