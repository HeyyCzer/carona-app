package me.rafaelpereira.caronaapp.repositories

import me.rafaelpereira.caronaapp.models.Route
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface RouteRepository : JpaRepository<Route, Long> {

    fun findByDriverIdAndActiveTrueOrderByCreatedAtDesc(driverId: Long): List<Route>

    fun findByActiveTrue(): List<Route>

}
