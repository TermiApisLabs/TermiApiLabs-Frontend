import 'dart:async';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_error.dart';

class ApiClient {
  final Dio dio;

  ApiClient({String? bearerToken})
      : dio = Dio(BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 45),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (bearerToken != null && bearerToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $bearerToken';
        }
        handler.next(options);
      },
    ));
  }

  Future<Response<T>> post<T>(String path, {Object? data}) {
    return dio.post<T>(path, data: data);
  }

  Future<Response<T>> get<T>(String path) => dio.get<T>(path);

  ApiError toApiError(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return const ApiError(
          status: null,
          message: 'Conectando ao servidor… isso pode levar alguns segundos.',
          kind: 'cold_start',
        );
      }
      if (error.type == DioExceptionType.connectionError) {
        return const ApiError(
          status: null,
          message:
              'Não foi possível alcançar o servidor. Verifique sua conexão.',
          kind: 'network_error',
        );
      }
      final response = error.response;
      if (response?.data is Map) {
        final body = Map<String, dynamic>.from(response!.data as Map);
        final rawFields = body['fieldErrors'];
        final fields = <String, String>{};
        if (rawFields is Map) {
          for (final entry in rawFields.entries) {
            fields[entry.key.toString()] = entry.value.toString();
          }
        }
        final status = body['status'] is int
            ? body['status'] as int
            : (response.statusCode ?? 0);
        final kind = _kindForStatus(status);
        return ApiError(
          status: status,
          message: body['message']?.toString() ??
              'Não foi possível concluir a operação.',
          fieldErrors: fields,
          kind: kind,
        );
      }
      if (response?.statusCode != null) {
        final status = response!.statusCode!;
        final kind = _kindForStatus(status);
        return ApiError(
            status: status,
            message: 'Resposta inválida do servidor.',
            kind: kind);
      }
    }
    return const ApiError(
        status: null, message: 'Ocorreu uma falha inesperada.', kind: 'error');
  }

  String _kindForStatus(int status) {
    return switch (status) {
      400 => 'validation',
      401 => 'unauthorized',
      403 => 'forbidden',
      409 => 'conflict',
      429 => 'rate_limited',
      >= 500 => 'server_error',
      _ => 'error',
    };
  }
}
