import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/groups_repository.dart';
import '../domain/group.dart';
import '../domain/group_membership.dart';

/// FutureProvider.family: uno por groupId, cacheado independientemente.
final groupDetailProvider = FutureProvider.family<Group, String>((ref, groupId) async {
  final repo = ref.watch(groupsRepositoryProvider);
  return repo.getGroup(groupId);
});

final groupMembersProvider =
    FutureProvider.family<List<GroupMembership>, String>((ref, groupId) async {
  final repo = ref.watch(groupsRepositoryProvider);
  return repo.listMembers(groupId);
});

/// Acciones sobre los miembros de un grupo (hoy: promover a capitán).
/// No mantiene estado propio — al mutar, invalida groupMembersProvider
/// para que la lista se refresque sola.
class GroupMembersActions {
  GroupMembersActions(this._ref);

  final Ref _ref;

  Future<void> promoteToAdmin(String groupId, String targetUserId) async {
    final repo = _ref.read(groupsRepositoryProvider);
    await repo.promoteToAdmin(groupId, targetUserId);
    _ref.invalidate(groupMembersProvider(groupId));
  }
}

final groupMembersActionsProvider =
    Provider<GroupMembersActions>((ref) => GroupMembersActions(ref));
