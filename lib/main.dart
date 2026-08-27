import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  runZonedGuarded(() {
    // Muestra en pantalla cualquier error de Flutter en vez de dejar que
    // la app se cierre en silencio — clave mientras validamos el primer
    // build real en un dispositivo.
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
    };

    ErrorWidget.builder = (details) => Material(
          color: Colors.red.shade50,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error:\n\n${details.exceptionAsString()}\n\n${details.stack}',
                style: const TextStyle(color: Colors.black, fontSize: 12),
              ),
            ),
          ),
        );

    runApp(const ProviderScope(child: F5App()));
  }, (error, stack) {
    // Errores async que escapan de Flutter (fuera de un widget build).
    debugPrint('Uncaught zone error: $error\n$stack');
  });
}
