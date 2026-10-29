package me.rafaelpereira.caronaapp.controllers.dto

import jakarta.validation.constraints.DecimalMax
import jakarta.validation.constraints.DecimalMin
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size
import me.rafaelpereira.caronaapp.models.Location

data class LocationDto(
    @field:NotBlank @field:Size(max = 120)
    val label: String,
    @field:DecimalMin("-90") @field:DecimalMax("90")
    val latitude: Double,
    @field:DecimalMin("-180") @field:DecimalMax("180")
    val longitude: Double
) {
    fun toModel() = Location(label.trim(), latitude, longitude)

    companion object {
        fun from(location: Location) = LocationDto(location.label, location.latitude, location.longitude)
    }
}
