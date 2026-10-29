package me.rafaelpereira.caronaapp.config

import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.scheduling.annotation.EnableScheduling
import java.time.Clock
import java.time.ZoneId

@Configuration
@EnableScheduling
class TimeConfig {

    // Datas e horários das caronas são locais (sem fuso), então "hoje" e "agora" precisam de um fuso fixo
    @Bean
    fun clock(@Value("\${app.timezone}") timezone: String): Clock = Clock.system(ZoneId.of(timezone))

}
