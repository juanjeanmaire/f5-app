import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/groups_repository.dart';
import '../domain/group.dart';
import '../domain/group_membership.dart';

class GroupsController extends AsyncNotifier<List<GroupMembership>> {
  late final GroupsRepository _repo;

  @override
  FutureOr<List<GroupMembership>> build() async {
    _repo = ref.watch(groupsRepositoryProvider);
    return _repo.listMyGroups();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.listMyGroups());
  }

  Future<Group> createGroup(String name) async {
    final group = await _repo.createGroup(name);
    await refresh();
    return group;
  }

  Future<Group?> joinGroup(String inviteCode) async {
    final membership = await _repo.joinGroup(inviteCode);
    await refresh();
    return membership.group;
  }

  /// Lanza ApiException si sos el único capitán del grupo — no la
  /// atajamos acá a propósito, la maneja quien llame para mostrar el error.
  Future<void> leaveGroup(String groupId) async {
    await _repo.leaveGroup(groupId);
    await refresh();
  }
}

final groupsControllerProvider =
    AsyncNotifierProvider<GroupsController, List<GroupMembership>>(GroupsController.new);
