package me.rafaelpereira.caronaapp.controllers

import jakarta.validation.Valid
import me.rafaelpereira.caronaapp.config.userId
import me.rafaelpereira.caronaapp.controllers.dto.CreateRideRequestDto
import me.rafaelpereira.caronaapp.controllers.dto.RidePassengerDto
import me.rafaelpereira.caronaapp.controllers.dto.RideRequestResponseDto
import me.rafaelpereira.caronaapp.controllers.dto.RideResponseDto
import me.rafaelpereira.caronaapp.controllers.dto.RideSearchResultDto
import me.rafaelpereira.caronaapp.models.Location
import me.rafaelpereira.caronaapp.services.RideRequestService
import me.rafaelpereira.caronaapp.services.RideService
import org.springframework.format.annotation.DateTimeFormat
import org.springframework.http.HttpStatus
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController
import java.time.LocalDate

@RestController
@RequestMapping("/rides")
class RideController(
    private val rideService: RideService,
    private val rideRequestService: RideRequestService
) {

    @GetMapping("/search")
    @PreAuthorize("hasAuthority('ride:search')")
    fun search(
        @AuthenticationPrincipal jwt: Jwt,
        @RequestParam originLat: Double,
        @RequestParam originLng: Double,
        @RequestParam destinationLat: Double,
        @RequestParam destinationLng: Double,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) date: LocalDate?
    ): List<RideSearchResultDto> = rideService.search(
        jwt.userId,
        Location("Origem", originLat, originLng),
        Location("Destino", destinationLat, destinationLng),
        date
    )

    @GetMapping("/driving")
    @PreAuthorize("hasAuthority('route:create')")
    fun driving(@AuthenticationPrincipal jwt: Jwt): List<RideResponseDto> =
        rideService.upcomingAsDriver(jwt.userId)

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('ride:search')")
    fun get(@PathVariable id: Long): RideResponseDto =
        rideService.get(id)

    @GetMapping("/{id}/passengers")
    @PreAuthorize("hasAuthority('ride:search')")
    fun passengers(@AuthenticationPrincipal jwt: Jwt, @PathVariable id: Long): List<RidePassengerDto> =
        rideService.passengers(jwt.userId, id)

    @PostMapping("/{id}/cancel")
    @PreAuthorize("hasAuthority('route:create')")
    fun cancel(@AuthenticationPrincipal jwt: Jwt, @PathVariable id: Long): RideResponseDto =
        rideService.cancel(jwt.userId, id)

    @PostMapping("/{id}/complete")
    @PreAuthorize("hasAuthority('route:create')")
    fun complete(@AuthenticationPrincipal jwt: Jwt, @PathVariable id: Long): RideResponseDto =
        rideService.complete(jwt.userId, id)

    @PostMapping("/{id}/requests")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAuthority('ride:request')")
    fun request(
        @AuthenticationPrincipal jwt: Jwt,
        @PathVariable id: Long,
        @Valid @RequestBody dto: CreateRideRequestDto
    ): RideRequestResponseDto = rideRequestService.create(jwt.userId, id, dto)

}
