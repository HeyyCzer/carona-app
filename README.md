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

A API sobe em `http://localhost:8080` e cria o banco `carona.db` e a pasta de fotos `avatars/` na própria pasta.

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
├── services/          # estado global (GetxService): sessão, locais salvos, mensagens, foto de perfil, rastreamento
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

## Dia da viagem

1. **Confirmação de presença:** 3 h antes da saída o passageiro precisa dizer se vai ("Vou" / "Não vou"), até 30 min antes. Quem não confirma perde a vaga, que volta para a busca.
2. **Código de embarque:** ao confirmar, o passageiro recebe um código de 4 dígitos. O motorista digita esse código em **Confirmar embarque** quando ele entra no carro.
3. **Acompanhamento em tempo real:** de 30 min antes da saída até o fim da viagem, o motorista pode ligar **Compartilhar localização** no detalhe da viagem. Os passageiros confirmados veem o carro andando no mapa (WebSocket `/ws/tracking`).
4. **Conclusão:** só quem embarcou aparece como viagem concluída e entra nos recebimentos. Quem não foi buscado aparece como "Não embarcou"; quem cancelou ou não confirmou, como "Cancelada" ou "Não confirmada".

Os prazos ficam em `app.rides.*` no `application.properties`.

## Fotos de perfil

Cada usuário pode tirar uma foto com a câmera (ou escolher da galeria) tocando no avatar do perfil. O backend guarda a foto na pasta `app.avatars.dir` (padrão `avatars/`, no Docker `/data/avatars`) com o id do usuário como nome: `avatars/42.jpg`. Os DTOs de pessoas trazem `avatarUrl` (`/users/42/avatar?v=...`), que muda a cada foto nova.

## O que ainda depende do backend

O protótipo tem algumas partes que o backend ainda não oferece:

- **Mensagens:** não há endpoints de chat. As conversas funcionam, mas ficam salvas só no aparelho de quem escreveu (o app avisa isso na tela). A troca para a API fica concentrada em `services/messages_service.dart`.
- **Verificação de e-mail** e **recuperação de senha:** não há endpoints, então essas telas não foram incluídas. O cadastro entra direto no app.
- **Avaliação e veículo do motorista** (ex.: "4,9 · Ford Ka"): não existem no modelo de dados e não aparecem no app.
- **Localização em segundo plano:** a posição do motorista só é enviada com o detalhe da viagem aberto. Para continuar com o app em segundo plano seria preciso um serviço em primeiro plano no Android e o modo de localização em background no iOS.
- **Lembretes de confirmação:** não há notificações push; o passageiro vê o pedido de confirmação ao abrir **Minhas caronas**.
