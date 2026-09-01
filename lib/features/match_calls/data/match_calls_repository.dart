import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../matches/domain/match.dart';
import '../domain/match_call.dart';

class MatchCallsRepository {
  MatchCallsRepository(this._dio);

  final Dio _dio;

  /// Solo el capitán, y solo si no hay otra convocatoria activa.
  Future<MatchCall> create(
    String groupId, {
    required MatchType matchType,
    required DateTime date,
    String? venueAddress,
    String? comment,
  }) async {
    try {
      final response = await _dio.post(
        '/groups/$groupId/match-calls',
        data: {
          'matchType': matchType.toJson(),
          'date': date.toIso8601String(),
          if (venueAddress != null) 'venueAddress': venueAddress,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        },
      );
      return MatchCall.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// La convocatoria activa del grupo (abierta, o cerrada reciente) —
  /// null si no hay ninguna.
  Future<MatchCall?> getActive(String groupId) async {
    try {
      final response = await _dio.get('/groups/$groupId/match-calls/active');
      if (response.data == null) return null;
      return MatchCall.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<MatchCall> getDetail(String groupId, String callId) async {
    try {
      final response = await _dio.get('/groups/$groupId/match-calls/$callId');
      return MatchCall.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<MatchCall> respond(String groupId, String callId, {required bool going}) async {
    try {
      final response = await _dio.post(
        '/groups/$groupId/match-calls/$callId/respond',
        data: {'going': going},
      );
      return MatchCall.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Solo el capitán, y solo mientras siga abierta.
  Future<void> cancel(String groupId, String callId) async {
    try {
      await _dio.delete('/groups/$groupId/match-calls/$callId');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final matchCallsRepositoryProvider = Provider<MatchCallsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return MatchCallsRepository(dio);
});
