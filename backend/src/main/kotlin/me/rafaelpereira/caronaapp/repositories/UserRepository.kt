package me.rafaelpereira.caronaapp.repositories

import me.rafaelpereira.caronaapp.models.User
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface UserRepository : JpaRepository<User, Long> {

    fun findByEmail(email: String): User?

}