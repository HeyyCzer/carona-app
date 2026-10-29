package me.rafaelpereira.caronaapp.config

import org.springframework.security.oauth2.jwt.Jwt

val Jwt.userId: Long
    get() = subject!!.toLong()
