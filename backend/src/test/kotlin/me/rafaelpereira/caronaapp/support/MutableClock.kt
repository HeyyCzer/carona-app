package me.rafaelpereira.caronaapp.support

import java.time.Clock
import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneId

/** Relógio que o teste pode adiantar, para simular as horas antes e depois da saída. */
class MutableClock(private var instant: Instant, private val zone: ZoneId) : Clock() {

    fun set(dateTime: LocalDateTime) {
        instant = dateTime.atZone(zone).toInstant()
    }

    override fun getZone(): ZoneId = zone

    override fun withZone(zone: ZoneId): Clock = MutableClock(instant, zone)

    override fun instant(): Instant = instant

}
