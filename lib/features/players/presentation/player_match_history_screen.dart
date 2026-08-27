import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/async_value_widget.dart';
import '../../matches/domain/match.dart';
import '../../matches/presentation/matches_controller.dart';
import '../../matches/presentation/widgets/team_elo_summary_row.dart';
import '../domain/player.dart';
import 'players_controller.dart';

Player? _findPlayer(List<Player>? players, String id) {
  if (players == null) return null;
  for (final p in players) {
    if (p.id == id) return p;
  }
  return null;
}

class PlayerMatchHistoryScreen extends ConsumerWidget {
  const PlayerMatchHistoryScreen({
    super.key,
    required this.groupId,
    required this.playerId,
    this.playerName,
  });

  final String groupId;
  final String playerId;

  /// Nombre pasado por navegación, para el título mientras carga el pool.
  final String? playerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesControllerProvider(groupId));
    final playersAsync = ref.watch(playersControllerProvider(groupId));

    final player = _findPlayer(playersAsync.valueOrNull, playerId);
    final title = player?.name ?? playerName ?? 'Jugador';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: RefreshIndicator(
        onRefresh: () => ref.read(matchesControllerProvider(groupId).notifier).refresh(),
        child: AsyncValueWidget<List<Match>>(
          value: matchesAsync,
          onRetry: () => ref.read(matchesControllerProvider(groupId).notifier).refresh(),
          data: (allMatches) {
            final matches = allMatches
                .where((m) => m.teamPlayers.any((tp) => tp.playerId == playerId))
                .toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (player != null)
                  _PlayerSummaryCard(player: player, matchCount: matches.length),
                const SizedBox(height: 16),
                if (matches.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(
                      child: Text('Este jugador todavía no jugó ningún partido.'),
                    ),
                  )
                else
                  ...matches.map((m) => _PlayerMatchTile(match: m, playerId: playerId)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PlayerSummaryCard extends StatelessWidget {
  const _PlayerSummaryCard({required this.player, required this.matchCount});

  final Player player;
  final int matchCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(player.name.isNotEmpty ? player.name[0].toUpperCase() : '?'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(player.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'ELO actual: ${player.elo.round()} · $matchCount '
                    '${matchCount == 1 ? 'partido' : 'partidos'}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerMatchTile extends StatelessWidget {
  const _PlayerMatchTile({required this.match, required this.playerId});

  final Match match;
  final String playerId;

  @override
  Widget build(BuildContext context) {
    final entry = match.teamPlayers.firstWhere((tp) => tp.playerId == playerId);
    final d = match.date;
    final dateLabel =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final teamLabel = entry.team == TeamSide.a ? 'Equipo A' : 'Equipo B';
    final deltaColor = entry.eloDelta >= 0 ? Colors.green.shade700 : Colors.red.shade700;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('${match.matchType.label} · $dateLabel'),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$teamLabel · Resultado ${match.scoreA} - ${match.scoreB}'),
              const SizedBox(height: 4),
              TeamEloSummaryRow(match: match),
            ],
          ),
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.eloDelta >= 0 ? '+' : ''}${entry.eloDelta.round()}',
              style: TextStyle(color: deltaColor, fontWeight: FontWeight.bold),
            ),
            Text(
              '${entry.eloBefore.round()} → ${entry.eloAfter.round()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
