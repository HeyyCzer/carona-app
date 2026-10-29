# Carona Universitária

App de caronas entre estudantes: quem já vai de carro para o campus publica sua rota, e quem precisa de carona encontra motoristas que passam perto de casa.

Monorepo com duas partes:

| Pasta | O que é | Tecnologia |
| --- | --- | --- |
| [`backend/`](backend/) | API REST (usuários, rotas, caronas, pedidos de vaga, recebimentos) | Kotlin, Spring Boot, SQLite, JWT |
| [`mobile/`](mobile/) | App Android/iOS | Flutter, GetX |

## Como rodar

### 1. Backend

```bash
cd backend
./gradlew bootRun
```

A API sobe em `http://localhost:8080` e cria o banco `carona.db` na própria pasta.

### 2. App

```bash
cd mobile
flutter pub get
flutter run
```

O app procura o backend em:

- **Emulador Android:** `http://10.0.2.2:8080` (é assim que o emulador enxerga o `localhost` do computador)
- **Simulador iOS:** `http://localhost:8080`
- **Celular físico:** passe o IP do computador na rede local:

  ```bash
  flutter run --dart-define=API_URL=http://192.168.0.10:8080
  ```

- **Backend publicado:** copie `mobile/.env.example` para `mobile/.env`, coloque a URL em `API_URL` e passe o arquivo para o `run` ou o `build`:

  ```bash
  flutter run --dart-define-from-file=.env
  flutter build apk --dart-define-from-file=.env
  flutter build ipa --dart-define-from-file=.env
  ```

  No VS Code, a configuração **mobile (.env)** do `launch.json` já faz isso.

Para testar sozinho, crie duas contas: uma publica uma rota em **Dirigir › Nova rota** e a outra busca a carona em **Buscar**.

## Organização do app (`mobile/lib`)

```
lib/
├── main.dart          # inicializa os services e o GetMaterialApp
├── config.dart        # URL da API
├── theme.dart         # cores e tipografia do protótipo
├── api/               # cliente HTTP, endpoints e modelos (espelham os DTOs do backend)
├── app/routes.dart    # rotas nomeadas (GetPage) e seus bindings
├── services/          # estado global (GetxService): sessão, locais salvos, mensagens
├── modules/           # uma pasta por funcionalidade, cada tela com controller + view
│   ├── auth/          # login e cadastro
│   ├── home/          # navegação inferior e perfil
│   ├── passenger/     # buscar, detalhe da carona, minhas caronas, meus pedidos
│   ├── driver/        # painel do motorista, nova rota, minhas rotas, saídas, recebimentos
│   ├── messages/      # conversas e chat
│   └── places/        # escolha de endereço (busca ou mapa) e mapa do ponto de embarque
├── ui/                # componentes visuais reutilizáveis, um por arquivo (ui.dart exporta todos)
└── utils/format.dart  # formatação de dinheiro, datas, distâncias
```

Cada tela segue o padrão do GetX: o `*_controller.dart` guarda o estado (`.obs`) e fala com a API; o `*_view.dart` só desenha, reagindo com `Obx`. As dependências são registradas nos bindings de `app/routes.dart`.

Mapas e busca de endereços usam o OpenStreetMap (tiles e Nominatim), que não precisam de chave de API.

## O que ainda depende do backend

O protótipo tem algumas partes que o backend ainda não oferece:

- **Mensagens:** não há endpoints de chat. As conversas funcionam, mas ficam salvas só no aparelho de quem escreveu (o app avisa isso na tela). A troca para a API fica concentrada em `services/messages_service.dart`.
- **Verificação de e-mail** e **recuperação de senha:** não há endpoints, então essas telas não foram incluídas. O cadastro entra direto no app.
- **Avaliação e veículo do motorista** (ex.: "4,9 · Ford Ka"): não existem no modelo de dados e não aparecem no app.
- **Concluir viagens:** o backend só lista caronas que ainda não saíram, mas só deixa concluir depois da saída. O app guarda os ids das caronas do motorista para mostrar as que já saíram em **Minhas saídas**, onde ele as marca como concluídas e elas passam a contar nos recebimentos.
