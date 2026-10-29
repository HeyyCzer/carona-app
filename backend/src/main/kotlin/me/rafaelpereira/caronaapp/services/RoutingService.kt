package me.rafaelpereira.caronaapp.services

import me.rafaelpereira.caronaapp.models.Location
import me.rafaelpereira.caronaapp.models.RoadPath
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.http.client.SimpleClientHttpRequestFactory
import org.springframework.stereotype.Service
import org.springframework.web.client.RestClient
import tools.jackson.databind.ObjectMapper
import java.time.Duration
import kotlin.math.roundToInt

/**
 * Trajeto pelas ruas via OSRM (OpenStreetMap). O servidor público é gratuito e não precisa de chave,
 * mas não tem garantia de disponibilidade: se falhar, quem chama usa a linha reta.
 */
@Service
class RoutingService(
    @Value("\${app.routing.osrm-url:}") private val baseUrl: String,
    private val objectMapper: ObjectMapper
) {

    private val log = LoggerFactory.getLogger(javaClass)

    private val client = RestClient.builder()
        .baseUrl(baseUrl)
        .requestFactory(SimpleClientHttpRequestFactory().apply {
            setConnectTimeout(Duration.ofSeconds(3))
            setReadTimeout(Duration.ofSeconds(8))
        })
        .defaultHeader("User-Agent", "carona-app-backend")
        .build()

    fun route(from: Location, to: Location): RoadPath? {
        if (baseUrl.isBlank()) return null
        val coordinates = "${from.longitude},${from.latitude};${to.longitude},${to.latitude}"
        return try {
            val body = client.get()
                .uri("/route/v1/driving/$coordinates?overview=full&geometries=polyline")
                .retrieve()
                .body(String::class.java)
            val json = objectMapper.readTree(body)
            val route = json["routes"]?.get(0)
            if (json["code"]?.asString() != "Ok" || route == null) {
                log.warn("OSRM não encontrou trajeto de {} até {}: {}", from.label, to.label, json["code"])
                return null
            }
            RoadPath(
                polyline = route["geometry"].asString(),
                distanceMeters = route["distance"].asDouble().roundToInt(),
                durationSeconds = route["duration"].asDouble().roundToInt()
            )
        } catch (e: Exception) {
            log.warn("Falha ao consultar o OSRM, usando linha reta: {}", e.message)
            null
        }
    }

}
