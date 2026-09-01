import '../../matches/domain/match.dart';

enum MatchCallStatus {
  open,
  closed,
  cancelled;

  static MatchCallStatus fromJson(String value) => switch (value) {
        'OPEN' => MatchCallStatus.open,
        'CLOSED' => MatchCallStatus.closed,
        _ => MatchCallStatus.cancelled,
      };
}

/// A qué equipo quedó asignado un jugador, una vez que la convocatoria
/// se cerró sola y se armaron los equipos por ELO.
class MatchCallTeamAssignment {
  const MatchCallTeamAssignment({
    required this.playerId,
    required this.playerName,
    required this.team,
  });

  final String playerId;
  final String playerName;
  final TeamSide team;

  factory MatchCallTeamAssignment.fromJson(Map<String, dynamic> json) => MatchCallTeamAssignment(
        playerId: json['playerId'] as String,
        playerName: (json['player'] as Map<String, dynamic>?)?['name'] as String? ?? '',
        team: TeamSide.fromJson(json['team'] as String),
      );
}

/// La confirmación de un miembro puntual — no trae el nombre (la pantalla
/// de detalle solo necesita saber CUÁNTOS confirmaron y si YO confirmé).
class MatchCallResponseEntry {
  const MatchCallResponseEntry({required this.userId, required this.going});

  final String userId;
  final bool going;

  factory MatchCallResponseEntry.fromJson(Map<String, dynamic> json) => MatchCallResponseEntry(
        userId: json['userId'] as String,
        going: json['going'] as bool,
      );
}

class MatchCall {
  const MatchCall({
    required this.id,
    required this.groupId,
    required this.matchType,
    required this.date,
    required this.status,
    this.venueAddress,
    this.comment,
    this.responses = const [],
    this.teamPlayers = const [],
  });

  final String id;
  final String groupId;
  final MatchType matchType;
  final DateTime date;
  final MatchCallStatus status;
  final String? venueAddress;
  final String? comment;
  final List<MatchCallResponseEntry> responses;
  final List<MatchCallTeamAssignment> teamPlayers;

  /// Cantidad de jugadores necesaria para cerrar la convocatoria — el
  /// mismo criterio que usa el backend (teamSize * 2).
  int get quota => matchType.teamSize * 2;

  int get goingCount => responses.where((r) => r.going).length;

  bool? myResponse(String? userId) {
    if (userId == null) return null;
    for (final r in responses) {
      if (r.userId == userId) return r.going;
    }
    return null;
  }

  List<MatchCallTeamAssignment> get teamA =>
      teamPlayers.where((p) => p.team == TeamSide.a).toList();
  List<MatchCallTeamAssignment> get teamB =>
      teamPlayers.where((p) => p.team == TeamSide.b).toList();

  factory MatchCall.fromJson(Map<String, dynamic> json) => MatchCall(
        id: json['id'] as String,
        groupId: json['groupId'] as String,
        matchType: MatchType.fromJson(json['matchType'] as String),
        date: DateTime.parse(json['date'] as String),
        status: MatchCallStatus.fromJson(json['status'] as String),
        venueAddress: json['venueAddress'] as String?,
        comment: json['comment'] as String?,
        responses: (json['responses'] as List<dynamic>? ?? [])
            .map((e) => MatchCallResponseEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        teamPlayers: (json['teamPlayers'] as List<dynamic>? ?? [])
            .map((e) => MatchCallTeamAssignment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
