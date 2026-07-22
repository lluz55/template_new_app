import 'package:flutter/material.dart';

/// Mostra uma `SnackBar` de texto simples, escondendo a anterior antes —
/// evita empilhar mensagens se o usuário disparar duas ações em sequência
/// rápida (ex.: remover dois itens rapidamente). Ponto único de entrada
/// para feedback transitório, para o app nunca chamar `ScaffoldMessenger`
/// direto em lugares diferentes com comportamentos ligeiramente diferentes.
void showAppSnackBar(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
