import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../domain/match.dart';

class MatchesRepository {
  MatchesRepository(this._dio);

  final Dio _dio;

  Future<Match> createMatch({
    required String groupId,
    required MatchType matchType,
    required int scoreA,
    required int scoreB,
    required List<String> teamAPlayerIds,
    required List<String> teamBPlayerIds,
  }) async {
    try {
      final response = await _dio.post(
        '/groups/$groupId/matches',
        data: {
          'matchType': matchType.toJson(),
          'scoreA': scoreA,
          'scoreB': scoreB,
          'teamAPlayerIds': teamAPlayerIds,
          'teamBPlayerIds': teamBPlayerIds,
        },
      );
      return Match.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Match>> listMatches(String groupId) async {
    try {
      final response = await _dio.get('/groups/$groupId/matches');
      return (response.data as List)
          .map((e) => Match.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final matchesRepositoryProvider = Provider<MatchesRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return MatchesRepository(dio);
});
