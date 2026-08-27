import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/matches_repository.dart';
import '../domain/match.dart';

class MatchesController extends FamilyAsyncNotifier<List<Match>, String> {
  late final MatchesRepository _repo;
  late final String _groupId;

  @override
  FutureOr<List<Match>> build(String groupId) async {
    _groupId = groupId;
    _repo = ref.watch(matchesRepositoryProvider);
    return _repo.listMatches(groupId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.listMatches(_groupId));
  }

  Future<Match> createMatch({
    required MatchType matchType,
    required int scoreA,
    required int scoreB,
    required List<String> teamAPlayerIds,
    required List<String> teamBPlayerIds,
  }) async {
    final match = await _repo.createMatch(
      groupId: _groupId,
      matchType: matchType,
      scoreA: scoreA,
      scoreB: scoreB,
      teamAPlayerIds: teamAPlayerIds,
      teamBPlayerIds: teamBPlayerIds,
    );
    await refresh();
    return match;
  }
}

final matchesControllerProvider =
    AsyncNotifierProvider.family<MatchesController, List<Match>, String>(
  MatchesController.new,
);
