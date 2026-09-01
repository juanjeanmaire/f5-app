import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/auth/presentation/auth_controller.dart';
import 'league_teams.dart';

/// Paleta de marca: marrón claro + azul marino, la misma que el ícono de
/// la app y la pantalla de carga nativa (ver assets/icon/). El azul
/// marino es el acento por DEFECTO — si el usuario elige un equipo
/// favorito en su perfil, ese acento se reemplaza por el color de ese
/// equipo (ver [AppTheme.build]); el fondo marrón y el texto oscuro se
/// mantienen siempre iguales.
class AppColors {
  AppColors._();

  static const navy = Color(0xFF1B2340);
  static const navyDeep = Color(0xFF11172C);
  static const gold = Color(0xFFC9A227);
  static const cream = Color(0xFFF1E8D6);
  static const error = Color(0xFFE0654B);

  /// El marrón claro de fondo — el mismo del ícono de la app y la
  /// pantalla de carga nativa (ver assets/icon/ y pubspec.yaml).
  static const iconBrown = Color(0xFFD9C6A0);
}

class AppTheme {
  AppTheme._();

  /// Bebas Neue para títulos (condensada, en bloque — el look "stencil de
  /// camiseta"), Barlow para el cuerpo del texto (buena legibilidad en listas).
  static TextTheme _buildTextTheme(ColorScheme scheme) {
    final base = GoogleFonts.barlowTextTheme(
      ThemeData(brightness: Brightness.light).textTheme,
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    final display = GoogleFonts.bebasNeueTextTheme(
      ThemeData(brightness: Brightness.light).textTheme,
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

  /// Arma el theme completo, con [accent] como color principal (azul
  /// marino por defecto, o el color de un equipo si el usuario eligió uno).
  /// El fondo marrón claro y el texto oscuro NUNCA cambian — solo varía
  /// el acento, para que siempre sea legible sin importar el equipo.
  static ThemeData build({Color accent = AppColors.navy}) {
    // Algunos equipos tienen colores muy claros (River blanco, Aldosivi
    // amarillo) — con texto crema fijo encima quedarían ilegibles. Se
    // calcula el contraste según qué tan clara es la posta del color.
    final onAccent = accent.computeLuminance() > 0.5 ? AppColors.navyDeep : AppColors.cream;

    final colorScheme = ColorScheme.light(
      primary: accent,
      onPrimary: onAccent,
      secondary: AppColors.navyDeep,
      onSecondary: AppColors.cream,
      surface: AppColors.cream,
      onSurface: AppColors.navyDeep,
      error: AppColors.error,
      onError: Colors.white,
    );
    final textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.iconBrown,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.iconBrown,
        foregroundColor: AppColors.navyDeep,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.navyDeep,
          fontSize: 22,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
          // Esquinas casi sin redondear — el espíritu "en bloques" del
          // resto de la marca (ícono, logo, ribbons) en vez del look
          // Material genérico con todo curvo.
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cream,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: accent.withValues(alpha: 0.3)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: accent.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        filled: true,
        fillColor: AppColors.cream,
        labelStyle: TextStyle(color: AppColors.navyDeep.withValues(alpha: 0.7)),
      ),
      iconTheme: const IconThemeData(color: AppColors.navyDeep),
      dividerColor: accent.withValues(alpha: 0.25),
    );
  }

  /// Theme por defecto (azul marino) — se usa si el usuario no eligió
  /// equipo, o antes de que la sesión termine de cargar.
  static ThemeData get light => build();

  /// Tipografía pixel de verdad (VT323) para los títulos de los ribbons —
  /// un guiño más directo a la identidad pixel-art que Bebas Neue sola.
  /// VT323 se ve más chica/fina que otras fuentes al mismo tamaño
  /// nominal, por eso se agranda un poco para que pese similar.
  static TextStyle ribbonTitleStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.titleMedium;
    return GoogleFonts.vt323(
      textStyle: base,
      fontSize: (base?.fontSize ?? 16) * 1.3,
      letterSpacing: 0.5,
    );
  }
}

/// El theme "vivo" de la app: azul marino por defecto, o el color del
/// equipo favorito del usuario logueado si eligió uno en su perfil. Se
/// actualiza solo — cualquier widget que lea Theme.of(context) se
/// redibuja apenas este provider cambia de valor, no hace falta reiniciar
/// nada ni navegar a otra pantalla.
final appThemeProvider = Provider<ThemeData>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  final team = findLeagueTeam(user?.favoriteTeamId);
  return AppTheme.build(accent: team?.primaryColor ?? AppColors.navy);
});
