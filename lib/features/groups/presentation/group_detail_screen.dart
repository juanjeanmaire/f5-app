import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/whatsapp_share.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/groups_repository.dart';
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
            _VenueRibbon(
              venueAddress: groupAsync.valueOrNull?.venueAddress ?? initialGroup?.venueAddress,
              isAdmin: isCurrentUserAdmin,
              onEdit: () => _editVenue(
                context,
                ref,
                groupAsync.valueOrNull?.venueAddress ?? initialGroup?.venueAddress,
              ),
            ),
            const SizedBox(height: 10),
            _ActionRibbon(
              icon: Icons.sports_soccer_outlined,
              label: 'JUGADORES',
              onTap: () => context.push('/groups/$groupId/players', extra: isCurrentUserAdmin),
            ),
            const SizedBox(height: 10),
            _ActionRibbon(
              icon: Icons.event_note_outlined,
              label: 'PARTIDOS',
              onTap: () => context.push('/groups/$groupId/matches', extra: isCurrentUserAdmin),
            ),
            const SizedBox(height: 10),
            _ActionRibbon(
              icon: Icons.shuffle,
              label: 'ARMAR EQUIPOS',
              onTap: () => context.push('/groups/$groupId/team-generator', extra: isCurrentUserAdmin),
            ),
            // Solo el capitán ve (y puede editar) la configuración de ELO
            // del grupo — el resto de los jugadores ni siquiera ve esta opción.
            if (isCurrentUserAdmin) ...[
              const SizedBox(height: 10),
              _ActionRibbon(
                icon: Icons.tune,
                label: 'CONFIGURACIÓN DE ELO',
                onTap: () => context.push('/groups/$groupId/elo-config', extra: isCurrentUserAdmin),
              ),
            ],
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

  Future<void> _editVenue(BuildContext context, WidgetRef ref, String? currentAddress) async {
    final controller = TextEditingController(text: currentAddress ?? '');
    final newAddress = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dirección de la cancha'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Ej: Complejo Deportivo Los Pinos, Av. Siempreviva 742',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (newAddress == null) return; // se canceló el diálogo

    try {
      final repo = ref.read(groupsRepositoryProvider);
      await repo.updateGroup(groupId, venueAddress: newAddress.isEmpty ? null : newAddress);
      ref.invalidate(groupDetailProvider(groupId));
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _ActionRibbon extends StatelessWidget {
  const _ActionRibbon({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: AppColors.gold, width: 4)),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 26),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VenueRibbon extends StatelessWidget {
  const _VenueRibbon({
    required this.venueAddress,
    required this.isAdmin,
    required this.onEdit,
  });

  final String? venueAddress;
  final bool isAdmin;
  final VoidCallback onEdit;

  bool get _hasAddress => venueAddress != null && venueAddress!.isNotEmpty;

  Future<void> _openMaps(BuildContext context) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': venueAddress,
    });
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('No se pudo abrir Google Maps')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: _hasAddress ? () => _openMaps(context) : (isAdmin ? onEdit : null),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: AppColors.gold, width: 4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.gold, size: 26),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CANCHA', style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      _hasAddress
                          ? venueAddress!
                          : (isAdmin ? 'Tocá para definirla' : 'Todavía no está definida'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isAdmin)
                IconButton(
                  tooltip: 'Editar cancha',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                )
              else if (_hasAddress)
                Icon(
                  Icons.open_in_new,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
            ],
          ),
        ),
      ),
    );
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
