import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// El wordmark "F5" en píxeles, con sombra — el mismo símbolo que el
/// ícono de la app en el celular y la pantalla de carga nativa
/// (ver pubspec.yaml: flutter_launcher_icons / flutter_native_splash,
/// y assets/icon/icon_foreground.png, que usa este mismo patrón de
/// píxeles a mano).
class PixelF5Logo extends StatelessWidget {
  const PixelF5Logo({super.key, this.pixelSize = 14, this.shadowOffset = 4});

  final double pixelSize;
  final double shadowOffset;

  static const List<List<int>> _f = [
    [1, 1, 1],
    [1, 0, 0],
    [1, 1, 0],
    [1, 0, 0],
    [1, 0, 0],
  ];

  static const List<List<int>> _five = [
    [1, 1, 1],
    [1, 0, 0],
    [1, 1, 1],
    [0, 0, 1],
    [1, 1, 1],
  ];

  static const _shadowColor = Color(0xFF0B0F1C);

  @override
  Widget build(BuildContext context) {
    final glyphW = pixelSize * 3;
    final glyphH = pixelSize * 5;
    final gap = pixelSize;
    final totalW = glyphW * 2 + gap;

    return SizedBox(
      width: totalW + shadowOffset,
      height: glyphH + shadowOffset,
      child: Stack(
        children: [
          ..._buildGlyph(_f, shadowOffset, shadowOffset, _shadowColor),
          ..._buildGlyph(_five, glyphW + gap + shadowOffset, shadowOffset, _shadowColor),
          ..._buildGlyph(_f, 0, 0, AppColors.navy),
          ..._buildGlyph(_five, glyphW + gap, 0, AppColors.navy),
        ],
      ),
    );
  }

  List<Widget> _buildGlyph(List<List<int>> mask, double ox, double oy, Color color) {
    final widgets = <Widget>[];
    for (var row = 0; row < mask.length; row++) {
      for (var col = 0; col < mask[row].length; col++) {
        if (mask[row][col] == 1) {
          widgets.add(
            Positioned(
              left: ox + col * pixelSize,
              top: oy + row * pixelSize,
              width: pixelSize,
              height: pixelSize,
              child: Container(color: color),
            ),
          );
        }
      }
    }
    return widgets;
  }
}
