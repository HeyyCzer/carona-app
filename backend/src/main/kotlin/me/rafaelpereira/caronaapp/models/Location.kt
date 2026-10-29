package me.rafaelpereira.caronaapp.models

import jakarta.persistence.Embeddable

@Embeddable
class Location(
    var label: String,
    var latitude: Double,
    var longitude: Double
)
