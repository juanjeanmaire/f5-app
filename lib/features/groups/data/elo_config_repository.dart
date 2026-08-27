import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../domain/elo_config.dart';

class EloConfigRepository {
  EloConfigRepository(this._dio);

  final Dio _dio;

  Future<EloConfig> getEloConfig(String groupId) async {
    try {
      final response = await _dio.get('/groups/$groupId/elo-config');
      return EloConfig.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// [changes] solo debe incluir las claves que se quieren actualizar.
  Future<EloConfig> updateEloConfig(String groupId, Map<String, dynamic> changes) async {
    try {
      final response = await _dio.patch('/groups/$groupId/elo-config', data: changes);
      return EloConfig.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final eloConfigRepositoryProvider = Provider<EloConfigRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return EloConfigRepository(dio);
});

final eloConfigProvider = FutureProvider.family<EloConfig, String>((ref, groupId) async {
  final repo = ref.watch(eloConfigRepositoryProvider);
  return repo.getEloConfig(groupId);
});
