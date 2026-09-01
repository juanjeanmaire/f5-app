import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = Theme.of(context).colorScheme.primary;
    final time = message.createdAt;
    final timeLabel =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMine ? accent : AppColors.navyDeep,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  message.senderDisplayName,
                  style: textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
              message.body,
              style: TextStyle(color: isMine ? AppColors.navyDeep : AppColors.cream),
            ),
            const SizedBox(height: 2),
            Text(
              timeLabel,
              style: textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: (isMine ? AppColors.navyDeep : AppColors.cream).withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
