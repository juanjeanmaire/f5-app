import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../players/domain/player.dart';
import '../../players/presentation/players_controller.dart';
import '../data/team_generator_repository.dart';
import '../domain/team_generation_result.dart';

class TeamGeneratorScreen extends ConsumerStatefulWidget {
  const TeamGeneratorScreen({super.key, required this.groupId, required this.isAdmin});

  final String groupId;
  final bool isAdmin;

  @override
  ConsumerState<TeamGeneratorScreen> createState() => _TeamGeneratorScreenState();
}

class _TeamGeneratorScreenState extends ConsumerState<TeamGeneratorScreen> {
  final Set<String> _selected = {};
  bool _generating = false;
  TeamGenerationResult? _result;

  Future<void> _generate() async {
    if (_selected.length < 2 || _selected.length.isOdd) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elegí una cantidad par de jugadores (mínimo 2)')),
      );
      return;
    }

    setState(() {
      _generating = true;
      _result = null;
    });

    try {
      final repo = ref.read(teamGeneratorRepositoryProvider);
      final result = await repo.generate(widget.groupId, _selected.toList());
      if (!mounted) return;
      setState(() => _result = result);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _loadMatchWithResult() {
    final result = _result;
    if (result == null) return;
    context.push(
      '/groups/${widget.groupId}/matches/create',
      extra: {
        'teamAIds': result.teamA.map((p) => p.playerId).toList(),
        'teamBIds': result.teamB.map((p) => p.playerId).toList(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersControllerProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('Armar equipos')),
      body: AsyncValueWidget<List<Player>>(
        value: playersAsync,
        data: (allPlayers) {
          final players = allPlayers.where((p) => p.active).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Elegí quiénes están disponibles hoy. Se arman dos equipos '
                  'parejos según el ELO de cada uno.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Expanded(
                child: players.isEmpty
                    ? const Center(child: Text('No hay jugadores activos en el grupo'))
                    : ListView.builder(
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          final player = players[index];
                          final selected = _selected.contains(player.id);
                          return CheckboxListTile(
                            value: selected,
                            onChanged: (value) {
                              setState(() {
                                if (value ?? false) {
                                  _selected.add(player.id);
                                } else {
                                  _selected.remove(player.id);
                                }
                              });
                            },
                            title: Text(player.name),
                            subtitle: Text('ELO ${player.elo.round()}'),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _generating ? null : _generate,
                    icon: _generating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.shuffle),
                    label: Text('Generar equipos (${_selected.length} seleccionados)'),
                  ),
                ),
              ),
              if (_result != null)
                _ResultSection(
                  result: _result!,
                  isAdmin: widget.isAdmin,
                  onLoadMatch: _loadMatchWithResult,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.result,
    required this.isAdmin,
    required this.onLoadMatch,
  });

  final TeamGenerationResult result;
  final bool isAdmin;
  final VoidCallback onLoadMatch;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Diferencia de ELO entre equipos: ${result.diff.round()}'
            '${result.method == 'heuristic' ? ' (aproximado)' : ''}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TeamResultColumn(
                  title: 'Equipo A',
                  sumElo: result.sumEloA,
                  players: result.teamA,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TeamResultColumn(
                  title: 'Equipo B',
                  sumElo: result.sumEloB,
                  players: result.teamB,
                ),
              ),
            ],
          ),
          if (isAdmin) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onLoadMatch,
              icon: const Icon(Icons.sports_soccer),
              label: const Text('Cargar este partido'),
            ),
          ],
        ],
      ),
    );
  }
}

class _TeamResultColumn extends StatelessWidget {
  const _TeamResultColumn({
    required this.title,
    required this.sumElo,
    required this.players,
  });

  final String title;
  final double sumElo;
  final List<TeamGenPlayer> players;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (ELO total ${sumElo.round()})',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        ...players.map((p) => Text('${p.name} (${p.elo.round()})')),
      ],
    );
  }
}
