import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/league_teams.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/pixel_icon.dart';
import '../../auth/domain/user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../groups/domain/group_membership.dart';
import '../../groups/presentation/groups_controller.dart';
import '../../groups/presentation/widgets/group_list_tile.dart';
import '../data/users_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authControllerProvider.notifier).signOut();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cerrar sesión: ${e.message}')),
      );
    }
  }

  Future<void> _editProfile(BuildContext context, WidgetRef ref, AppUser? user) async {
    final nameController = TextEditingController(text: user?.name ?? '');
    final nicknameController = TextEditingController(text: user?.nickname ?? '');
    final avatarController = TextEditingController(text: user?.avatarUrl ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar perfil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Apodo (opcional)',
                  hintText: 'Aparece como Nombre "Apodo"',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: avatarController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Link a tu foto (opcional)',
                  hintText: 'https://...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (saved != true) return;

    try {
      final repo = ref.read(usersRepositoryProvider);
      await repo.updateProfile(
        name: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
        nickname:
            nicknameController.text.trim().isEmpty ? null : nicknameController.text.trim(),
        avatarUrl: avatarController.text.trim().isEmpty ? null : avatarController.text.trim(),
      );
      ref.invalidate(authControllerProvider);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cambiar contraseña'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña actual'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña nueva'),
                  validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Repetir contraseña nueva'),
                  validator: (v) => v != newController.text ? 'No coincide' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(usersRepositoryProvider);
      await repo.changePassword(
        currentPassword: currentController.text,
        newPassword: newController.text,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Contraseña actualizada')));
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _selectFavoriteTeam(BuildContext context, WidgetRef ref, String? teamId) async {
    try {
      final repo = ref.read(usersRepositoryProvider);
      await repo.updateFavoriteTeam(teamId);
      ref.invalidate(authControllerProvider);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final groupsAsync = ref.watch(groupsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const PixelIcon(PixelIcons.logout, size: 20),
            onPressed: () => _signOut(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(groupsControllerProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundImage:
                        user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                    child: user?.avatarUrl == null
                        ? Text(
                            (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 28),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName ?? '',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  if (user?.email != null)
                    Text(user!.email, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _editProfile(context, ref, user),
                        icon: const PixelIcon(PixelIcons.editOutlined, size: 18),
                        label: const Text('Editar perfil'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _changePassword(context, ref),
                        icon: const PixelIcon(PixelIcons.lockOutline, size: 18),
                        label: const Text('Cambiar contraseña'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String?>(
                    initialValue: user?.favoriteTeamId,
                    decoration: const InputDecoration(
                      labelText: 'Equipo favorito',
                      helperText: 'Cambia el color de acento de toda la app',
                    ),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Sin equipo (dorado)'),
                      ),
                      ...argentineLeagueTeams.map(
                        (team) => DropdownMenuItem<String?>(
                          value: team.id,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: team.primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(team.name),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) => _selectFavoriteTeam(context, ref, value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Mensajes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            AsyncValueWidget<List<GroupMembership>>(
              value: groupsAsync,
              onRetry: () => ref.read(groupsControllerProvider.notifier).refresh(),
              data: (memberships) {
                final captainOf =
                    memberships.where((m) => m.role == GroupRole.admin).toList();
                if (captainOf.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No sos capitán de ningún grupo todavía.'),
                  );
                }
                return Column(
                  children: captainOf.map((m) {
                    return Card(
                      child: ListTile(
                        leading: const PixelIcon(PixelIcons.mailOutline, size: 20),
                        title: Text(m.group?.name ?? 'Tu grupo'),
                        subtitle: const Text('Ver mensajes de los jugadores'),
                        trailing: const PixelIcon(PixelIcons.chevronRight, size: 18),
                        onTap: () => context.push('/groups/${m.groupId}/inbox'),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 32),
            Text('Mis grupos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            AsyncValueWidget<List<GroupMembership>>(
              value: groupsAsync,
              onRetry: () => ref.read(groupsControllerProvider.notifier).refresh(),
              data: (memberships) {
                if (memberships.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Todavía no sos parte de ningún grupo.')),
                  );
                }
                return Column(
                  children: memberships
                      .map((m) => GroupListTile(membership: m))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
