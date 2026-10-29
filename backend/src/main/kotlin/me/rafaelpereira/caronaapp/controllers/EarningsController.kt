package me.rafaelpereira.caronaapp.controllers

import me.rafaelpereira.caronaapp.config.userId
import me.rafaelpereira.caronaapp.controllers.dto.EarningsResponseDto
import me.rafaelpereira.caronaapp.services.EarningsService
import org.springframework.format.annotation.DateTimeFormat
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import java.time.LocalDate

@RestController
@RequestMapping("/earnings")
class EarningsController(
    private val earningsService: EarningsService
) {

    /** Sem datas, retorna a semana atual (segunda a domingo). */
    @GetMapping
    @PreAuthorize("hasAuthority('earnings:read')")
    fun get(
        @AuthenticationPrincipal jwt: Jwt,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) from: LocalDate?,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) to: LocalDate?
    ): EarningsResponseDto = earningsService.get(jwt.userId, from, to)

}
