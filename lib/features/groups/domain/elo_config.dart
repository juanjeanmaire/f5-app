class EloConfig {
  const EloConfig({
    required this.kFactorNew,
    required this.kFactorMid,
    required this.kFactorVeteran,
    required this.newThreshold,
    required this.veteranThreshold,
    required this.goalDiffWeight,
    required this.maxGoalDiffMultiplier,
  });

  final double kFactorNew;
  final double kFactorMid;
  final double kFactorVeteran;
  final int newThreshold;
  final int veteranThreshold;
  final double goalDiffWeight;
  final double maxGoalDiffMultiplier;

  factory EloConfig.fromJson(Map<String, dynamic> json) => EloConfig(
        kFactorNew: (json['kFactorNew'] as num).toDouble(),
        kFactorMid: (json['kFactorMid'] as num).toDouble(),
        kFactorVeteran: (json['kFactorVeteran'] as num).toDouble(),
        newThreshold: json['newThreshold'] as int,
        veteranThreshold: json['veteranThreshold'] as int,
        goalDiffWeight: (json['goalDiffWeight'] as num).toDouble(),
        maxGoalDiffMultiplier: (json['maxGoalDiffMultiplier'] as num).toDouble(),
      );
}
