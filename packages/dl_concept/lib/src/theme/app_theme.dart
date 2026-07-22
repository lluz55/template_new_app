import 'package:flutter/material.dart';

import 'app_spacing.dart';

/// Sistema de temas único: cores, tipografia e espaçamento nunca são
/// hardcoded em widgets — tudo vem daqui. Toda tela/feature nova consome
/// estes tokens (ou propõe uma extensão neles), nunca um valor solto. Cobre
/// Material You (`dynamicScheme`, tipicamente vindo de um
/// `DynamicColorBuilder` no app consumidor) com fallback determinístico por
/// seed color.
class AppTheme {
  const AppTheme._();

  static const _seedColor = Colors.teal;
  static const _spacing = AppSpacing();

  static ThemeData light({ColorScheme? dynamicScheme}) => ThemeData(
        useMaterial3: true,
        colorScheme: dynamicScheme ??
            ColorScheme.fromSeed(
              seedColor: _seedColor,
              brightness: Brightness.light,
            ),
        extensions: const [_spacing],
      );

  static ThemeData dark({ColorScheme? dynamicScheme}) => ThemeData(
        useMaterial3: true,
        colorScheme: dynamicScheme ??
            ColorScheme.fromSeed(
              seedColor: _seedColor,
              brightness: Brightness.dark,
            ),
        extensions: const [_spacing],
      );
}
