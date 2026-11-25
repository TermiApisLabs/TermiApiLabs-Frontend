import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/pages/auth_pages.dart';

class TermiApp extends StatelessWidget {
  final AuthController auth;
  const TermiApp({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/login',
      refreshListenable: auth,
      redirect: (context, state) {
        if (auth.status == AuthStatus.initial) return null;
        final loggingIn = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register' ||
            state.matchedLocation == '/confirm-email' ||
            state.matchedLocation == '/forgot' ||
            state.matchedLocation == '/reset-password';
        if (auth.status == AuthStatus.unauthenticated &&
            state.matchedLocation == '/home') return '/login';
        if (auth.status == AuthStatus.authenticated && loggingIn) {
          return '/home';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
        GoRoute(
            path: '/confirm-email',
            builder: (_, state) => ConfirmEmailPage(
                initialEmail:
                    state.extra is String ? state.extra as String : '')),
        GoRoute(
            path: '/forgot', builder: (_, __) => const ForgotPasswordPage()),
        GoRoute(
            path: '/reset-password',
            builder: (_, state) => ResetPasswordPage(
                initialEmail:
                    state.extra is String ? state.extra as String : '')),
        GoRoute(path: '/home', builder: (_, __) => const HomePage()),
      ],
    );

    return ChangeNotifierProvider.value(
      value: auth,
      child: MaterialApp.router(
        title: 'TermiAPILabs',
        theme: AppTheme.light(),
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
