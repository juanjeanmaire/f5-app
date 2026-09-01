import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/match_calls_repository.dart';
import '../domain/match_call.dart';

/// La convocatoria activa del grupo (o null) — la usan tanto el banner de
/// arriba de la pantalla del grupo como el botón de "Realizar una
/// convocatoria" (para saber si tiene que aparecer gris).
final activeMatchCallProvider = FutureProvider.family<MatchCall?, String>((ref, groupId) async {
  final repo = ref.watch(matchCallsRepositoryProvider);
  return repo.getActive(groupId);
});

typedef MatchCallKey = ({String groupId, String callId});

/// El detalle completo de una convocatoria puntual — la pantalla de
/// "voy / no voy" (la misma a la que llevaría una notificación).
final matchCallDetailProvider = FutureProvider.family<MatchCall, MatchCallKey>((ref, key) async {
  final repo = ref.watch(matchCallsRepositoryProvider);
  return repo.getDetail(key.groupId, key.callId);
});
