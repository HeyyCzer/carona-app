package me.rafaelpereira.caronaapp.controllers

import me.rafaelpereira.caronaapp.config.userId
import me.rafaelpereira.caronaapp.controllers.dto.BookingResponseDto
import me.rafaelpereira.caronaapp.services.BookingService
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/bookings")
@PreAuthorize("hasAuthority('ride:request')")
class BookingController(
    private val bookingService: BookingService
) {

    @GetMapping("/mine")
    fun mine(@AuthenticationPrincipal jwt: Jwt): List<BookingResponseDto> =
        bookingService.mine(jwt.userId)

    @PostMapping("/{id}/cancel")
    fun cancel(@AuthenticationPrincipal jwt: Jwt, @PathVariable id: Long): BookingResponseDto =
        bookingService.cancel(jwt.userId, id)

}
