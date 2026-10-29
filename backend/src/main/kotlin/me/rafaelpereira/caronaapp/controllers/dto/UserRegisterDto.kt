package me.rafaelpereira.caronaapp.controllers.dto

import jakarta.validation.constraints.Email
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size

data class UserRegisterDto(
    @field:NotBlank
    @field:Size(min = 2, max = 50)
    val name: String,
    @field:NotBlank @field:Email
    val email: String,
    @field:Size(min = 8, max = 72)
    val password: String
)
