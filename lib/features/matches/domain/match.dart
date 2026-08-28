enum MatchType {
  f5,
  f6,
  f7;

  static MatchType fromJson(String value) => switch (value) {
        'F5' => MatchType.f5,
        'F6' => MatchType.f6,
        'F7' => MatchType.f7,
        _ => throw ArgumentError('MatchType desconocido: $value'),
      };

  String toJson() => switch (this) {
        MatchType.f5 => 'F5',
        MatchType.f6 => 'F6',
        MatchType.f7 => 'F7',
      };

  int get teamSize => switch (this) {
        MatchType.f5 => 5,
        MatchType.f6 => 6,
        MatchType.f7 => 7,
      };

  String get label => switch (this) {
        MatchType.f5 => 'F5 (5 vs 5)',
        MatchType.f6 => 'F6 (6 vs 6)',
        MatchType.f7 => 'F7 (7 vs 7)',
      };
}

enum TeamSide {
  a,
  b;

  static TeamSide fromJson(String value) => value == 'A' ? TeamSide.a : TeamSide.b;
}

class MatchTeamPlayer {
  const MatchTeamPlayer({
    required this.playerId,
    required this.team,
    required this.eloBefore,
    required this.eloAfter,
    required this.eloDelta,
    this.playerName,
    this.linkedUserId,
  });

  final String playerId;
  final TeamSide team;
  final double eloBefore;
  final double eloAfter;
  final double eloDelta;

  /// Vienen del `player` anidado (el backend hace include: { player: true }).
  final String? playerName;
  final String? linkedUserId;

  factory MatchTeamPlayer.fromJson(Map<String, dynamic> json) => MatchTeamPlayer(
        playerId: json['playerId'] as String,
        team: TeamSide.fromJson(json['team'] as String),
        eloBefore: (json['eloBefore'] as num).toDouble(),
        eloAfter: (json['eloAfter'] as num).toDouble(),
        eloDelta: (json['eloDelta'] as num).toDouble(),
        playerName: (json['player'] as Map<String, dynamic>?)?['name'] as String?,
        linkedUserId: (json['player'] as Map<String, dynamic>?)?['linkedUserId'] as String?,
      );
}

class Match {
  const Match({
    required this.id,
    required this.groupId,
    required this.matchType,
    required this.date,
    required this.scoreA,
    required this.scoreB,
    required this.teamPlayers,
    this.location,
    this.groupName,
  });

  final String id;
  final String groupId;
  final MatchType matchType;
  final DateTime date;
  final String? location;
  final int scoreA;
  final int scoreB;
  final List<MatchTeamPlayer> teamPlayers;

  /// Solo viene poblado en GET /matches/mine (el backend hace
  /// include: { group: true } ahí) — en los endpoints scoped a un grupo
  /// puntual no hace falta, ya se sabe en qué grupo se está.
  final String? groupName;

  List<MatchTeamPlayer> get teamA =>
      teamPlayers.where((p) => p.team == TeamSide.a).toList();
  List<MatchTeamPlayer> get teamB =>
      teamPlayers.where((p) => p.team == TeamSide.b).toList();

  static double _average(List<double> values) =>
      values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;

  /// ELO promedio del equipo ANTES del partido (el "nivel grupal" con el
  /// que se enfrentaron, no el actual).
  double get avgEloTeamA => _average(teamA.map((p) => p.eloBefore).toList());
  double get avgEloTeamB => _average(teamB.map((p) => p.eloBefore).toList());

  /// Delta promedio de ELO del equipo en este partido puntual. Los jugadores
  /// de un mismo equipo pueden tener deltas distintos entre sí (K-factor
  /// según su experiencia), así que esto es un promedio representativo,
  /// no un valor único "de equipo" que exista en el backend.
  double get avgDeltaTeamA => _average(teamA.map((p) => p.eloDelta).toList());
  double get avgDeltaTeamB => _average(teamB.map((p) => p.eloDelta).toList());

  factory Match.fromJson(Map<String, dynamic> json) => Match(
        id: json['id'] as String,
        groupId: json['groupId'] as String,
        matchType: MatchType.fromJson(json['matchType'] as String),
        date: DateTime.parse(json['date'] as String),
        location: json['location'] as String?,
        scoreA: json['scoreA'] as int,
        scoreB: json['scoreB'] as int,
        teamPlayers: (json['teamPlayers'] as List<dynamic>? ?? [])
            .map((e) => MatchTeamPlayer.fromJson(e as Map<String, dynamic>))
            .toList(),
        groupName: (json['group'] as Map<String, dynamic>?)?['name'] as String?,
      );
}

/// ELO de un jugador después de cada partido en el que participó, en
/// orden cronológico (los partidos más viejos primero) — pensado para
/// graficar su evolución. [matches] puede venir en cualquier orden.
List<double> eloProgressionFor(List<Match> matches, String playerId) {
  final relevant = matches
      .where((m) => m.teamPlayers.any((tp) => tp.playerId == playerId))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  return relevant
      .map((m) => m.teamPlayers.firstWhere((tp) => tp.playerId == playerId).eloAfter)
      .toList();
}
