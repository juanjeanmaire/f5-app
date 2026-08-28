import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/messages_repository.dart';
import '../domain/message.dart';

/// La conversación propia de un miembro con el/los capitán(es) del grupo.
final myConversationProvider = FutureProvider.family<List<ChatMessage>, String>(
  (ref, groupId) async {
    final repo = ref.watch(messagesRepositoryProvider);
    return repo.getMyConversation(groupId);
  },
);

/// El listado de conversaciones que ve el capitán (una por miembro).
final threadsProvider = FutureProvider.family<List<MessageThread>, String>(
  (ref, groupId) async {
    final repo = ref.watch(messagesRepositoryProvider);
    return repo.listThreads(groupId);
  },
);

/// Identifica una conversación puntual, para que el capitán pueda ver el
/// historial completo con un miembro particular.
typedef ConversationKey = ({String groupId, String memberId});

final conversationProvider =
    FutureProvider.family<List<ChatMessage>, ConversationKey>((ref, key) async {
  final repo = ref.watch(messagesRepositoryProvider);
  return repo.getConversation(key.groupId, key.memberId);
});
