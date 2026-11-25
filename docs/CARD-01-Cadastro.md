# [BETA-1][CARD-01] — Cadastro, autenticação e gerenciamento de usuário

## Objetivo

Documentar a implementação existente no frontend Flutter Web para cadastro convencional e demais fluxos de autenticação conectados ao backend Java Spring Boot por HTTP/JSON.

## Estado da implementação

O frontend implementa a interface e o estado local dos seguintes fluxos:

- cadastro convencional;
- confirmação de e-mail por código;
- reenvio de código de confirmação;
- login convencional;
- login Google por Google Identity Services;
- solicitação de recuperação de senha;
- redefinição de senha;
- logout local com chamada opcional ao endpoint público;
- persistência web de token e usuário;
- detecção visual de expiração a partir das claims do JWT;
- estados de carregamento, erro, frio da API, cooldown e sessão autenticada/não autenticada.

As telas de perfil completo, revogação de sessão, refresh token e alteração de senha autenticada não estão implementadas porque não existem endpoints correspondentes no backend descrito.

## Estrutura relacionada

### Configuração

- `lib/core/config/app_config.dart`
  - lê `API_BASE_URL` via `String.fromEnvironment`;
  - lê `GOOGLE_CLIENT_ID` via `String.fromEnvironment`;
  - não contém secrets administrativos.

### Rede

- `lib/core/network/api_client.dart`
  - usa Dio;
  - aplica `http://localhost:8080` como valor local padrão da API;
  - envia `Content-Type: application/json` e `Accept: application/json`;
  - pode anexar `Authorization: Bearer <accessToken>` em clientes configurados com bearer token;
  - interpreta timeout, falha de conexão e respostas HTTP;
  - transforma erros em `ApiError`, incluindo status, mensagem principal e `fieldErrors`.

### Storage

- `lib/core/storage/session_storage.dart`
  - persiste `termiapislabs_access_token` e `termiapislabs_user` usando `flutter_secure_storage`;
  - limpa ambos no logout ou quando não encontra uma sessão utilizável;
  - não persiste senha, confirmação de senha ou código de e-mail.

### Data

- `lib/features/auth/data/repositories/auth_repository.dart`
  - concentra todos os métodos HTTP da feature;
  - mapeia a resposta JSON em modelos do frontend;
  - não compartilha entidades JPA ou classes Java.

- `lib/features/auth/data/models/auth_response.dart`
  - representa `accessToken`, `tokenType` e `user`.

- `lib/features/auth/domain/entities/user.dart`
  - representa `AuthUser` com os campos da resposta de usuário da API.

- `lib/features/auth/data/dto/api_error_response.dart`
  - representa timestamp, status, erro textual, mensagem e `fieldErrors`.

### Presentation

- `lib/features/auth/presentation/controllers/auth_controller.dart`
  - controla estados `initial`, `loading`, `authenticated`, `unauthenticated` e `error`;
  - restaura uma sessão existente;
  - verifica visualmente a expiração pelo claim `exp` do JWT;
  - implementa login, registro, confirmação, reenvio, recuperação, redefinição e logout;
  - transforma `401` de login convencional em uma mensagem neutra de credenciais inválidas.

- `lib/features/auth/presentation/pages/auth_pages.dart`
  - contém login, cadastro, confirmação, recuperação, redefinição e área autenticada;
  - possui formulário, validação local, loading, cooldown e painel de erro;
  - utiliza o botão oficial de Google Identity Services no Web;
  - exibe orientação direta para usuário já autenticado como Google.

## Rotas do frontend

As rotas configuradas em `lib/app.dart` são:

- `/login`;
- `/register`;
- `/confirm-email`;
- `/forgot`;
- `/reset-password`;
- `/home`.

O usuário não autenticado não acessa `/home`. O usuário autenticado é redirecionado para `/home` fora das telas públicas de autenticação.

## Contratos consumidos

A URL base vem de `API_BASE_URL` e os caminhos são relativos a `/api/auth`.

### Cadastro convencional

```http
POST /api/auth/register
Content-Type: application/json
```

Payload enviado pelo repositório:

```json
{
  "nome": "Nome Completo",
  "email": "usuario@example.com",
  "senha": "Senha123",
  "confirmarSenha": "Senha123"
}
```

O frontend valida nome, e-mail, política mínima da senha e coincidência das senhas antes do envio. Após `201`, navega para `/confirm-email` com o e-mail preenchido.

### Confirmação de e-mail

```http
POST /api/auth/confirm-email
Content-Type: application/json
```

```json
{
  "email": "usuario@example.com",
  "codigo": "123456"
}
```

O campo aceita somente dígitos e limita a entrada a seis caracteres. Esta resposta não salva JWT: após sucesso, o frontend envia o usuário para login.

### Reenvio de confirmação

```http
POST /api/auth/resend-code
Content-Type: application/json
```

```json
{
  "email": "usuario@example.com"
}
```

A tela possui cooldown local de 60 segundos no fluxo de confirmação. `429` é tratado como limite de reenvio.

### Login convencional

```http
POST /api/auth/login
Content-Type: application/json
```

```json
{
  "email": "usuario@example.com",
  "senha": "Senha123"
}
```

Respostas relevantes tratadas pelo frontend:

