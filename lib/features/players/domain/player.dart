import '../../../shared/utils/display_name.dart';

class Player {
  const Player({
    required this.id,
    required this.groupId,
    required this.name,
    required this.elo,
    required this.matchesPlayed,
    required this.active,
    this.linkedUserId,
    this.linkedUserNickname,
  });

  final String id;
  final String groupId;
  final String? linkedUserId;
  final String name;
  final double elo;
  final int matchesPlayed;
  final bool active;

  /// El apodo que eligió la persona detrás de este jugador (si tiene
  /// cuenta vinculada y se puso uno) — null si no.
  final String? linkedUserNickname;

  /// "Nombre" si no hay apodo, o 'Nombre "Apodo"' si lo hay.
  String get displayName => formatDisplayName(name, linkedUserNickname);

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        groupId: json['groupId'] as String,
        linkedUserId: json['linkedUserId'] as String?,
        name: json['name'] as String,
        elo: (json['elo'] as num).toDouble(),
        matchesPlayed: json['matchesPlayed'] as int,
        active: json['active'] as bool,
        linkedUserNickname: json['linkedUserNickname'] as String?,
      );
}
