import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/auto_refresh.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../groups/presentation/group_detail_controller.dart';
import '../../groups/presentation/groups_controller.dart';
import '../data/match_calls_repository.dart';
import '../domain/match_call.dart';
import 'match_calls_controller.dart';

/// La pantalla de "voy / no voy" — a esta misma pantalla llevaría una
/// notificación push (cuando las tengamos), y también el banner/ribbon
/// de convocatoria abierta dentro de la app.
class MatchCallDetailScreen extends ConsumerWidget {
  const MatchCallDetailScreen({super.key, required this.groupId, required this.callId});

  final String groupId;
  final String callId;

  MatchCallKey get _key => (groupId: groupId, callId: callId);

  Future<void> _respond(BuildContext context, WidgetRef ref, bool going) async {
    try {
      final repo = ref.read(matchCallsRepositoryProvider);
      await repo.respond(groupId, callId, going: going);
      ref.invalidate(matchCallDetailProvider(_key));
      ref.invalidate(activeMatchCallProvider(groupId));
      ref.invalidate(groupsControllerProvider); // refresca el indicador del home
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callAsync = ref.watch(matchCallDetailProvider(_key));
    final currentUserId = ref.watch(authControllerProvider).valueOrNull?.id;
    final groupAsync = ref.watch(groupDetailProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('Convocatoria')),
      body: AutoRefresh(
        onRefresh: () => ref.invalidate(matchCallDetailProvider(_key)),
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(matchCallDetailProvider(_key)),
          child: AsyncValueWidget<MatchCall>(
            value: callAsync,
            onRetry: () => ref.invalidate(matchCallDetailProvider(_key)),
            data: (call) {
              final d = call.date;
              final dateLabel = '${d.day.toString().padLeft(2, '0')}/'
                '${d.month.toString().padLeft(2, '0')}/${d.year} · '
                '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
            final myGoing = call.myResponse(currentUserId);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(call.matchType.label, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 18),
                            const SizedBox(width: 6),
                            Text(dateLabel),
                          ],
                        ),
                        if (call.venueAddress != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 18),
                              const SizedBox(width: 6),
                              Expanded(child: Text(call.venueAddress!)),
                            ],
                          ),
                        ],
                        if (call.comment != null && call.comment!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(call.comment!, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          '${call.goingCount} / ${call.quota} confirmados',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (call.status == MatchCallStatus.open) ...[
                  Text('¿Vas a jugar?', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _respond(context, ref, true),
                          icon: const Icon(Icons.check),
                          label: const Text('VOY'),
                          style: myGoing == true
                              ? null
                              : FilledButton.styleFrom(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.4),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _respond(context, ref, false),
                          icon: const Icon(Icons.close),
                          label: const Text('NO VOY'),
                        ),
                      ),
                    ],
                  ),
                  if (myGoing != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      myGoing ? 'Confirmaste que vas.' : 'Confirmaste que no vas.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ] else if (call.status == MatchCallStatus.closed) ...[
                  Text('Cupo completo — equipos armados', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _TeamColumn(
                          title: groupAsync.valueOrNull?.displayTeamAName ?? 'A',
                          players: call.teamA,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _TeamColumn(
                          title: groupAsync.valueOrNull?.displayTeamBName ?? 'B',
                          players: call.teamB,
                        ),
                      ),
                    ],
                  ),
                ] else
                  const Text('Esta convocatoria fue cancelada.'),
              ],
            );
          },
        ),
      ),
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  const _TeamColumn({required this.title, required this.players});

  final String title;
  final List<MatchCallTeamAssignment> players;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        ...players.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(p.playerName),
          ),
        ),
      ],
    );
  }
}
