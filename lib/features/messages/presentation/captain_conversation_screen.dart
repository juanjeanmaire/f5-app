import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/message.dart';
import 'messages_controller.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_composer.dart';

/// Conversación completa del capitán con un miembro puntual — a diferencia
/// de MemberChatScreen, acá sí hace falta indicar memberId al responder.
class CaptainConversationScreen extends ConsumerStatefulWidget {
  const CaptainConversationScreen({
    super.key,
    required this.groupId,
    required this.memberId,
    this.memberName,
  });

  final String groupId;
  final String memberId;

  /// Pasado por navegación, para el título mientras carga.
  final String? memberName;

  @override
  ConsumerState<CaptainConversationScreen> createState() =>
      _CaptainConversationScreenState();
}

class _CaptainConversationScreenState extends ConsumerState<CaptainConversationScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  ConversationKey get _key => (groupId: widget.groupId, memberId: widget.memberId);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      final repo = ref.read(messagesRepositoryProvider);
      await repo.sendMessage(widget.groupId, text, memberId: widget.memberId);
      _controller.clear();
      ref.invalidate(conversationProvider(_key));
      ref.invalidate(threadsProvider(widget.groupId));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(conversationProvider(_key));
    final currentUserId = ref.watch(authControllerProvider).valueOrNull?.id;

    return Scaffold(
      appBar: AppBar(title: Text(widget.memberName ?? 'Conversación')),
      body: Column(
        children: [
          Expanded(
            child: AsyncValueWidget<List<ChatMessage>>(
              value: messagesAsync,
              onRetry: () => ref.invalidate(conversationProvider(_key)),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text('Todavía no hay mensajes acá.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) => MessageBubble(
                    message: messages[index],
                    isMine: messages[index].senderId == currentUserId,
                  ),
                );
              },
            ),
          ),
          MessageComposer(controller: _controller, sending: _sending, onSend: _send),
        ],
      ),
    );
  }
}
