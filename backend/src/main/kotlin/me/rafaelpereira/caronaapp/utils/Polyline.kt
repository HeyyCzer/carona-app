package me.rafaelpereira.caronaapp.utils

import me.rafaelpereira.caronaapp.models.Location
import kotlin.math.roundToLong

/**
 * Formato "encoded polyline" do Google (precisão de 5 casas), o mesmo que o OSRM devolve.
 * Guarda um trajeto com centenas de pontos numa string curta.
 */
object Polyline {

    private const val FACTOR = 1e5

    fun encode(points: List<Location>): String {
        val result = StringBuilder()
        var previousLat = 0L
        var previousLng = 0L
        for (point in points) {
            val lat = (point.latitude * FACTOR).roundToLong()
            val lng = (point.longitude * FACTOR).roundToLong()
            encodeValue(lat - previousLat, result)
            encodeValue(lng - previousLng, result)
            previousLat = lat
            previousLng = lng
        }
        return result.toString()
    }

    fun decode(encoded: String): List<Location> {
        val points = mutableListOf<Location>()
        var index = 0
        var lat = 0L
        var lng = 0L
        while (index < encoded.length) {
            val (dLat, afterLat) = decodeValue(encoded, index)
            val (dLng, afterLng) = decodeValue(encoded, afterLat)
            index = afterLng
            lat += dLat
            lng += dLng
            points += Location(label = "", latitude = lat / FACTOR, longitude = lng / FACTOR)
        }
        return points
    }

    private fun encodeValue(value: Long, out: StringBuilder) {
        var v = if (value < 0) (value shl 1).inv() else value shl 1
        while (v >= 0x20) {
            out.append(((0x20 or (v and 0x1f).toInt()) + 63).toChar())
            v = v shr 5
        }
        out.append((v + 63).toInt().toChar())
    }

    private fun decodeValue(encoded: String, start: Int): Pair<Long, Int> {
        var index = start
        var shift = 0
        var result = 0L
        var chunk: Int
        do {
            chunk = encoded[index++].code - 63
            result = result or ((chunk and 0x1f).toLong() shl shift)
            shift += 5
        } while (chunk >= 0x20)
        val value = if (result and 1L != 0L) (result shr 1).inv() else result shr 1
        return value to index
    }

}
