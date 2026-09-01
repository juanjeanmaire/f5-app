class Group {
  const Group({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.ownerId,
    this.venueAddress,
    this.teamAName,
    this.teamBName,
  });

  final String id;
  final String name;
  final String inviteCode;
  final String ownerId;
  final String? venueAddress;

  /// Nombres personalizados de los equipos — "A"/"B" si son null.
  final String? teamAName;
  final String? teamBName;

  String get displayTeamAName => teamAName?.isNotEmpty == true ? teamAName! : 'A';
  String get displayTeamBName => teamBName?.isNotEmpty == true ? teamBName! : 'B';

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'] as String,
        name: json['name'] as String,
        inviteCode: json['inviteCode'] as String,
        ownerId: json['ownerId'] as String,
        venueAddress: json['venueAddress'] as String?,
        teamAName: json['teamAName'] as String?,
        teamBName: json['teamBName'] as String?,
      );
}
