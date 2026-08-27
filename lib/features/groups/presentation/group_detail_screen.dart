import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/utils/whatsapp_share.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/group.dart';
import '../domain/group_membership.dart';
import 'group_detail_controller.dart';

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key, required this.groupId, this.initialGroup});

  final String groupId;

  /// Si venimos de la lista, de crear, o de unirnos, ya tenemos el Group en
  /// memoria — lo usamos para mostrar el título al instante sin esperar el
  /// fetch. Si es null (ej. deep link directo), se resuelve con groupDetailProvider.
  final Group? initialGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupDetailProvider(groupId));
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final currentUserId = ref.watch(authControllerProvider).valueOrNull?.id;

    final title = groupAsync.valueOrNull?.name ?? initialGroup?.name ?? 'Grupo';
    final inviteCode = groupAsync.valueOrNull?.inviteCode ?? initialGroup?.inviteCode;
    final isCurrentUserAdmin = (membersAsync.valueOrNull ?? []).any(
      (m) => m.userId == currentUserId && m.role == GroupRole.admin,
    );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(groupDetailProvider(groupId));
          ref.invalidate(groupMembersProvider(groupId));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (inviteCode != null) _InviteCodeCard(groupName: title, inviteCode: inviteCode),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.sports_soccer_outlined),
                title: const Text('Jugadores'),
                subtitle: const Text('Ver el pool y su ELO'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(
                  '/groups/$groupId/players',
                  extra: isCurrentUserAdmin,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.event_note_outlined),
                title: const Text('Partidos'),
                subtitle: const Text('Historial y carga de partidos'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(
                  '/groups/$groupId/matches',
                  extra: isCurrentUserAdmin,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.shuffle),
                title: const Text('Armar equipos'),
                subtitle: const Text('Generar equipos parejos según ELO'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(
                  '/groups/$groupId/team-generator',
                  extra: isCurrentUserAdmin,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('Configuración de ELO'),
                subtitle: const Text('Cómo se calcula el ELO en este grupo'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(
                  '/groups/$groupId/elo-config',
                  extra: isCurrentUserAdmin,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Miembros', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            AsyncValueWidget<List<GroupMembership>>(
              value: membersAsync,
              onRetry: () => ref.invalidate(groupMembersProvider(groupId)),
              data: (members) {
                return Column(
                  children: members.map((m) {
                    final isAdmin = m.role == GroupRole.admin;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            (m.user?.name.isNotEmpty ?? false)
                                ? m.user!.name[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(m.user?.name ?? m.userId),
                        subtitle: Text(m.role.label),
                        trailing: (isCurrentUserAdmin && !isAdmin)
                            ? TextButton(
                                onPressed: () => _promote(context, ref, m.userId),
                                child: const Text('Hacer capitán'),
                              )
                            : (isAdmin ? const Icon(Icons.shield, size: 20) : null),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _promote(BuildContext context, WidgetRef ref, String targetUserId) async {
    try {
      await ref.read(groupMembersActionsProvider).promoteToAdmin(groupId, targetUserId);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({required this.groupName, required this.inviteCode});

  final String groupName;
  final String inviteCode;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Código de invitación', style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 4),
                      Text(
                        inviteCode,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(letterSpacing: 4),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Copiar código',
                  icon: const Icon(Icons.copy_outlined),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: inviteCode));
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(const SnackBar(content: Text('Código copiado')));
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _inviteViaWhatsApp(context),
              icon: const Icon(Icons.chat_outlined),
              label: const Text('Invitar por WhatsApp'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _inviteViaWhatsApp(BuildContext context) async {
    final message = '¡Sumate a nuestro grupo "$groupName" en F5 App! ⚽\n\n'
        'Bajate la app y usá este código para unirte: $inviteCode';

    final opened = await shareViaWhatsApp(message);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('No se pudo abrir WhatsApp')));
    }
  }
}
