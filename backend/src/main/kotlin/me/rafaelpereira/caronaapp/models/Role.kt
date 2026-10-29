package me.rafaelpereira.caronaapp.models

enum class Role(val permissions: Set<Permission>) {
    // Qualquer usuário pode tanto buscar quanto oferecer carona
    USER(
        setOf(
            Permission.RIDE_SEARCH,
            Permission.RIDE_REQUEST,
            Permission.ROUTE_CREATE,
            Permission.RIDE_REQUEST_MANAGE,
            Permission.EARNINGS_READ,
            Permission.MESSAGE_SEND
        )
    ),
    ADMIN(USER.permissions + Permission.USER_MANAGE);

    val authority: String get() = "ROLE_$name"
}
