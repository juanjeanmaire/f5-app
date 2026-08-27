import 'group.dart';

/// En la UI mostramos "Capitán" en vez de "Admin" (ver nota en el
/// backend: GroupRole.ADMIN es, funcionalmente, el capitán del grupo).
enum GroupRole {
  admin,
  member;

  static GroupRole fromJson(String value) =>
      value == 'ADMIN' ? GroupRole.admin : GroupRole.member;

  String get label => this == GroupRole.admin ? 'Capitán' : 'Miembro';
}

/// Datos básicos de un usuario, tal como los devuelve el backend
/// cuando incluye `user` en una membership (GET /groups/:id/members).
class MemberInfo {
  const MemberInfo({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;

  factory MemberInfo.fromJson(Map<String, dynamic> json) => MemberInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        avatarUrl: json['avatarUrl'] as String?,
      );
}

/// Representa una fila de GroupMembership. Según el endpoint que la
/// devuelva, viene con `group` poblado (GET /groups/mine) o con `user`
/// poblado (GET /groups/:id/members) — ambos son opcionales acá.
class GroupMembership {
  const GroupMembership({
    required this.userId,
    required this.groupId,
    required this.role,
    this.group,
    this.user,
  });

  final String userId;
  final String groupId;
  final GroupRole role;
  final Group? group;
  final MemberInfo? user;

  factory GroupMembership.fromJson(Map<String, dynamic> json) => GroupMembership(
        userId: json['userId'] as String,
        groupId: json['groupId'] as String,
        role: GroupRole.fromJson(json['role'] as String),
        group: json['group'] != null
            ? Group.fromJson(json['group'] as Map<String, dynamic>)
            : null,
        user: json['user'] != null
            ? MemberInfo.fromJson(json['user'] as Map<String, dynamic>)
            : null,
      );
}
