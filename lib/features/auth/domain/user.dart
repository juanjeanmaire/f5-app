class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.nickname,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String name;
  final String? nickname;
  final String? avatarUrl;

  /// "Nombre" si no tiene apodo, o 'Nombre "Apodo"' si lo tiene — se usa
  /// en toda la app donde se muestra el nombre de un usuario.
  String get displayName =>
      (nickname != null && nickname!.isNotEmpty) ? '$name "$nickname"' : name;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        nickname: json['nickname'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
      );
}
