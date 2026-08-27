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
class AuthController extends AsyncNotifier<AppUser?> {
  late final AuthRepository _repo;
  late final SecureStorage _storage;
  late final GoogleSignIn _googleSignIn;

  @override
  FutureOr<AppUser?> build() async {
    // Fuerza re-evaluación cuando el backend devolvió 401 en algún request.
    ref.watch(sessionExpiredProvider);

    _repo = ref.watch(authRepositoryProvider);
    _storage = ref.watch(secureStorageProvider);
    _googleSignIn = GoogleSignIn(
      serverClientId: AppConfig.googleServerClientId.isEmpty
          ? null
          : AppConfig.googleServerClientId,
      scopes: const ['email'],
    );

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
      final googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        throw ApiException(message: 'Inicio de sesión cancelado');
      }

      final googleAuth = await googleAccount.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw ApiException(message: 'No se pudo obtener el token de Google');
      }

      final result = await _repo.loginWithGoogle(idToken);
      await _storage.saveToken(result.accessToken);
      return result.user;
    });
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _storage.deleteToken();
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);
