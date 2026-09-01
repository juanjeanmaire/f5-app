import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../players/domain/player.dart';
import '../../players/presentation/players_controller.dart';
import '../domain/match.dart';
import 'matches_controller.dart';

class CreateMatchScreen extends ConsumerStatefulWidget {
  const CreateMatchScreen({
    super.key,
    required this.groupId,
    this.initialTeamAIds,
    this.initialTeamBIds,
  });

  final String groupId;

  /// Si venimos del generador de equipos, ya trae los IDs preseleccionados.
  final List<String>? initialTeamAIds;
  final List<String>? initialTeamBIds;

  @override
  ConsumerState<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends ConsumerState<CreateMatchScreen> {
  MatchType _matchType = MatchType.f5;
  final Set<String> _teamA = {};
  final Set<String> _teamB = {};
  final _scoreAController = TextEditingController(text: '0');
  final _scoreBController = TextEditingController(text: '0');
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTeamAIds != null) _teamA.addAll(widget.initialTeamAIds!);
    if (widget.initialTeamBIds != null) _teamB.addAll(widget.initialTeamBIds!);

    // Si vino un equipo precargado (desde el generador), ajustamos el tipo
    // de partido para que coincida con esa cantidad, si calza con F5/F6/F7.
    if (_teamA.isNotEmpty) {
      final matching = MatchType.values.where((t) => t.teamSize == _teamA.length);
      if (matching.isNotEmpty) _matchType = matching.first;
    }
  }

  @override
  void dispose() {
    _scoreAController.dispose();
    _scoreBController.dispose();
    super.dispose();
  }

  void _togglePlayer(String playerId, {required bool teamA}) {
    setState(() {
      if (teamA) {
        if (_teamA.contains(playerId)) {
          _teamA.remove(playerId);
        } else {
          _teamB.remove(playerId);
          _teamA.add(playerId);
        }
      } else {
        if (_teamB.contains(playerId)) {
          _teamB.remove(playerId);
        } else {
          _teamA.remove(playerId);
          _teamB.add(playerId);
        }
      }
    });
  }

  void _onMatchTypeChanged(MatchType newType) {
    setState(() {
      _matchType = newType;
      final maxSize = newType.teamSize;
      if (_teamA.length > maxSize) {
        _teamA.removeAll(_teamA.toList().sublist(maxSize));
      }
      if (_teamB.length > maxSize) {
        _teamB.removeAll(_teamB.toList().sublist(maxSize));
      }
    });
  }

  Future<void> _submit() async {
    final requiredSize = _matchType.teamSize;
    if (_teamA.length != requiredSize || _teamB.length != requiredSize) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cada equipo necesita exactamente $requiredSize jugadores')),
      );
      return;
    }

    final scoreA = int.tryParse(_scoreAController.text.trim());
    final scoreB = int.tryParse(_scoreBController.text.trim());
    if (scoreA == null || scoreB == null || scoreA < 0 || scoreB < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresá goles válidos (0 o más) para ambos equipos')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(matchesControllerProvider(widget.groupId).notifier).createMatch(
            matchType: _matchType,
            scoreA: scoreA,
            scoreB: scoreB,
            teamAPlayerIds: _teamA.toList(),
            teamBPlayerIds: _teamB.toList(),
          );
      if (!mounted) return;
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersControllerProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('Cargar partido')),
      body: AsyncValueWidget<List<Player>>(
        value: playersAsync,
        data: (allPlayers) {
          final players = allPlayers.where((p) => p.active).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Tipo de partido', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    SegmentedButton<MatchType>(
                      segments: MatchType.values
                          .map((t) => ButtonSegment(value: t, label: Text(t.label)))
                          .toList(),
                      selected: {_matchType},
                      onSelectionChanged: (selection) => _onMatchTypeChanged(selection.first),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _scoreAController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Goles equipo A'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _scoreBController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Goles equipo B'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Equipo A: ${_teamA.length}/${_matchType.teamSize}   '
                      'Equipo B: ${_teamB.length}/${_matchType.teamSize}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: players.isEmpty
                    ? const Center(child: Text('No hay jugadores activos en el grupo'))
                    : ListView.builder(
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          final player = players[index];
                          final inA = _teamA.contains(player.id);
                          final inB = _teamB.contains(player.id);

                          return ListTile(
                            title: Text(player.name),
                            subtitle: Text('ELO ${player.elo.round()}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ChoiceChip(
                                  label: const Text('A'),
                                  selected: inA,
                                  onSelected: (_) => _togglePlayer(player.id, teamA: true),
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text('B'),
                                  selected: inB,
                                  onSelected: (_) => _togglePlayer(player.id, teamA: false),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar partido'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
