import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../domain/user.dart';

class LoginResult {
  const LoginResult({required this.accessToken, required this.user});

  final String accessToken;
  final AppUser user;
}

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  /// POST /auth/login — sin registro separado: si el email no existe, se
  /// crea la cuenta con esta contraseña; si existe, tiene que coincidir.
  /// [name] es opcional: si no se manda, el backend usa la parte antes de
  /// la @ del email como nombre por defecto (se puede editar después
  /// desde el perfil).
  Future<LoginResult> login({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password, if (name != null) 'name': name},
      );
      final data = response.data as Map<String, dynamic>;
      return LoginResult(
        accessToken: data['accessToken'] as String,
        user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// GET /users/me — usado para validar/rehidratar la sesión al abrir la app.
  Future<AppUser> fetchMe() async {
    try {
      final response = await _dio.get('/users/me');
      return AppUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// POST /auth/logout — libera la sesión del lado del servidor, para que
  /// se pueda volver a loguear (mismo u otro dispositivo). Sin esto, el
  /// login queda bloqueado para siempre (la sesión no vence sola).
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio);
});
