package me.rafaelpereira.caronaapp.controllers.dto

import me.rafaelpereira.caronaapp.models.User

/** Dados públicos de outro usuário (motorista ou passageiro). */
data class PersonDto(
    val id: Long,
    val name: String
) {
    companion object {
        fun from(user: User) = PersonDto(user.id!!, user.name)
    }
}
