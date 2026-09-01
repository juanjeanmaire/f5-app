class Group {
  const Group({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.ownerId,
    this.venueAddress,
  });

  final String id;
  final String name;
  final String inviteCode;
  final String ownerId;
  final String? venueAddress;

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'] as String,
        name: json['name'] as String,
        inviteCode: json['inviteCode'] as String,
        ownerId: json['ownerId'] as String,
        venueAddress: json['venueAddress'] as String?,
      );
}
