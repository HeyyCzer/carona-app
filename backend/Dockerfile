# Etapa 1: compila o jar com o Gradle wrapper do projeto
FROM eclipse-temurin:25-jdk AS build
WORKDIR /app

# Baixa o Gradle e as dependências antes de copiar o código, para aproveitar o cache
COPY gradlew settings.gradle.kts build.gradle.kts ./
COPY gradle gradle
RUN ./gradlew dependencies --no-daemon > /dev/null

COPY src src
RUN ./gradlew bootJar --no-daemon -x test \
    && find build/libs -name '*.jar' ! -name '*-plain.jar' -exec cp {} app.jar \;

# Etapa 2: só o JRE e o jar
FROM eclipse-temurin:25-jre
WORKDIR /app

RUN useradd --system --uid 1001 carona \
    && mkdir /data && chown carona /data
USER carona

COPY --from=build /app/app.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
