class TeamGenPlayer {
  const TeamGenPlayer({required this.playerId, required this.name, required this.elo});

  final String playerId;
  final String name;
  final double elo;

  factory TeamGenPlayer.fromJson(Map<String, dynamic> json) => TeamGenPlayer(
        playerId: json['playerId'] as String,
        name: json['name'] as String,
        elo: (json['elo'] as num).toDouble(),
      );
}

class TeamGenerationResult {
  const TeamGenerationResult({
    required this.teamA,
    required this.teamB,
    required this.sumEloA,
    required this.sumEloB,
    required this.diff,
    required this.method,
  });

  final List<TeamGenPlayer> teamA;
  final List<TeamGenPlayer> teamB;
  final double sumEloA;
  final double sumEloB;
  final double diff;

  /// 'exact' (fuerza bruta, pools chicos) o 'heuristic' (pools grandes).
  final String method;

  factory TeamGenerationResult.fromJson(Map<String, dynamic> json) => TeamGenerationResult(
        teamA: (json['teamA'] as List)
            .map((e) => TeamGenPlayer.fromJson(e as Map<String, dynamic>))
            .toList(),
        teamB: (json['teamB'] as List)
            .map((e) => TeamGenPlayer.fromJson(e as Map<String, dynamic>))
            .toList(),
        sumEloA: (json['sumEloA'] as num).toDouble(),
        sumEloB: (json['sumEloB'] as num).toDouble(),
        diff: (json['diff'] as num).toDouble(),
        method: json['method'] as String,
      );
}
