import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../domain/player.dart';

class PlayersRepository {
  PlayersRepository(this._dio);

  final Dio _dio;

  Future<Player> createPlayer(String groupId, String name) async {
    try {
      final response = await _dio.post('/groups/$groupId/players', data: {'name': name});
      return Player.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Player>> listPlayers(String groupId) async {
    try {
      final response = await _dio.get('/groups/$groupId/players');
      return (response.data as List)
          .map((e) => Player.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Player> updatePlayer(
    String groupId,
    String playerId, {
    String? name,
    bool? active,
  }) async {
    try {
      final data = <String, dynamic>{
        if (name != null) 'name': name,
        if (active != null) 'active': active,
      };
      final response = await _dio.patch('/groups/$groupId/players/$playerId', data: data);
      return Player.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Solo funciona si el jugador nunca jugó un partido (lo valida el backend);
  /// si ya tiene historial, hay que desactivarlo en vez de borrarlo.
  Future<void> deletePlayer(String groupId, String playerId) async {
    try {
      await _dio.delete('/groups/$groupId/players/$playerId');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Player> claimPlayer(String groupId, String playerId) async {
    try {
      final response = await _dio.post('/groups/$groupId/players/$playerId/claim');
      return Player.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final playersRepositoryProvider = Provider<PlayersRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return PlayersRepository(dio);
});
