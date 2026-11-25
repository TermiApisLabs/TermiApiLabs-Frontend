import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in_web/web_only.dart';

import '../../../../core/network/api_error.dart';
import '../controllers/auth_controller.dart';

class AuthLayout extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final Widget child;
  const AuthLayout(
      {super.key, required this.title, required this.child, this.eyebrow});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth > 1024;
        final card = ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(4, 4))
              ],
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (eyebrow != null)
                    Text(eyebrow!,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 24),
                  child,
                ]),
          ),
        );
        return Row(children: [
          if (wide)
            Expanded(
                child: Container(
                    color: const Color(0xFF111111),
                    child: const Center(
                        child: Text('TERMIAPI\nLABS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                height: 1))))),
          Expanded(
              flex: wide ? 2 : 1,
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: card))),
        ]);
      }),
    );
  }
}

class ErrorPanel extends StatelessWidget {
  final ApiError? error;
  const ErrorPanel(this.error, {super.key});

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();
    final cold = error!.kind == 'cold_start';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: cold ? const Color(0xFFFFE08A) : const Color(0xFFFFE2E2),
          border: Border.all(color: Colors.black, width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(error!.message,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          for (final entry in error!.fieldErrors.entries) ...[
            const SizedBox(height: 6),
            Text('${entry.key}: ${entry.value}',
                style: const TextStyle(fontFamily: 'monospace')),
          ],
        ],
      ),
    );
  }
}

bool validEmail(String value) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
bool validPassword(String value) =>
    value.length >= 8 &&
    value.length <= 72 &&
    RegExp(r'[A-Z]').hasMatch(value) &&
    RegExp(r'[a-z]').hasMatch(value) &&
    RegExp(r'[0-9]').hasMatch(value);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final senha = TextEditingController();
  final form = GlobalKey<FormState>();

  @override
  void dispose() {
    email.dispose();
    senha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return AuthLayout(
        title: 'Entrar',
        eyebrow: 'TERMIAPI LABS / AUTH',
        child: Form(
            key: form,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ErrorPanel(auth.error),
                  if (auth.error?.kind == 'forbidden') ...[
                    OutlinedButton(
                        onPressed: () => context.push('/confirm-email',
                            extra: email.text.trim()),
                        child: const Text('CONFIRMAR MEU E-MAIL')),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                      controller: email,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      validator: (v) => v != null && validEmail(v.trim())
                          ? null
                          : 'Informe um e-mail válido'),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: senha,
                      decoration: const InputDecoration(labelText: 'Senha'),
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Informe sua senha' : null),
                  Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                          onPressed: () => context.push('/forgot'),
                          child: const Text('ESQUECI MINHA SENHA'))),
                  const SizedBox(height: 8),
                  ElevatedButton(
                      onPressed: auth.operationInProgress
                          ? null
                          : () async {
                              if (!form.currentState!.validate()) return;
                              try {
                                await auth.login(
                                    email: email.text.trim(),
                                    senha: senha.text);
                                if (context.mounted) context.go('/home');
                              } catch (_) {}
                            },
                      child: auth.operationInProgress
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('ENTRAR')),
                  const SizedBox(height: 12),
                  const GoogleIdentityButton(),
                  const SizedBox(height: 16),
                  TextButton(
                      onPressed: () => context.push('/register'),
                      child: const Text('CRIAR UMA CONTA')),
                ])));
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nome = TextEditingController();
  final email = TextEditingController();
  final senha = TextEditingController();
  final confirmar = TextEditingController();
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    nome.dispose();
    email.dispose();
    senha.dispose();
    confirmar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return AuthLayout(
        title: 'Criar conta',
        eyebrow: 'NOVO CADASTRO',
        child: Form(
            key: form,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ErrorPanel(auth.error),
                  TextFormField(
                      controller: nome,
                      decoration: const InputDecoration(labelText: 'Nome'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Informe seu nome'
                          : (v.trim().length > 100
                              ? 'Máximo de 100 caracteres'
                              : null)),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: email,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      validator: (v) => v != null && validEmail(v.trim())
                          ? null
                          : 'Informe um e-mail válido'),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: senha,
                      decoration: const InputDecoration(labelText: 'Senha'),
                      obscureText: true,
                      validator: (v) => validPassword(v ?? '')
                          ? null
                          : '8+ caracteres, maiúscula, minúscula e número'),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: confirmar,
                      decoration:
                          const InputDecoration(labelText: 'Confirmar senha'),
                      obscureText: true,
                      validator: (v) =>
                          v == senha.text ? null : 'As senhas não coincidem'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                      onPressed: auth.operationInProgress
                          ? null
                          : () async {
                              if (!form.currentState!.validate()) return;
                              try {
                                await auth.register(
                                    nome: nome.text.trim(),
                                    email: email.text.trim(),
                                    senha: senha.text,
                                    confirmarSenha: confirmar.text);
                                if (context.mounted) {
                                  context.push('/confirm-email',
                                      extra: email.text.trim());
                                }
                              } catch (_) {}
                            },
                      child: auth.operationInProgress
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('CADASTRAR')),
                  const SizedBox(height: 12),
                  const GoogleIdentityButton(),
                  const SizedBox(height: 12),
                  TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('JÁ TENHO UMA CONTA')),
                ])));
  }
}

