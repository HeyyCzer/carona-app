package me.rafaelpereira.caronaapp.controllers.dto

data class AuthResponseDto(
    val accessToken: String,
    val tokenType: String = "Bearer",
    val expiresIn: Long,
    val user: UserResponseDto
)
