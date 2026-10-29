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
 * Cálculos geográficos aproximados. Quando não há trajeto pelas ruas (OSRM fora do ar),
 * a rota é tratada como linha reta entre origem e destino, corrigida por [ROAD_FACTOR].
 */
object Geo {

    private const val EARTH_RADIUS_METERS = 6_371_000.0
    private const val ROAD_FACTOR = 1.3
    private const val AVERAGE_SPEED_METERS_PER_MINUTE = 25_000.0 / 60
    private const val PICKUP_LABEL = "Ponto de embarque"

    /** [fraction] é a parte do comprimento do trajeto já percorrida até [point] (0 = início, 1 = fim). */
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

    /**
     * Quanto o motorista roda a mais para buscar alguém em [via]: ir do trajeto até lá e voltar.
     */
    fun detourMeters(path: List<Location>, via: Location): Int =
        (2 * project(via, path).distanceMeters * ROAD_FACTOR).roundToInt()

    /**
     * Ponto do trajeto [path] mais próximo de [point], com a distância até ele e a fração do
     * comprimento do trajeto até ali. Usa projeção plana local, suficiente para distâncias urbanas.
     */
    fun project(point: Location, path: List<Location>): Projection {
        require(path.isNotEmpty()) { "Trajeto vazio" }
        val metersPerDegreeLat = Math.toRadians(1.0) * EARTH_RADIUS_METERS
        val metersPerDegreeLng = metersPerDegreeLat * cos(Math.toRadians(path.first().latitude))
        fun x(l: Location) = (l.longitude - path.first().longitude) * metersPerDegreeLng
        fun y(l: Location) = (l.latitude - path.first().latitude) * metersPerDegreeLat

        val pointX = x(point)
        val pointY = y(point)
        val start = Location(PICKUP_LABEL, path.first().latitude, path.first().longitude)
        var best = Projection(start, hypot(pointX, pointY), 0.0)
        var bestAlong = 0.0
        var along = 0.0

        for ((from, to) in path.zipWithNext()) {
            val fromX = x(from)
            val fromY = y(from)
            val segmentX = x(to) - fromX
            val segmentY = y(to) - fromY
            val length = hypot(segmentX, segmentY)
            val t = if (length == 0.0) 0.0
            else (((pointX - fromX) * segmentX + (pointY - fromY) * segmentY) / (length * length)).coerceIn(0.0, 1.0)
            val distance = hypot(pointX - fromX - t * segmentX, pointY - fromY - t * segmentY)

            if (distance < best.distanceMeters) {
                val projected = Location(
                    label = PICKUP_LABEL,
                    latitude = from.latitude + t * (to.latitude - from.latitude),
                    longitude = from.longitude + t * (to.longitude - from.longitude)
                )
                best = Projection(projected, distance, 0.0)
                bestAlong = along + t * length
            }
            along += length
        }
        return best.copy(fraction = if (along == 0.0) 0.0 else bestAlong / along)
    }

}
