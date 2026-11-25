import 'package:flutter_test/flutter_test.dart';
import 'package:termiapislabs_frontend/features/auth/domain/entities/user.dart';
import 'package:termiapislabs_frontend/features/auth/data/models/auth_response.dart';
import 'package:termiapislabs_frontend/features/auth/data/dto/api_error_response.dart';

void main() {
  test('AuthUser parses the real API response', () {
    final user = AuthUser.fromJson(const {
      'id': '550e8400-e29b-41d4-a716-446655440000',
      'nome': 'Nome',
      'email': 'usuario@example.com',
      'fotoUrl': null,
      'links': <String>[],
      'emailVerificado': true,
      'provedorAuth': 'LOCAL',
      'dataCriacaoConta': '2026-11-21T20:00:00Z',
    });

    expect(user.email, 'usuario@example.com');
    expect(user.emailVerificado, isTrue);
  });

  test('AuthResponse parses token and user', () {
    final response = AuthResponse.fromJson({
      'accessToken': 'signed.jwt.token',
      'tokenType': 'Bearer',
      'user': {
        'id': '1',
        'nome': 'Nome',
        'email': 'usuario@example.com',
        'links': <String>[],
        'emailVerificado': true,
        'provedorAuth': 'LOCAL',
        'dataCriacaoConta': '2026-11-21T20:00:00Z',
      },
    });

    expect(response.accessToken, 'signed.jwt.token');
    expect(response.tokenType, 'Bearer');
  });

  test('ApiErrorResponse parses field errors', () {
    final response = ApiErrorResponse.fromJson({
      'timestamp': '2026-11-24T12:00:00Z',
      'status': 400,
      'error': 'Bad Request',
      'message': 'Dados inválidos.',
      'fieldErrors': {'email': 'must be a well-formed email address'},
    });

    expect(response.status, 400);
    expect(response.message, 'Dados inválidos.');
    expect(
        response.fieldErrors['email'], 'must be a well-formed email address');
  });
}
