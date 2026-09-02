import 'dart:async';

import 'package:flutter/material.dart';

/// Llama a [onRefresh] cada [interval] mientras el widget esté visible y
/// la app en primer plano — pensado para pantallas con datos que pueden
/// cambiar por acciones de OTRO usuario (ej. alguien más cierra una
/// convocatoria), ya que no tenemos notificaciones push en tiempo real y
/// si no, el cambio no se nota hasta reabrir la pantalla o la app.
///
/// Al volver de segundo plano (ej. el usuario estaba en otra app o con
/// la pantalla bloqueada) refresca al toque, sin esperar el próximo tick.
class AutoRefresh extends StatefulWidget {
  const AutoRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.interval = const Duration(seconds: 15),
  });

  final VoidCallback onRefresh;
  final Widget child;
  final Duration interval;

  @override
  State<AutoRefresh> createState() => _AutoRefreshState();
}

class _AutoRefreshState extends State<AutoRefresh> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.interval, (_) => widget.onRefresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.onRefresh();
      _startTimer();
    } else if (state == AppLifecycleState.paused) {
      // Sin sentido seguir pidiendo datos mientras la app no se ve.
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
