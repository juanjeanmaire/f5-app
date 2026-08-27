import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/players_repository.dart';
import '../domain/player.dart';

class PlayersController extends FamilyAsyncNotifier<List<Player>, String> {
  late final PlayersRepository _repo;
  late final String _groupId;

  @override
  FutureOr<List<Player>> build(String groupId) async {
    _groupId = groupId;
    _repo = ref.watch(playersRepositoryProvider);
    return _repo.listPlayers(groupId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.listPlayers(_groupId));
  }

  Future<void> createPlayer(String name) async {
    await _repo.createPlayer(_groupId, name);
    await refresh();
  }

  Future<void> updatePlayer(String playerId, {String? name, bool? active}) async {
    await _repo.updatePlayer(_groupId, playerId, name: name, active: active);
    await refresh();
  }

  Future<void> deletePlayer(String playerId) async {
    await _repo.deletePlayer(_groupId, playerId);
    await refresh();
  }

  Future<void> claimPlayer(String playerId) async {
    await _repo.claimPlayer(_groupId, playerId);
    await refresh();
  }
}

final playersControllerProvider =
    AsyncNotifierProvider.family<PlayersController, List<Player>, String>(
  PlayersController.new,
);
