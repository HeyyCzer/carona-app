package me.rafaelpereira.caronaapp.models

enum class Permission(val authority: String) {
    RIDE_SEARCH("ride:search"),
    RIDE_REQUEST("ride:request"),
    ROUTE_CREATE("route:create"),
    RIDE_REQUEST_MANAGE("ride-request:manage"),
    EARNINGS_READ("earnings:read"),
    MESSAGE_SEND("message:send"),
    USER_MANAGE("user:manage")
}
