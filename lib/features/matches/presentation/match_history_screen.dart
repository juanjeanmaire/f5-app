import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../domain/match.dart';
import 'matches_controller.dart';
import 'widgets/team_elo_summary_row.dart';

class MatchHistoryScreen extends ConsumerWidget {
  const MatchHistoryScreen({super.key, required this.groupId, required this.isAdmin});

  final String groupId;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesControllerProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('Partidos')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(matchesControllerProvider(groupId).notifier).refresh(),
        child: AsyncValueWidget<List<Match>>(
          value: matchesAsync,
          onRetry: () => ref.read(matchesControllerProvider(groupId).notifier).refresh(),
          data: (matches) {
            if (matches.isEmpty) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 120),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_note_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        const Text('Todavía no se cargó ningún partido.'),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _MatchCard(
                match: matches[index],
                groupId: groupId,
                isAdmin: isAdmin,
              ),
            );
          },
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/groups/$groupId/matches/create'),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Partido'),
            )
          : null,
    );
  }
}

class _MatchCard extends ConsumerWidget {
  const _MatchCard({required this.match, required this.groupId, required this.isAdmin});

  final Match match;
  final String groupId;
  final bool isAdmin;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Borrar este partido?'),
        content: const Text(
          'Se revierte el ELO que este partido les sumó o restó a los jugadores. '
          'Esto es exacto solo si es el partido más reciente de cada uno — '
          'si alguno jugó partidos después de este, mejor borrá primero esos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(matchesControllerProvider(groupId).notifier).deleteMatch(match.id);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = match.date;
    final dateLabel =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    return Card(
      child: ExpansionTile(
        title: Text('${match.matchType.label} · $dateLabel'),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resultado: ${match.scoreA} - ${match.scoreB}'),
              const SizedBox(height: 4),
              TeamEloSummaryRow(match: match),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _TeamColumn(title: 'Equipo A', players: match.teamA)),
                    const SizedBox(width: 16),
                    Expanded(child: _TeamColumn(title: 'Equipo B', players: match.teamB)),
                  ],
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _confirmDelete(context, ref),
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      label: const Text('Borrar partido', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  const _TeamColumn({required this.title, required this.players});

  final String title;
  final List<MatchTeamPlayer> players;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        ...players.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${p.playerName ?? p.playerId} '
              '(${p.eloDelta >= 0 ? '+' : ''}${p.eloDelta.round()})',
              style: TextStyle(
                color: p.eloDelta >= 0 ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
