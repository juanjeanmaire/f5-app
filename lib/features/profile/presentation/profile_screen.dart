import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../groups/domain/group_membership.dart';
import '../../groups/presentation/groups_controller.dart';
import '../../groups/presentation/widgets/group_list_tile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authControllerProvider.notifier).signOut();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cerrar sesión: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final groupsAsync = ref.watch(groupsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(groupsControllerProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundImage:
                        user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                    child: user?.avatarUrl == null
                        ? Text(
                            (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 28),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(user?.name ?? '', style: Theme.of(context).textTheme.titleLarge),
                  if (user?.email != null)
                    Text(user!.email, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Mensajes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            AsyncValueWidget<List<GroupMembership>>(
              value: groupsAsync,
              onRetry: () => ref.read(groupsControllerProvider.notifier).refresh(),
              data: (memberships) {
                final captainOf =
                    memberships.where((m) => m.role == GroupRole.admin).toList();
                if (captainOf.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No sos capitán de ningún grupo todavía.'),
                  );
                }
                return Column(
                  children: captainOf.map((m) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.mail_outline),
                        title: Text(m.group?.name ?? 'Tu grupo'),
                        subtitle: const Text('Ver mensajes de los jugadores'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/groups/${m.groupId}/inbox'),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 32),
            Text('Mis grupos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            AsyncValueWidget<List<GroupMembership>>(
              value: groupsAsync,
              onRetry: () => ref.read(groupsControllerProvider.notifier).refresh(),
              data: (memberships) {
                if (memberships.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Todavía no sos parte de ningún grupo.')),
                  );
                }
                return Column(
                  children: memberships
                      .map((m) => GroupListTile(membership: m))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
