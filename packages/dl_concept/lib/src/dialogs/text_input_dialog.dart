import 'package:flutter/material.dart';

/// Mostra um `AlertDialog` com um único `TextField` e as ações
/// cancelar/confirmar — o padrão repetido por telas que pedem um texto
/// curto ou multilinha ao usuário (título de item, lista de relays, etc.).
///
/// Retorna o texto digitado ao confirmar, ou `null` se o usuário cancelar
/// (botão, barrier ou botão voltar). Não faz `trim()`/validação — quem
/// chama decide o que fazer com o resultado.
Future<String?> showAppTextInputDialog(
  BuildContext context, {
  required String title,
  required String cancelLabel,
  required String confirmLabel,
  String? hint,
  String initialText = '',
  int minLines = 1,
  int maxLines = 1,
  bool autofocus = true,
}) {
  final controller = TextEditingController(text: initialText);
  final singleLine = maxLines == 1;

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: autofocus,
        minLines: minLines,
        maxLines: maxLines,
        decoration: InputDecoration(hintText: hint),
        onSubmitted:
            singleLine ? (value) => Navigator.of(context).pop(value) : null,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
