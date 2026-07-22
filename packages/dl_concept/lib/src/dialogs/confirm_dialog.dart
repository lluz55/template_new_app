import 'package:flutter/material.dart';

/// Mostra um `AlertDialog` de confirmação simples — título + mensagem
/// opcional + ações cancelar/confirmar. Retorna `true` só se o usuário
/// confirmar; cancelar, fechar pelo barrier ou voltar retornam `false`.
///
/// Use [destructive] para ações irreversíveis (ex.: apagar) — troca a cor
/// do botão de confirmar para `colorScheme.error`, mesma convenção do
/// Material 3 para chamar atenção antes de uma ação que não tem "desfazer".
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String cancelLabel,
  required String confirmLabel,
  String? message,
  bool destructive = false,
}) async {
  final colorScheme = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
