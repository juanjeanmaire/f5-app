import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/secure_storage.dart';

/// Se incrementa cada vez que el backend devuelve 401. AuthController lo
/// escucha (ref.watch) para re-evaluar la sesión y, al no encontrar token,
/// disparar el redirect a /login desde el router.
///
/// Deliberadamente vive en `core` y no conoce a `features/auth`: quien
/// depende de quién queda en una sola dirección (features -> core).
final sessionExpiredProvider = StateProvider<int>((ref) => 0);

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.readToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          storage.deleteToken();
          ref.read(sessionExpiredProvider.notifier).state++;
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});
