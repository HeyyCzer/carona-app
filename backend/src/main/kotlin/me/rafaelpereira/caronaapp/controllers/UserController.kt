package me.rafaelpereira.caronaapp.controllers

import jakarta.validation.Valid
import me.rafaelpereira.caronaapp.config.userId
import me.rafaelpereira.caronaapp.controllers.dto.AuthResponseDto
import me.rafaelpereira.caronaapp.controllers.dto.UserLoginDto
import me.rafaelpereira.caronaapp.controllers.dto.UserRegisterDto
import me.rafaelpereira.caronaapp.controllers.dto.UserResponseDto
import me.rafaelpereira.caronaapp.services.UserService
import org.springframework.http.HttpStatus
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping
class UserController(
    private val userService: UserService
) {

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    fun register(@Valid @RequestBody userDto: UserRegisterDto): AuthResponseDto =
        userService.register(userDto)

    @PostMapping("/login")
    fun login(@Valid @RequestBody userDto: UserLoginDto): AuthResponseDto =
        userService.login(userDto)

    @GetMapping("/me")
    fun me(@AuthenticationPrincipal jwt: Jwt): UserResponseDto =
        userService.findById(jwt.userId)

}
