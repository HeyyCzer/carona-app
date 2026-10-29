package me.rafaelpereira.caronaapp.controllers

import jakarta.validation.Valid
import me.rafaelpereira.caronaapp.config.userId
import me.rafaelpereira.caronaapp.controllers.dto.CreateRouteDto
import me.rafaelpereira.caronaapp.controllers.dto.RoutePreviewDto
import me.rafaelpereira.caronaapp.controllers.dto.RouteResponseDto
import me.rafaelpereira.caronaapp.models.Location
import me.rafaelpereira.caronaapp.services.RouteService
import org.springframework.http.HttpStatus
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/routes")
@PreAuthorize("hasAuthority('route:create')")
class RouteController(
    private val routeService: RouteService
) {

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    fun create(@AuthenticationPrincipal jwt: Jwt, @Valid @RequestBody dto: CreateRouteDto): RouteResponseDto =
        routeService.create(jwt.userId, dto)

    @GetMapping("/preview")
    fun preview(
        @RequestParam originLat: Double,
        @RequestParam originLng: Double,
        @RequestParam destinationLat: Double,
        @RequestParam destinationLng: Double
    ): RoutePreviewDto = routeService.preview(
        Location("Origem", originLat, originLng),
        Location("Destino", destinationLat, destinationLng)
    )

    @GetMapping("/mine")
    fun mine(@AuthenticationPrincipal jwt: Jwt): List<RouteResponseDto> =
        routeService.mine(jwt.userId)

    @GetMapping("/{id}")
    fun get(@AuthenticationPrincipal jwt: Jwt, @PathVariable id: Long): RouteResponseDto =
        routeService.get(jwt.userId, id)

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun deactivate(@AuthenticationPrincipal jwt: Jwt, @PathVariable id: Long) =
        routeService.deactivate(jwt.userId, id)

}
