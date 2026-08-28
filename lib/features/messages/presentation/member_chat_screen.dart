import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/message.dart';
import 'messages_controller.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_composer.dart';

/// Chat de un miembro común con el/los capitán(es) del grupo — su única
/// conversación posible (no puede elegir con quién hablar, siempre es
/// "con el capitán").
class MemberChatScreen extends ConsumerStatefulWidget {
  const MemberChatScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<MemberChatScreen> createState() => _MemberChatScreenState();
}

class _MemberChatScreenState extends ConsumerState<MemberChatScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

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
      await repo.sendMessage(widget.groupId, text);
      _controller.clear();
      ref.invalidate(myConversationProvider(widget.groupId));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(myConversationProvider(widget.groupId));
    final currentUserId = ref.watch(authControllerProvider).valueOrNull?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Mensaje al capitán')),
      body: Column(
        children: [
          Expanded(
            child: AsyncValueWidget<List<ChatMessage>>(
              value: messagesAsync,
              onRetry: () => ref.invalidate(myConversationProvider(widget.groupId)),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Todavía no le escribiste nada al capitán. Mandale un mensaje.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
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
