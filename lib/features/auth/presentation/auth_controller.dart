import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_repository.dart';
import '../domain/user.dart';

/// Estado de sesión de la app: `null` = no autenticado, `AppUser` = autenticado.
/// El router (core/router/app_router.dart) observa este provider para decidir
/// si mostrar /login o el resto de la app.
///
/// Login por email + contraseña (no por Google — se abandonó esa vía por
/// problemas irresolubles de Google Play Services/Credential Manager en
/// dispositivos reales). Sin registro separado: la contraseña queda fijada
/// para ese email en el primer login.
class AuthController extends AsyncNotifier<AppUser?> {
  late final AuthRepository _repo;
  late final SecureStorage _storage;

  @override
  FutureOr<AppUser?> build() async {
    // Fuerza re-evaluación cuando el backend devolvió 401 en algún request.
    ref.watch(sessionExpiredProvider);

    _repo = ref.watch(authRepositoryProvider);
    _storage = ref.watch(secureStorageProvider);

    final token = await _storage.readToken();
    if (token == null) return null;

    try {
      return await _repo.fetchMe();
    } on ApiException catch (e) {
      if (e.isUnauthorized) await _storage.deleteToken();
      return null;
    }
  }

  Future<void> login({
    required String email,
    required String name,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.login(email: email, name: name, password: password);
      await _storage.saveToken(result.accessToken);
      return result.user;
    });
  }

  Future<void> signOut() async {
    await _storage.deleteToken();
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);
