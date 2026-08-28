/// "Nombre" si no hay apodo, o 'Nombre "Apodo"' si lo hay — el mismo
/// criterio en toda la app para mostrar nombres de usuarios.
String formatDisplayName(String name, String? nickname) =>
    (nickname != null && nickname.isNotEmpty) ? '$name "$nickname"' : name;
