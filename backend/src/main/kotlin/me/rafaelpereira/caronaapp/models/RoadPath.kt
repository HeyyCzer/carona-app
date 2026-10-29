package me.rafaelpereira.caronaapp.models

import jakarta.persistence.Column
import jakarta.persistence.Embeddable
import me.rafaelpereira.caronaapp.utils.Polyline

/** Trajeto pelas ruas calculado pelo OSRM, com a geometria em [Polyline]. */
@Embeddable
class RoadPath(
    @Column(columnDefinition = "TEXT")
    var polyline: String,
    var distanceMeters: Int,
    var durationSeconds: Int
) {

    fun points(): List<Location> = Polyline.decode(polyline)

}
