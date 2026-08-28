import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/async_value_widget.dart';
import '../domain/message.dart';
import 'messages_controller.dart';

/// Listado de conversaciones que ve el capitán, una fila por miembro que
/// le escribió, con el último mensaje como preview.
class CaptainInboxScreen extends ConsumerWidget {
  const CaptainInboxScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(threadsProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('Mensajes')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(threadsProvider(groupId)),
        child: AsyncValueWidget<List<MessageThread>>(
          value: threadsAsync,
          onRetry: () => ref.invalidate(threadsProvider(groupId)),
          data: (threads) {
            if (threads.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.only(top: 120),
                    child: Center(child: Text('Todavía no te escribió nadie.')),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: threads.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final thread = threads[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        thread.memberName.isNotEmpty ? thread.memberName[0].toUpperCase() : '?',
                      ),
                    ),
                    title: Text(thread.memberName),
                    subtitle: Text(
                      thread.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(
                      '/groups/$groupId/inbox/${thread.memberId}',
                      extra: thread.memberName,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
