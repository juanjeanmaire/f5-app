import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/auth/presentation/auth_controller.dart';
import 'league_teams.dart';

/// Paleta de marca: navy + dorado + crema, inspirada en un jersey/trofeo
/// de fútbol vintage. Calibrada a mano (no generada por seed) para tener
/// control total sobre estos valores exactos. El dorado es el acento por
/// DEFECTO — si el usuario elige un equipo favorito en su perfil, ese
/// acento se reemplaza por el color de ese equipo (ver [AppTheme.build]).
class AppColors {
  AppColors._();

  static const navy = Color(0xFF1B2340);
  static const navyDeep = Color(0xFF11172C);
  static const gold = Color(0xFFC9A227);
  static const cream = Color(0xFFF1E8D6);
  static const error = Color(0xFFE0654B);

  /// El marrón claro del ícono de la app y la pantalla de carga nativa
  /// (ver assets/icon/ y pubspec.yaml) — no se usa en el resto de la UI,
  /// solo en ese momento puntual de apertura para que quede idéntico al
  /// ícono del sistema operativo.
  static const iconBrown = Color(0xFFD9C6A0);
}

class AppTheme {
  AppTheme._();

  /// Bebas Neue para títulos (condensada, en bloque — el look "stencil de
  /// camiseta"), Barlow para el cuerpo del texto (buena legibilidad en listas).
  static TextTheme _buildTextTheme(ColorScheme scheme) {
    final base = GoogleFonts.barlowTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    final display = GoogleFonts.bebasNeueTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    return base.copyWith(
      displayLarge: display.displayLarge?.copyWith(letterSpacing: 2),
      displayMedium: display.displayMedium?.copyWith(letterSpacing: 1.5),
      headlineLarge: display.headlineLarge?.copyWith(letterSpacing: 1.5),
      headlineMedium: display.headlineMedium?.copyWith(letterSpacing: 1.2),
      headlineSmall: display.headlineSmall?.copyWith(letterSpacing: 1.0),
      titleLarge: display.titleLarge?.copyWith(letterSpacing: 1.0),
      titleMedium: display.titleMedium?.copyWith(letterSpacing: 0.6),
    );
  }

  /// Arma el theme completo, con [accent] como color principal (dorado
  /// por defecto, o el color de un equipo si el usuario eligió uno).
  static ThemeData build({Color accent = AppColors.gold}) {
    final colorScheme = ColorScheme.dark(
      primary: accent,
      onPrimary: AppColors.navyDeep,
      secondary: AppColors.cream,
      onSecondary: AppColors.navyDeep,
      surface: AppColors.navy,
      onSurface: AppColors.cream,
      error: AppColors.error,
      onError: Colors.white,
    );
    final textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.navy,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navyDeep,
        foregroundColor: AppColors.cream,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.cream,
          fontSize: 22,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: AppColors.navyDeep,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      cardTheme: CardThemeData(
        color: AppColors.navyDeep,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: accent.withValues(alpha: 0.25)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accent.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        filled: true,
        fillColor: AppColors.navyDeep,
        labelStyle: TextStyle(color: AppColors.cream.withValues(alpha: 0.7)),
      ),
      iconTheme: const IconThemeData(color: AppColors.cream),
      dividerColor: accent.withValues(alpha: 0.2),
    );
  }

  /// Theme por defecto (dorado) — se usa si el usuario no eligió equipo,
  /// o antes de que la sesión termine de cargar.
  static ThemeData get light => build();
}

/// El theme "vivo" de la app: dorado por defecto, o el color del equipo
/// favorito del usuario logueado si eligió uno en su perfil.
final appThemeProvider = Provider<ThemeData>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  final team = findLeagueTeam(user?.favoriteTeamId);
  return AppTheme.build(accent: team?.primaryColor ?? AppColors.gold);
});
