import 'package:flutter/material.dart';

/// Un globo de chat en píxeles, en el verde característico de WhatsApp —
/// no reproducimos su isotipo exacto (evitamos usar su marca literal),
/// pero el color + la forma de globo comunican "compartir por WhatsApp"
/// de un vistazo, en el mismo estilo en bloques que el resto de la marca.
class PixelChatIcon extends StatelessWidget {
  const PixelChatIcon({super.key, this.pixelSize = 3});

  final double pixelSize;

  static const Color _green = Color(0xFF25D366);

  // Globo de chat con colita, 8x7 — 1 = pintado.
  static const List<List<int>> _mask = [
    [0, 1, 1, 1, 1, 1, 1, 0],
    [1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1],
    [0, 1, 1, 1, 1, 1, 1, 0],
    [0, 1, 0, 0, 0, 0, 0, 0],
  ];

  @override
  Widget build(BuildContext context) {
    final cols = _mask[0].length;
    final rows = _mask.length;

    return SizedBox(
      width: cols * pixelSize,
      height: rows * pixelSize,
      child: Stack(
        children: [
          for (var row = 0; row < rows; row++)
            for (var col = 0; col < cols; col++)
              if (_mask[row][col] == 1)
                Positioned(
                  left: col * pixelSize,
                  top: row * pixelSize,
                  width: pixelSize,
                  height: pixelSize,
                  child: Container(color: _green),
                ),
        ],
      ),
    );
  }
}
