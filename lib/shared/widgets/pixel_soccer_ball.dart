import 'package:flutter/material.dart';

/// Pelota de fútbol pixel-art / 8-bit — el elemento de marca distintivo
/// de la app. Se dibuja a mano (no es una imagen) para que se vea nítida
/// en cualquier tamaño y no dependa de assets externos.
///
/// El patrón es simétrico en los dos ejes y en diagonal (se calcula por
/// distancia al centro, no está "tipeado" celda por celda), así que
/// siempre da un resultado prolijo sin importar el tamaño de grilla.
class PixelSoccerBall extends StatelessWidget {
  const PixelSoccerBall({
    super.key,
    this.size = 96,
    required this.baseColor,
    required this.patternColor,
  });

  final double size;
  final Color baseColor;
  final Color patternColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PixelBallPainter(baseColor: baseColor, patternColor: patternColor),
      ),
    );
  }
}

class _PixelBallPainter extends CustomPainter {
  _PixelBallPainter({required this.baseColor, required this.patternColor});

  final Color baseColor;
  final Color patternColor;

  static const int _grid = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _grid;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawCircle(center, radius, Paint()..color = baseColor);

    final darkPaint = Paint()..color = patternColor;

    for (int row = 0; row < _grid; row++) {
      for (int col = 0; col < _grid; col++) {
        final cx = (col + 0.5) * cell;
        final cy = (row + 0.5) * cell;
        final dx = cx - center.dx;
        final dy = cy - center.dy;
        if (dx * dx + dy * dy > radius * radius) continue; // fuera del círculo

        if (_isDark(row, col)) {
          canvas.drawRect(
            Rect.fromLTWH(col * cell, row * cell, cell + 0.5, cell + 0.5),
            darkPaint,
          );
        }
      }
    }
  }

  /// Patrón central tipo pentágono + parches hacia el borde, con simetría
  /// en ambos ejes y diagonal (por eso alcanza con comparar valores
  /// absolutos, no hace falta listar cada celda a mano).
  bool _isDark(int row, int col) {
    final r = (row - (_grid - 1) / 2).abs();
    final c = (col - (_grid - 1) / 2).abs();
    final a = r > c ? r : c;
    final b = r < c ? r : c;

    if (a <= 1.5) return true; // bloque central
    if (a >= 3.5 && a <= 4.5 && b <= 1.0) return true; // parches cardinales
    if (a >= 2.5 && a <= 3.5 && b >= 2.0 && b <= 3.0) return true; // parches diagonales

    return false;
  }

  @override
  bool shouldRepaint(covariant _PixelBallPainter oldDelegate) =>
      oldDelegate.baseColor != baseColor || oldDelegate.patternColor != patternColor;
}
