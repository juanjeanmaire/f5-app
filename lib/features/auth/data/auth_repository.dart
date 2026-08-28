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
  Future<LoginResult> login({
    required String email,
    required String name,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'name': name, 'password': password},
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
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio);
});
