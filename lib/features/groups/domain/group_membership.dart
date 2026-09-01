import '../../../shared/utils/display_name.dart';
import '../../match_calls/domain/match_call.dart';
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
    this.nickname,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final String? nickname;
  final String? avatarUrl;

  String get displayName => formatDisplayName(name, nickname);

  factory MemberInfo.fromJson(Map<String, dynamic> json) => MemberInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        nickname: json['nickname'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
      );
}

/// Representa una fila de GroupMembership. Según el endpoint que la
/// devuelva, viene con `group` poblado (GET /groups/mine) o con `user`
/// poblado (GET /groups/:id/members) — ambos son opcionales acá.
///
/// `captainName`/`captainNickname`/`myElo` solo vienen poblados desde
/// GET /groups/mine (ver GroupsService.listMyGroups en el backend) — se
/// usan para el ribbon de "mis grupos" en la home.
class GroupMembership {
  const GroupMembership({
    required this.userId,
    required this.groupId,
    required this.role,
    this.group,
    this.user,
    this.captainName,
    this.captainNickname,
    this.myElo,
    this.activeMatchCall,
  });

  final String userId;
  final String groupId;
  final GroupRole role;
  final Group? group;
  final MemberInfo? user;
  final String? captainName;
  final String? captainNickname;
  final double? myElo;

  /// Solo viene poblado desde GET /groups/mine — la convocatoria abierta
  /// (o recién cerrada) de este grupo, si hay alguna, para el indicador
  /// en el ribbon de "mis grupos" en la home.
  final MatchCall? activeMatchCall;

  String? get captainDisplayName =>
      captainName != null ? formatDisplayName(captainName!, captainNickname) : null;

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
        captainName: json['captainName'] as String?,
        captainNickname: json['captainNickname'] as String?,
        myElo: (json['myElo'] as num?)?.toDouble(),
        activeMatchCall: json['activeMatchCall'] != null
            ? MatchCall.fromJson(json['activeMatchCall'] as Map<String, dynamic>)
            : null,
      );
}
