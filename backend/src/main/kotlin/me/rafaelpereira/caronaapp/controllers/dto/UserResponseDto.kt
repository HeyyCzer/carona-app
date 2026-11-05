package me.rafaelpereira.caronaapp.controllers.dto

import me.rafaelpereira.caronaapp.models.User

data class UserResponseDto(
    val id: Long,
    val name: String,
    val email: String,
    val avatarUrl: String?,
    val roles: Set<String>,
    val permissions: Set<String>
) {
    companion object {
        fun from(user: User) = UserResponseDto(
            id = user.id!!,
            name = user.name,
            email = user.email,
            avatarUrl = PersonDto.avatarUrl(user),
            roles = user.roles.map { it.name }.toSet(),
            permissions = user.permissions.map { it.authority }.toSet()
        )
    }
}
