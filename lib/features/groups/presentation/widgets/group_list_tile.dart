import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../shared/widgets/pixel_icon.dart';
import '../../domain/group_membership.dart';
import '../groups_controller.dart';

class GroupListTile extends ConsumerWidget {
  const GroupListTile({super.key, required this.membership});

  final GroupMembership membership;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = membership.group!;
    final captainDisplay = membership.captainDisplayName;
    final myElo = membership.myElo;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/groups/${group.id}', extra: group),
        onLongPress: () => _showLeaveGroupSheet(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                child: Text(group.name.isNotEmpty ? group.name[0].toUpperCase() : '?'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name, style: Theme.of(context).textTheme.titleMedium),
                    if (captainDisplay != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Capitán: $captainDisplay',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (myElo != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      myElo.round().toString(),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text('ELO', style: Theme.of(context).textTheme.bodySmall),
                  ],
                )
              else
                PixelIcon(
                  PixelIcons.chevronRight,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLeaveGroupSheet(BuildContext context, WidgetRef ref) async {
    final group = membership.group!;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const PixelIcon(PixelIcons.exitToApp, size: 20, color: Colors.red),
              title: const Text('Eliminar grupo', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Salís del grupo — no lo borra para los demás'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _confirmLeave(context, ref, group.id, group.name);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLeave(
    BuildContext context,
    WidgetRef ref,
    String groupId,
    String groupName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Salir del grupo?'),
        content: Text(
          'Vas a dejar de ver "$groupName" en tu inicio. Podés volver a unirte '
          'más adelante con el código de invitación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(groupsControllerProvider.notifier).leaveGroup(groupId);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
