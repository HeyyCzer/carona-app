package me.rafaelpereira.caronaapp.controllers.dto

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size

data class UserLoginDto(
    @field:NotBlank
    val email: String,
    @field:NotBlank
    @field:Size(max = 72)
    val password: String
)
