import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/whatsapp_share.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/elo_line_chart.dart';
import '../../../shared/widgets/pixel_icon.dart';
import '../../../shared/widgets/pixel_chat_icon.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../matches/domain/match.dart';
import '../../matches/presentation/matches_controller.dart';
import '../../players/domain/player.dart';
import '../../players/data/players_repository.dart';
import '../../players/presentation/players_controller.dart';
import '../data/groups_repository.dart';
import '../domain/group.dart';
import '../domain/group_membership.dart';
import 'group_detail_controller.dart';

/// Últimos N valores de una lista (para "últimos 20 partidos"). Si hay
/// menos, devuelve todos.
List<double> _lastN(List<double> values, int n) =>
    values.length <= n ? values : values.sublist(values.length - n);

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
    final playersAsync = ref.watch(playersControllerProvider(groupId));
    final matchesAsync = ref.watch(matchesControllerProvider(groupId));
    final currentUser = ref.watch(authControllerProvider).valueOrNull;

    final title = groupAsync.valueOrNull?.name ?? initialGroup?.name ?? 'Grupo';
    final inviteCode = groupAsync.valueOrNull?.inviteCode ?? initialGroup?.inviteCode;
    final isCurrentUserAdmin = (membersAsync.valueOrNull ?? []).any(
      (m) => m.userId == currentUser?.id && m.role == GroupRole.admin,
    );

    Player? myPlayer;
    final playersList = playersAsync.valueOrNull;
    if (playersList != null && currentUser != null) {
      for (final p in playersList) {
        if (p.linkedUserId == currentUser.id) {
          myPlayer = p;
          break;
        }
      }
    }

    final eloProgression = (myPlayer != null && matchesAsync.valueOrNull != null)
        ? _lastN(eloProgressionFor(matchesAsync.valueOrNull!, myPlayer.id), 20)
        : const <double>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (inviteCode != null)
            IconButton(
              tooltip: 'Invitar por WhatsApp',
              icon: const PixelChatIcon(pixelSize: 3),
              onPressed: () => _showInviteSheet(context, title, inviteCode),
            ),
          if (isCurrentUserAdmin)
            IconButton(
              tooltip: 'Editar nombre del grupo',
              icon: const PixelIcon(PixelIcons.editOutlined, size: 20),
              onPressed: () => _editGroupName(context, ref, title),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(groupDetailProvider(groupId));
          ref.invalidate(groupMembersProvider(groupId));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _PlayerEloRibbon(
              playerLabel: myPlayer?.name ?? currentUser?.displayName ?? 'Vos',
              hasPlayer: myPlayer != null,
              eloProgression: eloProgression,
              onNavigate: () {
                if (myPlayer != null) {
                  context.push(
                    '/groups/$groupId/players/${myPlayer.id}/matches',
                    extra: myPlayer.name,
                  );
                } else {
                  context.push('/groups/$groupId/players', extra: isCurrentUserAdmin);
                }
              },
            ),
            const SizedBox(height: 10),
            _VenueRibbon(
              venueAddress: groupAsync.valueOrNull?.venueAddress ?? initialGroup?.venueAddress,
              isAdmin: isCurrentUserAdmin,
              onEdit: () => _editVenue(
                context,
                ref,
                groupAsync.valueOrNull?.venueAddress ?? initialGroup?.venueAddress,
              ),
            ),
            if (isCurrentUserAdmin) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _SquareButton(
                      icon: PixelIcons.campaignOutlined,
                      label: 'REALIZAR UNA\nCONVOCATORIA',
                      onTap: () {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(content: Text('Todavía no está disponible')),
                          );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SquareButton(
                      icon: PixelIcons.addCircleOutline,
                      label: 'GENERAR\nPARTIDO',
                      onTap: () => context.push('/groups/$groupId/matches/create'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            _ActionRibbon(
              icon: PixelIcons.eventNoteOutlined,
              label: 'HISTORIAL DE PARTIDOS',
              onTap: () => context.push('/groups/$groupId/matches', extra: isCurrentUserAdmin),
            ),
            const SizedBox(height: 10),
            _ActionRibbon(
              icon: PixelIcons.sportsSoccer,
              label: 'JUGADORES',
              onTap: () => context.push('/groups/$groupId/players', extra: isCurrentUserAdmin),
            ),
            const SizedBox(height: 10),
            _ActionRibbon(
              icon: PixelIcons.shuffle,
              label: 'ARMAR EQUIPOS',
              onTap: () => context.push('/groups/$groupId/team-generator', extra: isCurrentUserAdmin),
            ),
            // Solo el capitán ve (y puede editar) la configuración de ELO
            // del grupo — el resto de los jugadores ni siquiera ve esta opción.
            if (isCurrentUserAdmin) ...[
              const SizedBox(height: 10),
              _ActionRibbon(
                icon: PixelIcons.tune,
                label: 'CONFIGURACIÓN DE ELO',
                onTap: () => context.push('/groups/$groupId/elo-config', extra: isCurrentUserAdmin),
              ),
            ],
            const SizedBox(height: 24),
            if (isCurrentUserAdmin) ...[
              Text('Miembros', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              AsyncValueWidget<List<GroupMembership>>(
                value: membersAsync,
                onRetry: () => ref.invalidate(groupMembersProvider(groupId)),
                data: (members) {
                  final allPlayers = playersAsync.valueOrNull ?? [];
                  return Column(
                    children: members.map((m) {
                      final isAdmin = m.role == GroupRole.admin;
                      final hasLinkedPlayer =
                          allPlayers.any((p) => p.linkedUserId == m.userId);
                      final menuItems = <PopupMenuEntry<String>>[
                        if (!isAdmin)
                          const PopupMenuItem(value: 'promote', child: Text('Hacer capitán')),
                        if (!hasLinkedPlayer)
                          const PopupMenuItem(
                            value: 'assign',
                            child: Text('Adjudicar jugador viejo'),
                          ),
                      ];

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              (m.user?.name.isNotEmpty ?? false)
                                  ? m.user!.name[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(m.user?.displayName ?? m.userId),
                          subtitle: Text(m.role.label),
                          trailing: menuItems.isEmpty
                              ? (isAdmin ? const PixelIcon(PixelIcons.shield, size: 20) : null)
                              : PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'promote') _promote(context, ref, m.userId);
                                    if (value == 'assign') {
                                      _assignPlayer(
                                        context,
                                        ref,
                                        m.userId,
                                        m.user?.displayName ?? m.userId,
                                        allPlayers,
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => menuItems,
                                ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ] else ...[
              Text('Capitán', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              AsyncValueWidget<List<GroupMembership>>(
                value: membersAsync,
                onRetry: () => ref.invalidate(groupMembersProvider(groupId)),
                data: (members) {
                  final captains = members.where((m) => m.role == GroupRole.admin).toList();
                  if (captains.isEmpty) {
                    return const Text('No se encontró un capitán para este grupo.');
                  }
                  final captain = captains.first;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          (captain.user?.name.isNotEmpty ?? false)
                              ? captain.user!.name[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(captain.user?.displayName ?? captain.userId),
                      subtitle: const Text('Capitán'),
                      trailing: const PixelIcon(PixelIcons.chatBubbleOutline, size: 20),
                      onTap: () => context.push('/groups/$groupId/message-captain'),
                    ),
                  );
                },
              ),
            ],
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

  /// El capitán le adjudica un jugador viejo (sin cuenta vinculada) a un
  /// miembro puntual — típicamente alguien que se acaba de unir por
  /// invitación y ya tenía historial de antes.
  Future<void> _assignPlayer(
    BuildContext context,
    WidgetRef ref,
    String targetUserId,
    String targetLabel,
    List<Player> allPlayers,
  ) async {
    final candidates = allPlayers.where((p) => p.linkedUserId == null).toList();

    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay jugadores sin cuenta vinculada en este grupo.')),
      );
      return;
    }

    Player? selected;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text('¿Qué jugador viejo es $targetLabel?'),
          content: DropdownButtonFormField<Player>(
            initialValue: selected,
            hint: const Text('Elegí un jugador'),
            isExpanded: true,
            items: candidates
                .map(
                  (p) => DropdownMenuItem(
                    value: p,
                    child: Text('${p.name} (ELO ${p.elo.round()})'),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => selected = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: selected == null
                  ? null
                  : () => Navigator.of(dialogContext).pop(true),
              child: const Text('Adjudicar'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || selected == null || !context.mounted) return;

    try {
      final repo = ref.read(playersRepositoryProvider);
      await repo.assignPlayer(groupId, selected!.id, targetUserId);
      ref.invalidate(playersControllerProvider(groupId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${selected!.name}" adjudicado a $targetLabel')),
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _editGroupName(BuildContext context, WidgetRef ref, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nombre del grupo'),
        content: TextField(controller: controller, autofocus: true),
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

    if (newName == null || newName.isEmpty || newName == currentName) return;

    try {
      final repo = ref.read(groupsRepositoryProvider);
      await repo.updateGroupName(groupId, newName);
      ref.invalidate(groupDetailProvider(groupId));
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _editVenue(BuildContext context, WidgetRef ref, String? currentAddress) async {
    final newAddress = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _VenueAddressDialog(initialAddress: currentAddress),
    );

    if (newAddress == null) return; // se canceló el diálogo

    try {
      final repo = ref.read(groupsRepositoryProvider);
      await repo.updateGroupVenue(groupId, venueAddress: newAddress.isEmpty ? null : newAddress);
      ref.invalidate(groupDetailProvider(groupId));
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _showInviteSheet(
    BuildContext context,
    String groupName,
    String inviteCode,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Código de invitación', style: Theme.of(sheetContext).textTheme.labelMedium),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      inviteCode,
                      style: Theme.of(sheetContext)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(letterSpacing: 4),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copiar código',
                    icon: const PixelIcon(PixelIcons.copyOutlined, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: inviteCode));
                      ScaffoldMessenger.of(sheetContext)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(const SnackBar(content: Text('Código copiado')));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  final message = '¡Sumate a nuestro grupo "$groupName" en F5 App! ⚽\n\n'
                      'Bajate la app y usá este código para unirte: $inviteCode';
                  final opened = await shareViaWhatsApp(message);
                  if (!opened && sheetContext.mounted) {
                    ScaffoldMessenger.of(sheetContext)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(const SnackBar(content: Text('No se pudo abrir WhatsApp')));
                  }
                },
                icon: const PixelChatIcon(pixelSize: 2.5),
                label: const Text('Compartir por WhatsApp'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRibbon extends StatelessWidget {
  const _ActionRibbon({required this.icon, required this.label, required this.onTap});

  final List<List<int>> icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: accent, width: 4)),
          ),
          child: Row(
            children: [
              PixelIcon(icon, color: accent, size: 26),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              PixelIcon(
                PixelIcons.chevronRight,
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

class _SquareButton extends StatelessWidget {
  const _SquareButton({required this.icon, required this.label, required this.onTap});

  final List<List<int>> icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PixelIcon(icon, size: 30, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Primer banner de la pantalla: título con el nombre del jugador, gráfico
/// de su evolución de ELO (últimos 20 partidos). Tocarlo lo expande al
/// doble de alto en el lugar; "Ver historial completo" navega a la
/// pantalla con el detalle de todos sus partidos.
class _PlayerEloRibbon extends StatefulWidget {
  const _PlayerEloRibbon({
    required this.playerLabel,
    required this.hasPlayer,
    required this.eloProgression,
    required this.onNavigate,
  });

  final String playerLabel;
  final bool hasPlayer;
  final List<double> eloProgression;
  final VoidCallback onNavigate;

  @override
  State<_PlayerEloRibbon> createState() => _PlayerEloRibbonState();
}

class _PlayerEloRibbonState extends State<_PlayerEloRibbon> {
  bool _expanded = false;

  static const _compactHeight = 60.0;
  static const _expandedHeight = 130.0;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          if (!widget.hasPlayer) {
            widget.onNavigate();
            return;
          }
          setState(() => _expanded = !_expanded);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: accent, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PixelIcon(PixelIcons.showChart, color: accent, size: 26),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(widget.playerLabel, style: Theme.of(context).textTheme.titleMedium),
                  ),
                  PixelIcon(
                    widget.hasPlayer
                        ? (_expanded ? PixelIcons.expandLess : PixelIcons.expandMore)
                        : PixelIcons.chevronRight,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
              if (!widget.hasPlayer)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Reclamá tu jugador para ver tu evolución de ELO',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: EloLineChart(
                    values: widget.eloProgression,
                    compact: !_expanded,
                    height: _expanded ? _expandedHeight : _compactHeight,
                  ),
                ),
                if (_expanded)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: widget.onNavigate,
                      child: const Text('Ver historial completo'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Segundo banner: la cancha. Tocarlo lo expande al doble para mostrar un
/// mapa embebido (OpenStreetMap, sin API key) con la dirección cargada.
/// Diálogo para escribir la dirección de la cancha, con sugerencias en
/// vivo (Nominatim/OpenStreetMap — el mismo servicio que usa el mapa
/// embebido, sin necesitar API key). Si la búsqueda falla por lo que sea,
/// el capitán igual puede escribir la dirección a mano y guardarla tal cual.
class _VenueAddressDialog extends StatefulWidget {
  const _VenueAddressDialog({this.initialAddress});

  final String? initialAddress;

  @override
  State<_VenueAddressDialog> createState() => _VenueAddressDialogState();
}

class _VenueAddressDialogState extends State<_VenueAddressDialog> {
  late final TextEditingController _controller;
  Timer? _debounce;
  List<String> _suggestions = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAddress ?? '');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    // Esperamos un toque después de que dejó de tipear, para no
    // bombardear la API con un pedido por cada letra.
    _debounce = Timer(const Duration(milliseconds: 600), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {'q': query, 'format': 'jsonv2', 'limit': '5'},
        options: Options(
          headers: {'User-Agent': 'F5App/1.0 (contacto: juangjeanmaire@gmail.com)'},
        ),
      );
      final results = (response.data as List)
          .map((e) => (e as Map<String, dynamic>)['display_name'] as String)
          .toList();
      if (mounted) setState(() => _suggestions = results);
    } catch (_) {
      // Silencioso a propósito: si falla la búsqueda, el capitán igual
      // puede escribir la dirección a mano y guardarla tal cual.
      if (mounted) setState(() => _suggestions = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dirección de la cancha'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 2,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Ej: Complejo Deportivo Los Pinos, Av. Siempreviva 742',
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),
            if (_suggestions.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) => ListTile(
                    dense: true,
                    leading: const PixelIcon(PixelIcons.locationOnOutlined, size: 18),
                    title: Text(
                      _suggestions[index],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onTap: () {
                      _controller.text = _suggestions[index];
                      setState(() => _suggestions = []);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _VenueRibbon extends StatefulWidget {
  const _VenueRibbon({
    required this.venueAddress,
    required this.isAdmin,
    required this.onEdit,
  });

  final String? venueAddress;
  final bool isAdmin;
  final VoidCallback onEdit;

  @override
  State<_VenueRibbon> createState() => _VenueRibbonState();
}

class _VenueRibbonState extends State<_VenueRibbon> {
  bool _expanded = false;
  bool _mapLoading = false;
  WebViewController? _controller;
  String? _loadedForAddress;

  bool get _hasAddress => widget.venueAddress != null && widget.venueAddress!.isNotEmpty;

  /// Ubica la dirección primero (mismo servicio que las sugerencias del
  /// editor) y carga el mapa minimalista de OpenStreetMap centrado ahí,
  /// en vez de la página completa de búsqueda — así se siente parte de
  /// la app en vez de un sitio externo con su propio menú.
  Future<void> _loadMap() async {
    if (!_hasAddress) return;
    if (_controller != null && _loadedForAddress == widget.venueAddress) return;

    setState(() => _mapLoading = true);

    final address = widget.venueAddress!;
    String targetUrl;
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {'q': address, 'format': 'jsonv2', 'limit': '1'},
        options: Options(
          headers: {'User-Agent': 'F5App/1.0 (contacto: juangjeanmaire@gmail.com)'},
        ),
      );
      final results = response.data as List;
      if (results.isNotEmpty) {
        final first = results.first as Map<String, dynamic>;
        final lat = double.parse(first['lat'] as String);
        final lon = double.parse(first['lon'] as String);
        const delta = 0.006; // recorte chico alrededor del punto (~600m)
        final bbox = '${lon - delta},${lat - delta},${lon + delta},${lat + delta}';
        targetUrl =
            'https://www.openstreetmap.org/export/embed.html?bbox=$bbox&layer=mapnik&marker=$lat,$lon';
      } else {
        // No se pudo ubicar exacto — mostramos la búsqueda como respaldo.
        targetUrl = 'https://www.openstreetmap.org/search?query=${Uri.encodeComponent(address)}';
      }
    } catch (_) {
      targetUrl = 'https://www.openstreetmap.org/search?query=${Uri.encodeComponent(address)}';
    }

    if (!mounted) return;
    setState(() {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(targetUrl));
      _loadedForAddress = address;
      _mapLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              if (!_hasAddress) {
                if (widget.isAdmin) widget.onEdit();
                return;
              }
              setState(() => _expanded = !_expanded);
              if (_expanded) _loadMap();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: accent, width: 4)),
              ),
              child: Row(
                children: [
                  PixelIcon(PixelIcons.locationOnOutlined, color: accent, size: 26),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CANCHA', style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          _hasAddress
                              ? widget.venueAddress!
                              : (widget.isAdmin
                                  ? 'Tocá para definirla'
                                  : 'Todavía no está definida'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (widget.isAdmin)
                    IconButton(
                      tooltip: 'Editar cancha',
                      icon: const PixelIcon(PixelIcons.editOutlined, size: 20),
                      onPressed: widget.onEdit,
                    )
                  else if (_hasAddress)
                    PixelIcon(
                      _expanded ? PixelIcons.expandLess : PixelIcons.expandMore,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                ],
              ),
            ),
          ),
          if (_expanded && _hasAddress)
            SizedBox(
              height: 240,
              child: _mapLoading || _controller == null
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : WebViewWidget(controller: _controller!),
            ),
        ],
      ),
    );
  }
}
