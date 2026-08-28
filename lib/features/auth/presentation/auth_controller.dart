import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/config/app_config.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_repository.dart';
import '../domain/user.dart';

/// Estado de sesión de la app: `null` = no autenticado, `AppUser` = autenticado.
/// El router (core/router/app_router.dart) observa este provider para decidir
/// si mostrar /login o el resto de la app.
///
/// Usa google_sign_in 7.x (basado en Android Credential Manager) — la API
/// vieja (6.x, basada en el SDK de Google Play Services Auth) fue
/// deprecada y dejó de funcionar en dispositivos reales.
class AuthController extends AsyncNotifier<AppUser?> {
  late final AuthRepository _repo;
  late final SecureStorage _storage;
  bool _googleSignInInitialized = false;

  @override
  FutureOr<AppUser?> build() async {
    // Fuerza re-evaluación cuando el backend devolvió 401 en algún request.
    ref.watch(sessionExpiredProvider);

    _repo = ref.watch(authRepositoryProvider);
    _storage = ref.watch(secureStorageProvider);

    // google_sign_in 7.x exige llamar initialize() una sola vez, antes de
    // cualquier otro método del plugin.
    if (!_googleSignInInitialized) {
      await GoogleSignIn.instance.initialize(
        serverClientId: AppConfig.googleServerClientId.isEmpty
            ? null
            : AppConfig.googleServerClientId,
      );
      _googleSignInInitialized = true;
    }

    final token = await _storage.readToken();
    if (token == null) return null;

    try {
      return await _repo.fetchMe();
    } on ApiException catch (e) {
      if (e.isUnauthorized) await _storage.deleteToken();
      return null;
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final GoogleSignInAccount account;
      try {
        // scopeHint: pedimos el email ya en el paso de autenticación, para
        // que el idToken resultante incluya el claim de email (lo valida
        // el backend).
        account = await GoogleSignIn.instance.authenticate(
          scopeHint: const ['email'],
        );
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled) {
          throw ApiException(message: 'Inicio de sesión cancelado');
        }
        throw ApiException(message: 'No se pudo iniciar sesión con Google (${e.code})');
      }

      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw ApiException(message: 'No se pudo obtener el token de Google');
      }

      final result = await _repo.loginWithGoogle(idToken);
      await _storage.saveToken(result.accessToken);
      return result.user;
    });
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _storage.deleteToken();
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);
