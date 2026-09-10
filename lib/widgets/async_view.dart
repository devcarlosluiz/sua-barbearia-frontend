import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/api_exception.dart';
import 'app_states.dart';

/// Renderiza um [AsyncValue] cobrindo os três estados de UX do projeto:
/// carregando, erro (com "Tentar novamente") e conteúdo.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
    this.loading,
    this.emptyMessage,
    this.isEmpty,
    this.emptyIcon = Icons.inbox_rounded,
    this.emptyActionLabel,
    this.onEmptyAction,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final Widget? loading;
  final String? emptyMessage;
  final bool Function(T data)? isEmpty;
  final IconData emptyIcon;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => loading ?? const AppLoading(),
      error: (error, _) => AppErrorState(
        message: error is ApiException
            ? error.message
            : 'Ocorreu um erro inesperado. Tente novamente.',
        onRetry: onRetry,
      ),
      data: (data) {
        if (emptyMessage != null && (isEmpty?.call(data) ?? false)) {
          return AppEmptyState(
            message: emptyMessage!,
            icon: emptyIcon,
            actionLabel: emptyActionLabel,
            onAction: onEmptyAction,
          );
        }
        return builder(data);
      },
    );
  }
}
