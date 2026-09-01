import 'package:dio/dio.dart';

/// Excepción tipada que mapea las respuestas de error del backend
/// (NestJS + ValidationPipe devuelve { statusCode, message, error }).
class ApiException implements Exception {
  ApiException({this.statusCode, required this.message, this.details});

  final int? statusCode;
  final String message;
  final Object? details;

  factory ApiException.fromDioError(DioException e) {
    final response = e.response;

    if (response != null && response.data is Map) {
      final data = response.data as Map;
      final rawMessage = data['message'];
      final message = rawMessage is List
          ? rawMessage.join(', ')
          : (rawMessage?.toString() ?? 'Ocurrió un error inesperado');

      return ApiException(
        statusCode: response.statusCode,
        message: message,
        details: data,
      );
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return ApiException(
        message: 'No se pudo conectar con el servidor. Revisá tu conexión.',
      );
    }

    return ApiException(
      statusCode: response?.statusCode,
      message: e.message ?? 'Ocurrió un error inesperado',
    );
  }

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isBadRequest => statusCode == 400;

  @override
  String toString() => message;
}