- `200`: salva token e usuário, tornando o estado autenticado;
- `401`: informa credenciais inválidas sem diferenciar existência da conta;
- `403`: oferece opção de navegar à confirmação do e-mail;
- `400`, `409`, `429` e `500`: passam pelo mapeamento de `ApiError`;
- falha de rede ou timeout: apresenta mensagem própria de rede ou cold start.

### Login Google

```http
POST /api/auth/google
Content-Type: application/json
```

Payload:

```json
{
  "credential": "google_id_token"
}
```

O frontend usa o Google Identity Services/Google Sign-In Web para capturar o ID Token. Ele envia o valor no campo `credential` e não envia o `access_token` do Google nem dados extraídos manualmente como substitutos da credencial.

O backend valida o token e retorna `AuthResponse`. O frontend só persiste a resposta após o backend concluir a autenticação.

A integração depende de:

- `GOOGLE_CLIENT_ID` via `--dart-define`;
- origem efetiva autorizada no Google Cloud Console;
- mesmo Client ID configurado no backend;
- CORS configurado no backend para a origem real do navegador.

A inicialização múltipla do botão Google e os logs `[GSI_LOGGER]` vêm da biblioteca Google em modo debug; não são gerados pelo repositório frontend. O log pode mostrar o ID Token recebido no navegador, que deve ser tratado como dado sensível temporário e não compartilhado pelo código da aplicação.

### Solicitação de recuperação

```http
POST /api/auth/forgot-password
Content-Type: application/json
```

```json
{
  "email": "usuario@example.com"
}
```

O backend pode responder `200` independentemente de:

- conta inexistente;
- conta Google;
- conta local elegível;
- sucesso ou falha temporária do SMTP.

Por isso, o frontend não afirma que o código foi enviado. A interface usa uma mensagem neutra baseada na elegibilidade de uma conta local e direciona contas Google para o login Google.

A etapa 1 possui cooldown local de 60 segundos após uma solicitação bem-sucedida. `429` também inicia ou representa o intervalo aplicável.

A tela não consulta publicamente o provedor da conta digitada no e-mail.

### Redefinição de senha

```http
POST /api/auth/reset-password
Content-Type: application/json
```

```json
{
  "email": "usuario@example.com",
  "codigo": "123456",
  "novaSenha": "NovaSenha123",
  "confirmarNovaSenha": "NovaSenha123"
}
```

Validações locais:

- e-mail válido;
- código com exatamente seis dígitos;
- senha entre 8 e 72 caracteres;
- pelo menos uma maiúscula;
- pelo menos uma minúscula;
- pelo menos um número;
- novas senhas iguais.

Após `200`, o frontend recebe `AuthResponse`, persiste token e usuário e navega para `/home`, pois o backend retorna JWT imediatamente após a redefinição.

### Logout

```http
POST /api/auth/logout
```

Sem corpo.

A chamada é opcional: o estado real do logout é local.

A ação remove:

- `accessToken`;
- usuário persistido;
- token e usuário em memória;
- erro e estado autenticado.

Depois, redireciona para `/login`. O backend não possui blacklist ou revogação efetiva; o JWT continua válido até expirar.

## Modelo de usuário

`AuthUser` representa os campos observados no cliente:

- `id`;
- `nome`;
- `email`;
- `fotoUrl`;
- `resumo`;
- `links`;
- `pais`;
- `organizacao`;
- `emailContato`;
- `emailVerificado`;
- `provedorAuth`;
- `dataCriacaoConta`.

O frontend não cria ou espera campos como `senhaHash`.

## Estados e cold start

Os estados visuais incluem:

- inicial;
- carregamento;
- validando;
- sucesso;
- erro;
- cooldown;
- rede indisponível;
- servidor indisponível;
- autenticação Google;
- usuário autenticado/não autenticado.

Timeout de conexão/recepção pode produzir a mensagem:

```text
Conectando ao servidor… isso pode levar alguns segundos.
```

## Segurança aplicada

- Google Client ID público fornecido por `dart-define`;
- nenhum Client Secret, JWT Secret, senha SMTP ou credencial administrativa no frontend;
- JWT persistido no storage web compatível, não na URL;
- logout limpa sessão local;
- expiração visual decodificada pelo campo `exp`, sem considerar essa validação como autorização server-side;
- o frontend não registra secrets, tokens, credenciais ou códigos;
- os payloads sensíveis permanecem nos métodos HTTP/repositórios e não em parâmetros de rota ou query string.

## Pontos pendentes ou divergências a validar

- confirmar `APP_FRONTEND_URL=http://localhost:5000` no backend local;
- confirmar que o Google Client ID usado no backend corresponde ao mesmo `--dart-define` do frontend;
- confirmar o domínio/origem autorizado no Google Cloud Console;
- validar entrega SMTP em contas locais convencionais;
- lembrar que contas Google não recebem código de recuperação;
- confirmar as variáveis efetivas de produção do backend e `JWT_EXPIRATION_MINUTES`;
- não há endpoint público para descobrir provedor, usuário atual, sessões ou revogação.

## Comandos

Executar:

```bash
flutter run -d web-server \
  --web-port=5000 \
  --dart-define=API_BASE_URL=http://localhost:8080 \
  --dart-define=GOOGLE_CLIENT_ID=SEU_GOOGLE_CLIENT_ID.apps.googleusercontent.com
```

Build:

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.seudominio.com \
  --dart-define=GOOGLE_CLIENT_ID=SEU_GOOGLE_CLIENT_ID.apps.googleusercontent.com
```
