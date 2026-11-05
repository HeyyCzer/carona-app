package me.rafaelpereira.caronaapp.controllers.dto

import me.rafaelpereira.caronaapp.models.User

/** Dados públicos de outro usuário (motorista ou passageiro). */
data class PersonDto(
    val id: Long,
    val name: String,
    /** Caminho da foto na API (`/users/{id}/avatar?v=...`), ou nulo se a pessoa não tem foto. */
    val avatarUrl: String?
) {
    companion object {
        fun from(user: User) = PersonDto(user.id!!, user.name, avatarUrl(user))

        /** O `v` muda a cada foto nova, para o app não mostrar a antiga do cache. */
        fun avatarUrl(user: User): String? =
            user.avatarUpdatedAt?.let { "/users/${user.id}/avatar?v=${it.toEpochMilli()}" }
    }
}
