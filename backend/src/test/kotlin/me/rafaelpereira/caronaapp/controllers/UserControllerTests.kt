package me.rafaelpereira.caronaapp.controllers

import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc
import org.springframework.http.MediaType
import org.springframework.test.context.TestPropertySource
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.post
import tools.jackson.databind.ObjectMapper

@SpringBootTest
@AutoConfigureMockMvc
@TestPropertySource(properties = ["spring.datasource.url=jdbc:sqlite:file:test?mode=memory&cache=shared"])
class UserControllerTests {

    @Autowired
    lateinit var mockMvc: MockMvc

    @Autowired
    lateinit var objectMapper: ObjectMapper

    private fun register(email: String) = mockMvc.post("/register") {
        contentType = MediaType.APPLICATION_JSON
        content = """{"name":"Cauanny","email":"$email","password":"senha12345"}"""
    }

    @Test
    fun `cadastro retorna token com papel USER`() {
        register("novo@test.com").andExpect {
            status { isCreated() }
            jsonPath("$.accessToken") { isNotEmpty() }
            jsonPath("$.user.roles[0]") { value("USER") }
        }
    }

    @Test
    fun `cadastro com email repetido retorna 409`() {
        register("repetido@test.com")
        register("repetido@test.com").andExpect { status { isConflict() } }
    }

    @Test
    fun `cadastro com dados invalidos retorna 400`() {
        mockMvc.post("/register") {
            contentType = MediaType.APPLICATION_JSON
            content = """{"name":"","email":"nao-e-email","password":"123"}"""
        }.andExpect { status { isBadRequest() } }
    }

    @Test
    fun `login com token acessa me`() {
        register("login@test.com")

        val body = mockMvc.post("/login") {
            contentType = MediaType.APPLICATION_JSON
            content = """{"email":"LOGIN@test.com","password":"senha12345"}"""
        }.andExpect { status { isOk() } }.andReturn().response.contentAsString
        val token = objectMapper.readTree(body)["accessToken"].asString()

        mockMvc.get("/me") { header("Authorization", "Bearer $token") }.andExpect {
            status { isOk() }
            jsonPath("$.email") { value("login@test.com") }
            jsonPath("$.permissions.length()") { value(6) }
        }
    }

    @Test
    fun `login com senha errada retorna 401`() {
        register("errada@test.com")
        mockMvc.post("/login") {
            contentType = MediaType.APPLICATION_JSON
            content = """{"email":"errada@test.com","password":"outrasenha"}"""
        }.andExpect { status { isUnauthorized() } }
    }

    @Test
    fun `me sem token retorna 401`() {
        mockMvc.get("/me").andExpect { status { isUnauthorized() } }
    }

}
