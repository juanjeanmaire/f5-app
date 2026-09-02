import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/auto_refresh.dart';
import '../../../shared/widgets/pixel_f5_logo.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/group_membership.dart';
import 'groups_controller.dart';
import 'widgets/group_list_tile.dart';

class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsControllerProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            PixelF5Logo(pixelSize: 3, shadowOffset: 1),
            SizedBox(width: 10),
            Text('Mis grupos'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Crear o unirme a un grupo',
            icon: const Icon(Icons.add, size: 20),
            onPressed: () => _showCreateOrJoinSheet(context),
          ),
        ],
      ),
      body: AutoRefresh(
        interval: const Duration(seconds: 20),
        onRefresh: () => ref.read(groupsControllerProvider.notifier).refresh(),
        child: RefreshIndicator(
          onRefresh: () => ref.read(groupsControllerProvider.notifier).refresh(),
          child: AsyncValueWidget<List<GroupMembership>>(
            value: groupsAsync,
            onRetry: () => ref.read(groupsControllerProvider.notifier).refresh(),
            data: (memberships) {
              if (memberships.isEmpty) {
                return ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 120),
                      child: Column(
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user != null ? '¡Hola, ${user.displayName}!' : '¡Hola!',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          const Text('Todavía no sos parte de ningún grupo.'),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: memberships.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) => GroupListTile(membership: memberships[index]),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showCreateOrJoinSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline, size: 22),
              title: const Text('Crear un grupo nuevo'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.push('/groups/create');
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add_outlined, size: 22),
              title: const Text('Unirme con un código'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.push('/groups/join');
              },
            ),
          ],
        ),
      ),
    );
  }
}
