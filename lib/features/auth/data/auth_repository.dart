import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../domain/user.dart';

class GoogleLoginResult {
  const GoogleLoginResult({required this.accessToken, required this.user});

  final String accessToken;
  final AppUser user;
}

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  /// POST /auth/google — intercambia el idToken de Google por el JWT propio.
  Future<GoogleLoginResult> loginWithGoogle(String idToken) async {
    try {
      final response = await _dio.post('/auth/google', data: {'idToken': idToken});
      final data = response.data as Map<String, dynamic>;
      return GoogleLoginResult(
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
