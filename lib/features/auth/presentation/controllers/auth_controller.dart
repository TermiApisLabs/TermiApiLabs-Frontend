import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/storage/session_storage.dart';
import '../../domain/entities/user.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthController extends ChangeNotifier {
  final AuthRepository repository;
  final SessionStorage storage;

  final GoogleSignIn? _google;
  StreamSubscription<GoogleSignInAccount?>? _googleSubscription;

  AuthStatus status = AuthStatus.initial;
  AuthUser? user;
  String? token;
  ApiError? error;
  bool operationInProgress = false;

  AuthController({AuthRepository? repository, SessionStorage? storage})
      : repository = repository ?? AuthRepository(),
        storage = storage ?? SessionStorage(),
        _google = kIsWeb && AppConfig.googleClientId.isNotEmpty
            ? GoogleSignIn(
                clientId: AppConfig.googleClientId,
                scopes: const ['openid', 'email', 'profile'],
              )
            : null {
    _googleSubscription = _google?.onCurrentUserChanged.listen((account) {
      if (account != null) {
        googleLoginWithAccount(account);
      }
    });
  }

  Future<void> initialize() async {
    final savedToken = await storage.readToken();
    final savedUser = await storage.readUser();
    if (savedToken != null && savedUser != null && !_isExpired(savedToken)) {
      token = savedToken;
      user = AuthUser.fromJson(savedUser);
      status = AuthStatus.authenticated;
    } else {
      await storage.clear();
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> register(
      {required String nome,
      required String email,
      required String senha,
      required String confirmarSenha}) async {
    await _run(() async {
      await repository.register(
          nome: nome,
          email: email,
          senha: senha,
          confirmarSenha: confirmarSenha);
    });
  }

  Future<void> login({required String email, required String senha}) async {
    await _run(() async {
      try {
        final result = await repository.login(email: email, senha: senha);
        await _saveAuth(result.accessToken, result.user);
      } on ApiError catch (error) {
        if (error.status == 401) {
          throw const ApiError(
            status: 401,
            message: 'E-mail ou senha inválidos.',
            kind: 'unauthorized',
          );
        }
        rethrow;
      }
    });
  }

  Future<void> googleLogin() async {
    throw const ApiError(
      status: null,
      message: 'Use o botão oficial do Google Identity Services.',
      kind: 'validation',
    );
  }

  Future<void> googleLoginWithAccount(GoogleSignInAccount account) async {
    await _run(() async {
      final authentication = await account.authentication;
      final credential = authentication.idToken;
      if (credential == null || credential.isEmpty) {
        throw const ApiError(
            status: null,
            message: 'Não foi possível obter o ID Credential do Google.',
            kind: 'unauthorized');
      }
      final result = await repository.googleLogin(credential);
      await _saveAuth(result.accessToken, result.user);
    });
  }

  Future<void> confirmEmail(String email, String codigo) async {
    await _run(
        () async => repository.confirmEmail(email: email, codigo: codigo));
  }

  Future<Map<String, dynamic>> resendCode(String email) async {
    error = null;
    operationInProgress = true;
    notifyListeners();
    try {
      final result = await repository.resendCode(email);
      return result;
    } catch (e) {
      error = e is ApiError
          ? e
          : const ApiError(
              status: null,
              message: 'Falha ao reenviar o código.',
              kind: 'error');
      rethrow;
    } finally {
      operationInProgress = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    error = null;
    operationInProgress = true;
    notifyListeners();
    try {
      return await repository.forgotPassword(email);
    } catch (e) {
      error = e is ApiError
          ? e
          : const ApiError(
              status: null,
              message: 'Falha ao solicitar recuperação.',
              kind: 'error');
      rethrow;
    } finally {
      operationInProgress = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(
      {required String email,
      required String codigo,
      required String novaSenha,
      required String confirmarNovaSenha}) async {
    await _run(() async {
      final result = await repository.resetPassword(
          email: email,
          codigo: codigo,
          novaSenha: novaSenha,
          confirmarNovaSenha: confirmarNovaSenha);
      await _saveAuth(result.accessToken, result.user);
    });
  }

  Future<void> logout({bool callServer = true}) async {
    if (callServer) {
      try {
        await repository.logout();
      } catch (_) {
        // Logout local não depende da resposta HTTP.
      }
    }
    await storage.clear();
    token = null;
    user = null;
    error = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() action) async {
    error = null;
    operationInProgress = true;
    status = AuthStatus.loading;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      error = e is ApiError
          ? e
          : const ApiError(
              status: null, message: 'Falha inesperada.', kind: 'error');
      status = AuthStatus.error;
      rethrow;
    } finally {
      operationInProgress = false;
      notifyListeners();
    }
  }

  Future<void> _saveAuth(String accessToken, AuthUser authUser) async {
    await storage.saveSession(accessToken, authUser.toJson());
    token = accessToken;
    user = authUser;
    status = AuthStatus.authenticated;
  }

  bool _isExpired(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return true;
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      switch (payload.length % 4) {
        case 2:
          payload += '==';
        case 3:
          payload += '=';
      }
      final data = jsonDecode(utf8.decode(base64Url.decode(payload))) as Map;
      final exp = data['exp'];
      if (exp is! num) return false;
      return DateTime.now().millisecondsSinceEpoch / 1000 >= exp;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _googleSubscription?.cancel();
    super.dispose();
  }
}