class ConfirmEmailPage extends StatefulWidget {
  final String initialEmail;
  const ConfirmEmailPage({super.key, required this.initialEmail});
  @override
  State<ConfirmEmailPage> createState() => _ConfirmEmailPageState();
}

class _ConfirmEmailPageState extends State<ConfirmEmailPage> {
  late final TextEditingController email;
  final codigo = TextEditingController();
  final form = GlobalKey<FormState>();
  int cooldown = 0;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    email.dispose();
    codigo.dispose();
    timer?.cancel();
    super.dispose();
  }

  void startCooldown() {
    setState(() => cooldown = 60);
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (cooldown <= 1) {
        timer?.cancel();
        setState(() => cooldown = 0);
      } else {
        setState(() => cooldown--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return AuthLayout(
        title: 'Confirmar e-mail',
        eyebrow: 'CÓDIGO DE 6 DÍGITOS',
        child: Form(
            key: form,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ErrorPanel(auth.error),
                  TextFormField(
                      controller: email,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      validator: (v) => v != null && validEmail(v.trim())
                          ? null
                          : 'Informe um e-mail válido'),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: codigo,
                      decoration: const InputDecoration(labelText: 'Código'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6)
                      ],
                      validator: (v) =>
                          v != null && RegExp(r'^\d{6}$').hasMatch(v)
                              ? null
                              : 'Informe os 6 dígitos'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                      onPressed: auth.operationInProgress
                          ? null
                          : () async {
                              if (!form.currentState!.validate()) return;
                              try {
                                await auth.confirmEmail(
                                    email.text.trim(), codigo.text);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('E-mail confirmado.')));
                                  context.go('/login');
                                }
                              } catch (_) {}
                            },
                      child: const Text('CONFIRMAR')),
                  const SizedBox(height: 12),
                  OutlinedButton(
                      onPressed: auth.operationInProgress || cooldown > 0
                          ? null
                          : () async {
                              if (!validEmail(email.text.trim())) return;
                              try {
                                await auth.resendCode(email.text.trim());
                                startCooldown();
                              } catch (_) {}
                            },
                      child: Text(cooldown > 0
                          ? 'REENVIAR EM ${cooldown}s'
                          : 'REENVIAR CÓDIGO')),
                ])));
  }
}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final email = TextEditingController();
  final form = GlobalKey<FormState>();
  bool accepted = false;
  int cooldown = 0;
  Timer? timer;

  @override
  void dispose() {
    email.dispose();
    timer?.cancel();
    super.dispose();
  }

  void startCooldown() {
    setState(() => cooldown = 60);
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (cooldown <= 1) {
        timer?.cancel();
        setState(() => cooldown = 0);
      } else {
        setState(() => cooldown--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return AuthLayout(
      title: 'Recuperar senha',
      eyebrow: 'ETAPA 1',
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ErrorPanel(auth.error),
            if (accepted)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FF),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: const Text(
                  'Se houver uma conta local elegível associada a este e-mail, as instruções serão enviadas. Contas cadastradas com Google devem continuar entrando com o botão Continuar com Google.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            TextFormField(
              controller: email,
              decoration: const InputDecoration(labelText: 'E-mail'),
              validator: (value) => value != null && validEmail(value.trim())
                  ? null
                  : 'Informe um e-mail válido',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: auth.operationInProgress || cooldown > 0
                  ? null
                  : () async {
                      if (!form.currentState!.validate()) return;
                      try {
                        await auth.forgotPassword(email.text.trim());
                        if (context.mounted) {
                          setState(() => accepted = true);
                          startCooldown();
                        }
                      } catch (_) {
                        if (context.mounted &&
                            auth.error?.kind == 'rate_limited') {
                          startCooldown();
                        }
                      }
                    },
              child: auth.operationInProgress
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(cooldown > 0
                      ? 'SOLICITAR NOVAMENTE EM ${cooldown}s'
                      : 'SOLICITAR CÓDIGO'),
            ),
            if (accepted) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push(
                  '/reset-password',
                  extra: email.text.trim(),
                ),
                child: const Text('CONTINUAR PARA REDEFINIÇÃO'),
              ),
            ],
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('VOLTAR AO LOGIN'),
            ),
          ],
        ),
      ),
    );
  }
}

