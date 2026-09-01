import 'package:flutter/material.dart';

/// Un equipo de la Liga Profesional Argentina, con sus colores
/// principales — se usan para el acento de color de la app cuando el
/// usuario lo elige en su perfil.
class LeagueTeam {
  const LeagueTeam({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final String id;
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
}

/// Lista de equipos conocidos de primera división — no es 100% exhaustiva
/// (algunos ascendidos recientes o clubes menos conocidos pueden faltar);
/// se puede ampliar más adelante.
const List<LeagueTeam> argentineLeagueTeams = [
  LeagueTeam(id: 'boca', name: 'Boca Juniors', primaryColor: Color(0xFF1B5E9E), secondaryColor: Color(0xFFFDB913)),
  LeagueTeam(id: 'river', name: 'River Plate', primaryColor: Color(0xFFE30613), secondaryColor: Color(0xFFFFFFFF)),
  LeagueTeam(id: 'racing', name: 'Racing Club', primaryColor: Color(0xFF75AADB), secondaryColor: Color(0xFFFFFFFF)),
  LeagueTeam(id: 'independiente', name: 'Independiente', primaryColor: Color(0xFFE2231A), secondaryColor: Color(0xFFFFFFFF)),
  LeagueTeam(id: 'sanlorenzo', name: 'San Lorenzo', primaryColor: Color(0xFF002F6C), secondaryColor: Color(0xFFE4032E)),
  LeagueTeam(id: 'estudiantes', name: 'Estudiantes de La Plata', primaryColor: Color(0xFFD52B1E), secondaryColor: Color(0xFFFFFFFF)),
  LeagueTeam(id: 'gimnasia', name: 'Gimnasia y Esgrima (LP)', primaryColor: Color(0xFF002554), secondaryColor: Color(0xFF75AADB)),
  LeagueTeam(id: 'velez', name: 'Vélez Sarsfield', primaryColor: Color(0xFF003DA5), secondaryColor: Color(0xFFE4032E)),
  LeagueTeam(id: 'huracan', name: 'Huracán', primaryColor: Color(0xFFD2001F), secondaryColor: Color(0xFFFFFFFF)),
  LeagueTeam(id: 'newells', name: "Newell's Old Boys", primaryColor: Color(0xFFE2231A), secondaryColor: Color(0xFF000000)),
  LeagueTeam(id: 'rosariocentral', name: 'Rosario Central', primaryColor: Color(0xFF002D72), secondaryColor: Color(0xFFFFD100)),
  LeagueTeam(id: 'talleres', name: 'Talleres de Córdoba', primaryColor: Color(0xFF002D72), secondaryColor: Color(0xFFFFFFFF)),
  LeagueTeam(id: 'belgrano', name: 'Belgrano', primaryColor: Color(0xFF75AADB), secondaryColor: Color(0xFF000000)),
  LeagueTeam(id: 'argentinosjrs', name: 'Argentinos Juniors', primaryColor: Color(0xFFE2231A), secondaryColor: Color(0xFFFFFFFF)),
  LeagueTeam(id: 'banfield', name: 'Banfield', primaryColor: Color(0xFF006A44), secondaryColor: Color(0xFFFFFFFF)),
  LeagueTeam(id: 'lanus', name: 'Lanús', primaryColor: Color(0xFF6D1E3C), secondaryColor: Color(0xFFFFFFFF)),
  LeagueTeam(id: 'defensayjusticia', name: 'Defensa y Justicia', primaryColor: Color(0xFF2E7D32), secondaryColor: Color(0xFF6A2C91)),
  LeagueTeam(id: 'tigre', name: 'Tigre', primaryColor: Color(0xFF75AADB), secondaryColor: Color(0xFFE2231A)),
  LeagueTeam(id: 'platense', name: 'Platense', primaryColor: Color(0xFF6B7A3D), secondaryColor: Color(0xFF000000)),
  LeagueTeam(id: 'barracascentral', name: 'Barracas Central', primaryColor: Color(0xFFE2231A), secondaryColor: Color(0xFFFFFFFF)),
  LeagueTeam(id: 'instituto', name: 'Instituto (Córdoba)', primaryColor: Color(0xFFE2231A), secondaryColor: Color(0xFFFFFFFF)),
  LeagueTeam(id: 'sarmiento', name: 'Sarmiento (Junín)', primaryColor: Color(0xFF2E7D32), secondaryColor: Color(0xFFFFFFFF)),
  LeagueTeam(id: 'centralcordoba', name: 'Central Córdoba (SdE)', primaryColor: Color(0xFF000000), secondaryColor: Color(0xFFFFFFFF)),
  LeagueTeam(id: 'union', name: 'Unión (Santa Fe)', primaryColor: Color(0xFFE2231A), secondaryColor: Color(0xFFFFFFFF)),
  LeagueTeam(id: 'colon', name: 'Colón (Santa Fe)', primaryColor: Color(0xFF000000), secondaryColor: Color(0xFFE2231A)),
  LeagueTeam(id: 'aldosivi', name: 'Aldosivi', primaryColor: Color(0xFFFFD100), secondaryColor: Color(0xFF2E7D32)),
  LeagueTeam(id: 'independienterivadavia', name: 'Independiente Rivadavia', primaryColor: Color(0xFF003DA5), secondaryColor: Color(0xFFFFFFFF)),
  LeagueTeam(id: 'riestra', name: 'Deportivo Riestra', primaryColor: Color(0xFFE2231A), secondaryColor: Color(0xFF000000)),
];

LeagueTeam? findLeagueTeam(String? id) {
  if (id == null) return null;
  for (final team in argentineLeagueTeams) {
    if (team.id == id) return team;
  }
  return null;
}
