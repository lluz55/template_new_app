import 'package:flutter/material.dart';

/// Mostra um modal bottom sheet com a identidade visual do design system
/// (via `BottomSheetThemeData` em `AppTheme` — topo arredondado, handle de
/// arraste). Ponto único de entrada, irmão de [showAppTextInputDialog]/
/// [showAppConfirmDialog], para nenhuma tela reconfigurar
/// `isScrollControlled`/shape na mão.
///
/// Use [isScrollControlled] quando o conteúdo for maior que ~metade da
/// tela (ex.: um formulário) — sem isso, o sheet fica limitado a essa
/// altura e o conteúdo pode cortar.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    builder: builder,
  );
}
