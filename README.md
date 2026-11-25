# TermiAPILabs — Frontend

<p align="center">
  <img src="assets/termiapislabs-logo.jpeg" alt="Logo oficial do TermiAPILabs" width="260">
</p>

O **TermiAPILabs** é uma plataforma open-source para centralizar, documentar e testar APIs. Este repositório contém o frontend em **Flutter Web**, responsável pela interface e pelas chamadas HTTP/JSON ao backend Java Spring Boot mantido em outro repositório.

## Fases do produto

- **BETA 1 — autenticação e usuário:** cadastro convencional, confirmação de e-mail, login, Google Identity Services, recuperação e redefinição de senha e logout no cliente.
- **BETA 2 — próximas evoluções:** analytics e sandbox não fazem parte da implementação atual deste repositório.

## Arquitetura

O frontend atua exclusivamente como cliente HTTP/UI:

- apresenta formulários e estados de operação;
- valida dados antes do envio;
- envia e recebe JSON pelo Dio;
- mantém estado de autenticação com `provider` e `ChangeNotifier`;
- persiste a sessão web com `flutter_secure_storage`;
- delega ao backend Java Spring Boot as regras de negócio, persistência PostgreSQL e segurança.

A organização segue uma separação por features:

```text
lib/
├── core/
│   ├── config/
│   ├── network/
│   ├── storage/
│   ├── theme/
│   └── widgets/
└── features/
    └── auth/
        ├── data/
        │   ├── dto/
        │   ├── models/
        │   └── repositories/
        ├── domain/
        │   └── entities/
        └── presentation/
            ├── controllers/
            ├── pages/
            └── widgets/
```

Os principais pontos são:

- `lib/core/config/app_config.dart`: configuração pública por `--dart-define`;
- `lib/core/network/api_client.dart`: cliente Dio, headers, timeouts e erros HTTP;
- `lib/core/storage/session_storage.dart`: token e usuário persistidos no armazenamento web protegido disponível pelo plugin;
- `lib/features/auth/data/repositories/auth_repository.dart`: chamadas aos endpoints `/api/auth`;
- `lib/features/auth/presentation/controllers/auth_controller.dart`: estado de autenticação e sessão;
- `lib/features/auth/presentation/pages/auth_pages.dart`: telas e formulários de autenticação;
- `lib/app.dart`: tema, rotas e redirecionamentos.

## Identidade visual

A interface usa uma estética **neo-brutalista técnica**:

- paleta monocromática preta, branca e cinza;
- vermelho moderado para erros;
- verde ou azul escuro discreto para sucesso;
- amarelo apenas para alertas;
- bordas sólidas de 2 px;
- sombras geométricas sólidas;
- cantos pequenos ou quadrados;
- tipografia técnica legível em campos e dados.

A logo oficial é uma composição geométrica em alto contraste. Ela apresenta um símbolo de terminal representado por uma seta ou prompt angular à esquerda, um bloco técnico com outro prompt à direita e uma barra inferior, sobre fundo branco, dentro de uma moldura preta quadrada. Esses elementos dialogam com a estética de terminal, APIs e interfaces técnicas utilizada pelo frontend.

## Dependências reais

As dependências relevantes já declaradas em `pubspec.yaml` incluem:

- `dio` para comunicação HTTP;
- `flutter_secure_storage` para persistência web da sessão;
- `go_router` para navegação;
- `provider` para estado;
- `google_sign_in` e `google_sign_in_web` para Google Identity Services;
- `flutter_test` para testes.

## Configuração de ambiente

A URL da API e o Google Client ID são fornecidos em tempo de compilação:

```dart
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);

const googleClientId = String.fromEnvironment(
  'GOOGLE_CLIENT_ID',
  defaultValue: '',
);
```

Valores públicos de exemplo estão em `dart_defines.example.json`.

## Executar localmente

Use a origem `http://localhost:5000` no navegador e configure essa origem no backend/CORS:

```bash
flutter pub get
flutter run -d web-server \
  --web-port=5000 \
  --dart-define=API_BASE_URL=http://localhost:8080 \
  --dart-define=GOOGLE_CLIENT_ID=SEU_GOOGLE_CLIENT_ID.apps.googleusercontent.com
```

Abra:

```text
http://localhost:5000
```

Não use `127.0.0.1:5000` quando o backend estiver configurado para aceitar `localhost:5000`.

## Build Web e Firebase Hosting

Gerar arquivos estáticos:

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.seudominio.com \
  --dart-define=GOOGLE_CLIENT_ID=SEU_GOOGLE_CLIENT_ID.apps.googleusercontent.com
```

Os arquivos são publicados em `build/web`. O projeto já possui `firebase.json` configurado com essa pasta pública e rewrite para `index.html`.

Implantação após autenticação no Firebase CLI:

```bash
firebase login
firebase use SEU_PROJECT_ID
firebase deploy --only hosting
```

O frontend não usa Docker. O backend pode ser executado em Docker separadamente e concentra banco de dados, SMTP, regras de negócio e emissão/validação dos JWT.

## Testes e qualidade

```bash
flutter analyze
flutter test
flutter build web --release
```

## Segurança

- Não inclua Client Secret, JWT Secret, credenciais SMTP, senhas de banco ou outros secrets no Flutter.
- Google Client ID é uma configuração pública.
- Não registre JWT, ID Credential, `access_token`, senhas ou códigos em logs.
- Não coloque tokens em URLs.
- A resposta de recuperação não deve ser interpretada como confirmação de que o código foi enviado.
- O logout remove token, usuário e dados temporários do cliente; não invalida retroativamente o JWT no backend.

## Pontos que merecem conferência manual

- Configuração real de CORS do backend para a origem efetiva do navegador.
- Mesmo Google Client ID no frontend e no backend.
- Configuração SMTP do backend para contas locais.
- Contas Google não recebem código de redefinição por este fluxo.
- Integração do Google deve enviar o ID Token no campo `credential`, nunca o `access_token`.
- A implementação atual não possui refresh token, revogação de JWT, perfil com edição ou endpoints protegidos além dos fluxos presentes.

## Contribuição

1. Crie uma branch a partir da branch principal.
2. Preserve a organização por features.
3. Mantenha chamadas HTTP fora dos widgets, em serviços/repositórios.
4. Não adicione endpoints ou campos que não existam no backend real.
5. Execute `flutter analyze`, `flutter test` e o build Web antes de abrir um pull request.
6. Não faça commit de `.env`, secrets, `build/`, `.dart_tool/` ou arquivos locais de IDE.
