package me.rafaelpereira.caronaapp.services

import me.rafaelpereira.caronaapp.controllers.dto.AuthResponseDto
import me.rafaelpereira.caronaapp.controllers.dto.UserLoginDto
import me.rafaelpereira.caronaapp.controllers.dto.UserRegisterDto
import me.rafaelpereira.caronaapp.controllers.dto.UserResponseDto
import me.rafaelpereira.caronaapp.models.User
import me.rafaelpereira.caronaapp.repositories.UserRepository
import org.springframework.data.repository.findByIdOrNull
import org.springframework.http.HttpStatus
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.server.ResponseStatusException

@Service
class UserService(
    private val userRepository: UserRepository,
    private val passwordEncoder: PasswordEncoder,
    private val tokenService: TokenService
) {

    @Transactional
    fun register(dto: UserRegisterDto): AuthResponseDto {
        val email = normalizeEmail(dto.email)
        if (userRepository.findByEmail(email) != null) {
            throw ResponseStatusException(HttpStatus.CONFLICT, "E-mail já cadastrado")
        }

        val user = userRepository.save(
            User(
                name = dto.name.trim(),
                email = email,
                password = passwordEncoder.encode(dto.password)!!
            )
        )
        return authResponse(user)
    }

    fun login(dto: UserLoginDto): AuthResponseDto {
        val user = userRepository.findByEmail(normalizeEmail(dto.email))
        if (user == null || !passwordEncoder.matches(dto.password, user.password)) {
            throw ResponseStatusException(HttpStatus.UNAUTHORIZED, "E-mail ou senha inválidos")
        }
        return authResponse(user)
    }

    fun findById(id: Long): UserResponseDto {
        val user = userRepository.findByIdOrNull(id)
            ?: throw ResponseStatusException(HttpStatus.NOT_FOUND, "Usuário não encontrado")
        return UserResponseDto.from(user)
    }

    private fun authResponse(user: User) = AuthResponseDto(
        accessToken = tokenService.generate(user),
        expiresIn = tokenService.expiresInSeconds,
        user = UserResponseDto.from(user)
    )

    private fun normalizeEmail(email: String) = email.trim().lowercase()

}
