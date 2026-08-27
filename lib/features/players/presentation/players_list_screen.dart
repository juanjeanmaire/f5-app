import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../domain/player.dart';
import 'players_controller.dart';

class PlayersListScreen extends ConsumerWidget {
  const PlayersListScreen({super.key, required this.groupId, required this.isAdmin});

  final String groupId;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(playersControllerProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('Jugadores')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(playersControllerProvider(groupId).notifier).refresh(),
        child: AsyncValueWidget<List<Player>>(
          value: playersAsync,
          onRetry: () => ref.read(playersControllerProvider(groupId).notifier).refresh(),
          data: (players) {
            if (players.isEmpty) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 120),
                    child: Column(
                      children: [
                        Icon(
                          Icons.sports_soccer,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        const Text('Todavía no hay jugadores cargados.'),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: players.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _PlayerTile(
                player: players[index],
                groupId: groupId,
                isAdmin: isAdmin,
                rank: index + 1,
              ),
            );
          },
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showAddPlayerDialog(context, ref),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Jugador'),
            )
          : null,
    );
  }

  void _showAddPlayerDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nuevo jugador'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre'),
          onSubmitted: (_) => _submitAddPlayer(context, dialogContext, ref, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => _submitAddPlayer(context, dialogContext, ref, controller.text),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAddPlayer(
    BuildContext screenContext,
    BuildContext dialogContext,
    WidgetRef ref,
    String rawName,
  ) async {
    final name = rawName.trim();
    if (name.length < 2) return;

    Navigator.of(dialogContext).pop();
    try {
      await ref.read(playersControllerProvider(groupId).notifier).createPlayer(name);
    } on ApiException catch (e) {
      if (!screenContext.mounted) return;
      ScaffoldMessenger.of(screenContext).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _PlayerTile extends ConsumerWidget {
  const _PlayerTile({
    required this.player,
    required this.groupId,
    required this.isAdmin,
    required this.rank,
  });

  final Player player;
  final String groupId;
  final bool isAdmin;
  final int rank;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canClaim = player.linkedUserId == null;

    return Opacity(
      opacity: player.active ? 1 : 0.5,
      child: Card(
        child: ListTile(
          onTap: () => context.push(
            '/groups/$groupId/players/${player.id}/matches',
            extra: player.name,
          ),
          leading: CircleAvatar(child: Text('$rank')),
          title: Text(player.name),
          subtitle: Text(
            'ELO ${player.elo.round()} · ${player.matchesPlayed} '
            '${player.matchesPlayed == 1 ? 'partido' : 'partidos'}'
            '${player.active ? '' : ' · Inactivo'}',
          ),
          trailing: isAdmin
              ? PopupMenuButton<String>(
                  onSelected: (value) => _handleAdminAction(context, ref, value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'rename', child: Text('Renombrar')),
                    PopupMenuItem(
                      value: 'toggle_active',
                      child: Text(player.active ? 'Desactivar' : 'Reactivar'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Borrar')),
                  ],
                )
              : (canClaim
                  ? TextButton(
                      onPressed: () => _claim(context, ref),
                      child: const Text('Reclamar'),
                    )
                  : null),
        ),
      ),
    );
  }

  Future<void> _handleAdminAction(BuildContext context, WidgetRef ref, String action) async {
    final notifier = ref.read(playersControllerProvider(groupId).notifier);
    try {
      switch (action) {
        case 'rename':
          final newName = await _promptRename(context);
          if (newName != null && newName.trim().isNotEmpty) {
            await notifier.updatePlayer(player.id, name: newName.trim());
          }
          break;
        case 'toggle_active':
          await notifier.updatePlayer(player.id, active: !player.active);
          break;
        case 'delete':
          await notifier.deletePlayer(player.id);
          break;
      }
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<String?> _promptRename(BuildContext context) {
    final controller = TextEditingController(text: player.name);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Renombrar jugador'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _claim(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(playersControllerProvider(groupId).notifier).claimPlayer(player.id);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
