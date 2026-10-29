package me.rafaelpereira.caronaapp.utils

import me.rafaelpereira.caronaapp.models.Location
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class GeoTests {

    private fun at(lat: Double, lng: Double) = Location("", lat, lng)

    @Test
    fun `polyline decodifica o exemplo da documentação do Google`() {
        val points = Polyline.decode("_p~iF~ps|U_ulLnnqC_mqNvxq`@")
        assertEquals(3, points.size)
        assertEquals(38.5, points[0].latitude, 1e-9)
        assertEquals(-120.2, points[0].longitude, 1e-9)
        assertEquals(43.252, points[2].latitude, 1e-9)
        assertEquals(-126.453, points[2].longitude, 1e-9)
    }

    @Test
    fun `polyline codifica e decodifica de volta`() {
        val path = listOf(at(-20.8113, -49.3758), at(-20.79815, -49.3674), at(-20.785, -49.36))
        val decoded = Polyline.decode(Polyline.encode(path))
        path.zip(decoded).forEach { (a, b) ->
            assertEquals(a.latitude, b.latitude, 1e-9)
            assertEquals(a.longitude, b.longitude, 1e-9)
        }
    }

    @Test
    fun `projeção usa o trecho mais próximo do trajeto em L`() {
        // Trajeto em L: ~1,1 km para o norte e depois ~1 km para o leste
        val path = listOf(at(-20.82, -49.38), at(-20.81, -49.38), at(-20.81, -49.37))
        // Perto do segundo trecho, mas a ~1 km da linha reta entre as pontas
        val point = at(-20.8105, -49.375)

        val onPath = Geo.project(point, path)
        assertTrue(onPath.distanceMeters < 100, "distância até o trajeto: ${onPath.distanceMeters}")
        assertTrue(onPath.fraction > 0.5 && onPath.fraction < 1.0, "fração: ${onPath.fraction}")

        val straight = Geo.project(point, listOf(path.first(), path.last()))
        assertTrue(straight.distanceMeters > 300, "distância até a linha reta: ${straight.distanceMeters}")
    }

}
