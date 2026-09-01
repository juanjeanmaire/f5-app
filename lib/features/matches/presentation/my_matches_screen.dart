import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/async_value_widget.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/my_matches_repository.dart';
import '../domain/match.dart';
import 'widgets/team_elo_summary_row.dart';

/// El log de todos los partidos del usuario, en todos los grupos de los
/// que participa — a diferencia de MatchHistoryScreen (que está scoped a
/// un solo grupo), esta pantalla junta todo.
class MyMatchesScreen extends ConsumerWidget {
  const MyMatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(myMatchesProvider);
    final currentUserId = ref.watch(authControllerProvider).valueOrNull?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis partidos')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myMatchesProvider),
        child: AsyncValueWidget<List<Match>>(
          value: matchesAsync,
          onRetry: () => ref.invalidate(myMatchesProvider),
          data: (matches) {
            if (matches.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.only(top: 120),
                    child: Center(
                      child: Text(
                        'Todavía no jugaste ningún partido en ninguno de tus grupos.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: matches.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Todos tus partidos, en todos tus grupos',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }
                return _MyMatchCard(
                  match: matches[index - 1],
                  currentUserId: currentUserId,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MyMatchCard extends StatelessWidget {
  const _MyMatchCard({required this.match, required this.currentUserId});

  final Match match;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final d = match.date;
    final dateLabel =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    MatchTeamPlayer? mine;
    for (final tp in match.teamPlayers) {
      if (tp.linkedUserId == currentUserId) {
        mine = tp;
        break;
      }
    }
    final deltaColor = (mine?.eloDelta ?? 0) >= 0 ? Colors.green.shade700 : Colors.red.shade700;

    return Card(
      child: ExpansionTile(
        title: Text(match.groupName ?? 'Grupo'),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${match.matchType.label} · $dateLabel'),
              Text('Resultado: ${match.scoreA} - ${match.scoreB}'),
              const SizedBox(height: 4),
              TeamEloSummaryRow(match: match, teamAName: match.displayTeamAName, teamBName: match.displayTeamBName),
            ],
          ),
        ),
        trailing: mine != null
            ? Text(
                '${mine.eloDelta >= 0 ? '+' : ''}${mine.eloDelta.round()}',
                style: TextStyle(color: deltaColor, fontWeight: FontWeight.bold),
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _TeamColumn(title: match.displayTeamAName, players: match.teamA)),
                const SizedBox(width: 16),
                Expanded(child: _TeamColumn(title: match.displayTeamBName, players: match.teamB)),
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
