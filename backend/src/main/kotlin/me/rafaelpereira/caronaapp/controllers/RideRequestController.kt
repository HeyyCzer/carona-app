package me.rafaelpereira.caronaapp.controllers

import me.rafaelpereira.caronaapp.config.userId
import me.rafaelpereira.caronaapp.controllers.dto.RideRequestResponseDto
import me.rafaelpereira.caronaapp.models.RideRequestStatus
import me.rafaelpereira.caronaapp.services.RideRequestService
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/ride-requests")
class RideRequestController(
    private val rideRequestService: RideRequestService
) {

    @GetMapping("/received")
    @PreAuthorize("hasAuthority('ride-request:manage')")
    fun received(
        @AuthenticationPrincipal jwt: Jwt,
        @RequestParam(required = false) status: RideRequestStatus?
    ): List<RideRequestResponseDto> = rideRequestService.received(jwt.userId, status)

    @GetMapping("/mine")
    @PreAuthorize("hasAuthority('ride:request')")
    fun mine(@AuthenticationPrincipal jwt: Jwt): List<RideRequestResponseDto> =
        rideRequestService.mine(jwt.userId)

    @PostMapping("/{id}/accept")
    @PreAuthorize("hasAuthority('ride-request:manage')")
    fun accept(@AuthenticationPrincipal jwt: Jwt, @PathVariable id: Long): RideRequestResponseDto =
        rideRequestService.accept(jwt.userId, id)

    @PostMapping("/{id}/reject")
    @PreAuthorize("hasAuthority('ride-request:manage')")
    fun reject(@AuthenticationPrincipal jwt: Jwt, @PathVariable id: Long): RideRequestResponseDto =
        rideRequestService.reject(jwt.userId, id)

    @PostMapping("/{id}/cancel")
    @PreAuthorize("hasAuthority('ride:request')")
    fun cancel(@AuthenticationPrincipal jwt: Jwt, @PathVariable id: Long): RideRequestResponseDto =
        rideRequestService.cancel(jwt.userId, id)

}
