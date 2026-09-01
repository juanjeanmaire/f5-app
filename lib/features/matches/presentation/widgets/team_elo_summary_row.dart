import 'package:flutter/material.dart';

import '../../domain/match.dart';

/// Muestra, para un partido, el ELO promedio de cada equipo (el nivel con
/// el que se enfrentaron) y cuántos puntos ganó/perdió cada uno en promedio.
class TeamEloSummaryRow extends StatelessWidget {
  const TeamEloSummaryRow({
    super.key,
    required this.match,
    this.teamAName = 'Equipo A',
    this.teamBName = 'Equipo B',
  });

  final Match match;
  final String teamAName;
  final String teamBName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TeamBadge(
            label: teamAName,
            avgElo: match.avgEloTeamA,
            avgDelta: match.avgDeltaTeamA,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TeamBadge(
            label: teamBName,
            avgElo: match.avgEloTeamB,
            avgDelta: match.avgDeltaTeamB,
          ),
        ),
      ],
    );
  }
}

class _TeamBadge extends StatelessWidget {
  const _TeamBadge({required this.label, required this.avgElo, required this.avgDelta});

  final String label;
  final double avgElo;
  final double avgDelta;

  @override
  Widget build(BuildContext context) {
    final deltaColor = avgDelta >= 0 ? Colors.green.shade700 : Colors.red.shade700;
    final deltaText = '${avgDelta >= 0 ? '+' : ''}${avgDelta.round()}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            '$label · ELO ${avgElo.round()}',
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          deltaText,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: deltaColor, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