class ResetPasswordPage extends StatefulWidget {
  final String initialEmail;
  const ResetPasswordPage({super.key, required this.initialEmail});
  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  late final TextEditingController email;
  final codigo = TextEditingController();
  final nova = TextEditingController();
  final confirmar = TextEditingController();
  final form = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    email.dispose();
    codigo.dispose();
    nova.dispose();
    confirmar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return AuthLayout(
        title: 'Redefinir senha',
        eyebrow: 'ETAPA 2',
        child: Form(
            key: form,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ErrorPanel(auth.error),
                  TextFormField(
                      controller: email,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      validator: (v) => v != null && validEmail(v.trim())
                          ? null
                          : 'Informe um e-mail válido'),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: codigo,
                      decoration: const InputDecoration(
                          labelText: 'Código de 6 dígitos'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6)
                      ],
                      validator: (v) =>
                          v != null && RegExp(r'^\d{6}$').hasMatch(v)
                              ? null
                              : 'Informe os 6 dígitos'),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: nova,
                      decoration:
                          const InputDecoration(labelText: 'Nova senha'),
                      obscureText: true,
                      validator: (v) => validPassword(v ?? '')
                          ? null
                          : '8+ caracteres, maiúscula, minúscula e número'),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: confirmar,
                      decoration: const InputDecoration(
                          labelText: 'Confirmar nova senha'),
                      obscureText: true,
                      validator: (v) =>
                          v == nova.text ? null : 'As senhas não coincidem'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                      onPressed: auth.operationInProgress
                          ? null
                          : () async {
                              if (!form.currentState!.validate()) return;
                              try {
                                await auth.resetPassword(
                                    email: email.text.trim(),
                                    codigo: codigo.text,
                                    novaSenha: nova.text,
                                    confirmarNovaSenha: confirmar.text);
                                if (context.mounted) context.go('/home');
                              } catch (_) {}
                            },
                      child: const Text('REDEFINIR E ENTRAR')),
                ])));
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      appBar: AppBar(title: const Text('TermiAPILabs')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(4, 4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sessão autenticada',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                Text('Usuário: ${auth.user?.nome ?? ''}'),
                const SizedBox(height: 8),
                Text(
                  'E-mail: ${auth.user?.email ?? ''}',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    await auth.logout();
                    if (context.mounted) context.go('/login');
                  },
                  child: const Text('SAIR'),
                ),
                if (auth.user?.provedorAuth == 'GOOGLE') ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1FF),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: const Text(
                      'Esta conta utiliza login com Google. Continue entrando com o Google.',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GoogleIdentityButton extends StatelessWidget {
  const GoogleIdentityButton({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (auth.operationInProgress) {
      return const SizedBox(height: 48);
    }
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: renderButton(
        configuration: GSIButtonConfiguration(
          type: GSIButtonType.standard,
          theme: GSIButtonTheme.outline,
          size: GSIButtonSize.large,
          text: GSIButtonText.continueWith,
          shape: GSIButtonShape.rectangular,
          minimumWidth: 400,
        ),
      ),
    );
  }
}
