import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import 'pixel_icon.dart';

/// Envuelve el patrón repetido de mostrar loading/error/data para un
/// AsyncValue, con un estilo de error consistente en toda la app.
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        final message = error is ApiException ? error.message : 'Ocurrió un error inesperado';
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PixelIcon(PixelIcons.errorOutline, size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                if (onRetry != null) ...[
                  const SizedBox(height: 16),
                  OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
