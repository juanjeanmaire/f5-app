import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../domain/match.dart';

class MyMatchesRepository {
  MyMatchesRepository(this._dio);

  final Dio _dio;

  /// Todos los partidos del usuario, en todos sus grupos.
  Future<List<Match>> listMyMatches() async {
    try {
      final response = await _dio.get('/matches/mine');
      return (response.data as List)
          .map((e) => Match.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final myMatchesRepositoryProvider = Provider<MyMatchesRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return MyMatchesRepository(dio);
});

final myMatchesProvider = FutureProvider<List<Match>>((ref) async {
  final repo = ref.watch(myMatchesRepositoryProvider);
  return repo.listMyMatches();
});
