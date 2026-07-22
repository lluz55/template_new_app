import 'package:flutter/material.dart';

import 'app_spacing.dart';

/// Sistema de temas único: cores, tipografia e espaçamento nunca são
/// hardcoded em widgets — tudo vem daqui. Toda tela/feature nova consome
/// estes tokens (ou propõe uma extensão neles), nunca um valor solto. Cobre
/// Material You (`dynamicScheme`, tipicamente vindo de um
/// `DynamicColorBuilder` no app consumidor) com fallback determinístico por
/// seed color.
///
/// Identidade visual: em vez do stadium-shape padrão do M3 nos botões, todo
/// componente interativo (botão, input, card, diálogo, FAB) reusa o mesmo
/// raio de canto — [AppSpacing.radius] — como uma "linguagem de forma"
/// única. É a única decisão estética própria do template; o resto
/// (cor, elevação, tipografia base) fica no padrão M3 derivado do
/// `ColorScheme`, para não competir com Material You.
class AppTheme {
  const AppTheme._();

  static const _seedColor = Colors.teal;
  static const _spacing = AppSpacing();

  static ThemeData light({ColorScheme? dynamicScheme}) => _themeFrom(
        dynamicScheme ??
            ColorScheme.fromSeed(
              seedColor: _seedColor,
              brightness: Brightness.light,
            ),
      );

  static ThemeData dark({ColorScheme? dynamicScheme}) => _themeFrom(
        dynamicScheme ??
            ColorScheme.fromSeed(
              seedColor: _seedColor,
              brightness: Brightness.dark,
            ),
      );

  static ThemeData _themeFrom(ColorScheme colorScheme) {
    final componentShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_spacing.radius),
    );
    final buttonPadding = EdgeInsets.symmetric(
      horizontal: _spacing.lg,
      vertical: _spacing.sm,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      extensions: const [_spacing],

      // Botões: mesmo raio/padding para Filled/Outlined/Text — hierarquia
      // vem só de cor (preenchido → contornado → texto), não de forma.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: componentShape,
          padding: buttonPadding,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: componentShape,
          padding: buttonPadding,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: componentShape,
          padding: EdgeInsets.symmetric(
            horizontal: _spacing.md,
            vertical: _spacing.sm,
          ),
        ),
      ),

      // Inputs: preenchidos e sem borda visível em repouso — a cor de
      // preenchimento já indica "isto é editável" sem precisar de contorno
      // competindo com o resto da tela; o anel colorido só aparece em foco
      // (affordance de "estou editando isto agora") ou erro.
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        contentPadding: EdgeInsets.symmetric(
          horizontal: _spacing.md,
          vertical: _spacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_spacing.radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_spacing.radius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_spacing.radius),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_spacing.radius),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_spacing.radius),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),

      // Cards: plano (elevation 0) com cor de superfície tonal em vez de
      // sombra — mais consistente entre light/dark e com Material You
      // (sombra "neutra" ignora a cor dinâmica; tint de superfície não).
      // `clipBehavior` explícito porque o padrão do Card é `Clip.none` — sem
      // isso, o ripple de um filho interativo (ex.: `ListTile` dentro do
      // card) vaza além do canto arredondado.
      cardTheme: CardThemeData(
        shape: componentShape,
        elevation: 0,
        color: colorScheme.surfaceContainer,
        clipBehavior: Clip.antiAlias,
      ),

      // Diálogos: raio maior que botões/inputs — convenção de "superfície
      // grande ganha curva mais suave" — mas ainda derivado do mesmo token,
      // não um valor solto.
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_spacing.radius * 2),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: componentShape,
      ),
    );
  }
}
