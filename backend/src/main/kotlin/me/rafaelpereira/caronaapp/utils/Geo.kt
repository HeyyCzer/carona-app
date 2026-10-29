package me.rafaelpereira.caronaapp.utils

import me.rafaelpereira.caronaapp.models.Location
import kotlin.math.asin
import kotlin.math.ceil
import kotlin.math.cos
import kotlin.math.hypot
import kotlin.math.pow
import kotlin.math.roundToInt
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * Cálculos geográficos aproximados, sem serviço de mapas: as rotas são tratadas como
 * linha reta entre origem e destino, corrigida por [ROAD_FACTOR] para estimar a distância pelas ruas.
 */
object Geo {

    private const val EARTH_RADIUS_METERS = 6_371_000.0
    private const val ROAD_FACTOR = 1.3
    private const val AVERAGE_SPEED_METERS_PER_MINUTE = 25_000.0 / 60

    data class Projection(val point: Location, val distanceMeters: Double, val fraction: Double)

    fun distanceMeters(a: Location, b: Location): Double {
        val dLat = Math.toRadians(b.latitude - a.latitude)
        val dLng = Math.toRadians(b.longitude - a.longitude)
        val h = sin(dLat / 2).pow(2) +
            cos(Math.toRadians(a.latitude)) * cos(Math.toRadians(b.latitude)) * sin(dLng / 2).pow(2)
        return 2 * EARTH_RADIUS_METERS * asin(sqrt(h))
    }

    fun roadDistanceMeters(a: Location, b: Location): Int =
        (distanceMeters(a, b) * ROAD_FACTOR).roundToInt()

    fun travelMinutes(roadMeters: Int): Long =
        ceil(roadMeters / AVERAGE_SPEED_METERS_PER_MINUTE).toLong()

    /** Quanto o motorista roda a mais para passar por [via] no caminho de [from] até [to]. */
    fun detourMeters(from: Location, to: Location, via: Location): Int {
        val extra = distanceMeters(from, via) + distanceMeters(via, to) - distanceMeters(from, to)
        return (extra.coerceAtLeast(0.0) * ROAD_FACTOR).roundToInt()
    }

    /**
     * Ponto do trajeto [from]→[to] mais próximo de [point], com a distância até ele e a fração
     * do trajeto (0 = início, 1 = fim). Usa projeção plana local, suficiente para distâncias urbanas.
     */
    fun project(point: Location, from: Location, to: Location): Projection {
        val metersPerDegreeLat = Math.toRadians(1.0) * EARTH_RADIUS_METERS
        val metersPerDegreeLng = metersPerDegreeLat * cos(Math.toRadians(from.latitude))

        val segmentX = (to.longitude - from.longitude) * metersPerDegreeLng
        val segmentY = (to.latitude - from.latitude) * metersPerDegreeLat
        val pointX = (point.longitude - from.longitude) * metersPerDegreeLng
        val pointY = (point.latitude - from.latitude) * metersPerDegreeLat

        val lengthSquared = segmentX * segmentX + segmentY * segmentY
        val fraction = if (lengthSquared == 0.0) 0.0
        else ((pointX * segmentX + pointY * segmentY) / lengthSquared).coerceIn(0.0, 1.0)

        val projected = Location(
            label = "Ponto de embarque",
            latitude = from.latitude + fraction * segmentY / metersPerDegreeLat,
            longitude = from.longitude + fraction * segmentX / metersPerDegreeLng
        )
        val distance = hypot(pointX - fraction * segmentX, pointY - fraction * segmentY)
        return Projection(projected, distance, fraction)
    }

}
