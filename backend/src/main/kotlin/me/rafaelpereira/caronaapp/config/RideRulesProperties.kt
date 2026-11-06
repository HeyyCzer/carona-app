package me.rafaelpereira.caronaapp.config

import org.springframework.boot.context.properties.ConfigurationProperties
import java.time.Duration

/** Prazos de confirmação de presença, embarque e rastreamento, contados a partir da saída da carona. */
@ConfigurationProperties("app.rides")
data class RideRulesProperties(
    /** Quanto tempo antes da saída o passageiro já pode (e precisa) confirmar que vai. */
    val confirmationOpensBefore: Duration = Duration.ofHours(3),
    /** Até quanto tempo antes da saída a confirmação é aceita; depois disso a vaga é liberada. */
    val confirmationDeadlineBefore: Duration = Duration.ofMinutes(30),
    /** Quanto tempo antes da saída o motorista pode começar a compartilhar a posição e registrar embarques. */
    val trackingStartsBefore: Duration = Duration.ofMinutes(30),
    /** Por quanto tempo depois da saída a viagem ainda é considerada em andamento. */
    val trackingMaxDuration: Duration = Duration.ofHours(6)
)
