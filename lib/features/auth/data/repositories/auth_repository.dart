import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/user.dart';
import '../models/auth_response.dart';

class AuthRepository {
  final ApiClient _api;

  AuthRepository({ApiClient? api}) : _api = api ?? ApiClient();

  Future<T> _run<T>(Future<Response<T>> request) async {
    try {
      final response = await request;
      return response.data as T;
    } catch (error) {
      throw _api.toApiError(error);
    }
  }

  Future<AuthUser> register(
      {required String nome,
      required String email,
      required String senha,
      required String confirmarSenha}) async {
    final data =
        await _run<Map<String, dynamic>>(_api.post('/api/auth/register', data: {
      'nome': nome,
      'email': email,
      'senha': senha,
      'confirmarSenha': confirmarSenha,
    }));
    return AuthUser.fromJson(data);
  }

  Future<AuthUser> confirmEmail(
      {required String email, required String codigo}) async {
    final data = await _run<Map<String, dynamic>>(_api.post(
        '/api/auth/confirm-email',
        data: {'email': email, 'codigo': codigo}));
    return AuthUser.fromJson(data);
  }

  Future<Map<String, dynamic>> resendCode(String email) =>
      _run<Map<String, dynamic>>(
          _api.post('/api/auth/resend-code', data: {'email': email}));

  Future<AuthResponse> login(
      {required String email, required String senha}) async {
    final data = await _run<Map<String, dynamic>>(
        _api.post('/api/auth/login', data: {'email': email, 'senha': senha}));
    return AuthResponse.fromJson(data);
  }

  Future<AuthResponse> googleLogin(String credential) async {
    final data = await _run<Map<String, dynamic>>(
        _api.post('/api/auth/google', data: {'credential': credential}));
    return AuthResponse.fromJson(data);
  }

  Future<Map<String, dynamic>> forgotPassword(String email) =>
      _run<Map<String, dynamic>>(
          _api.post('/api/auth/forgot-password', data: {'email': email}));

  Future<AuthResponse> resetPassword(
      {required String email,
      required String codigo,
      required String novaSenha,
      required String confirmarNovaSenha}) async {
    final data = await _run<Map<String, dynamic>>(
        _api.post('/api/auth/reset-password', data: {
      'email': email,
      'codigo': codigo,
      'novaSenha': novaSenha,
      'confirmarNovaSenha': confirmarNovaSenha,
    }));
    return AuthResponse.fromJson(data);
  }

  Future<Map<String, dynamic>> logout() =>
      _run<Map<String, dynamic>>(_api.post('/api/auth/logout'));
}
