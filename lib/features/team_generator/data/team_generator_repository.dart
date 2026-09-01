import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../domain/team_generation_result.dart';

class TeamGeneratorRepository {
  TeamGeneratorRepository(this._dio);

  final Dio _dio;

  /// De solo lectura: no persiste nada en el backend, es una propuesta.
  Future<TeamGenerationResult> generate(String groupId, List<String> playerIds) async {
    try {
      final response = await _dio.post(
        '/groups/$groupId/team-generator',
        data: {'playerIds': playerIds},
      );
      return TeamGenerationResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final teamGeneratorRepositoryProvider = Provider<TeamGeneratorRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TeamGeneratorRepository(dio);
});
