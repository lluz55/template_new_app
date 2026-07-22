import 'package:dl_concept/dl_concept.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final entry in {
    'light': AppTheme.light(),
    'dark': AppTheme.dark(),
  }.entries) {
    final brightness = entry.key;
    final theme = entry.value;

    group(brightness, () {
      test('expõe AppSpacing como ThemeExtension', () {
        expect(theme.extension<AppSpacing>(), isNotNull);
      });

      test('botões preenchido/contornado/texto usam o mesmo raio', () {
        final spacing = theme.extension<AppSpacing>()!;
        for (final shape in [
          theme.filledButtonTheme.style?.shape?.resolve({}),
          theme.outlinedButtonTheme.style?.shape?.resolve({}),
          theme.textButtonTheme.style?.shape?.resolve({}),
          theme.floatingActionButtonTheme.shape,
        ]) {
          expect(shape, isA<RoundedRectangleBorder>());
          expect(
            (shape as RoundedRectangleBorder).borderRadius,
            BorderRadius.circular(spacing.radius),
          );
        }
      });

      test('inputs são preenchidos e sem borda em repouso', () {
        final decoration = theme.inputDecorationTheme;
        expect(decoration.filled, isTrue);
        expect(
          (decoration.enabledBorder as OutlineInputBorder).borderSide,
          BorderSide.none,
        );
        expect(
          (decoration.focusedBorder as OutlineInputBorder).borderSide.color,
          theme.colorScheme.primary,
        );
      });

      test('cards são planos (elevation 0) e recortam o conteúdo', () {
        expect(theme.cardTheme.elevation, 0);
        expect(theme.cardTheme.clipBehavior, Clip.antiAlias);
      });

      test('diálogos usam raio maior que botões/inputs', () {
        final spacing = theme.extension<AppSpacing>()!;
        final dialogShape = theme.dialogTheme.shape as RoundedRectangleBorder;
        expect(
          dialogShape.borderRadius,
          BorderRadius.circular(spacing.radius * 2),
        );
      });

      test('AppBar é plana e com título centralizado', () {
        expect(theme.appBarTheme.elevation, 0);
        expect(theme.appBarTheme.centerTitle, isTrue);
      });

      test('SnackBar é flutuante e usa o mesmo raio dos outros componentes',
          () {
        final spacing = theme.extension<AppSpacing>()!;
        expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
        expect(
          (theme.snackBarTheme.shape as RoundedRectangleBorder).borderRadius,
          BorderRadius.circular(spacing.radius),
        );
      });

      test('Chips usam o mesmo raio e não têm borda', () {
        final spacing = theme.extension<AppSpacing>()!;
        expect(
          (theme.chipTheme.shape as RoundedRectangleBorder).borderRadius,
          BorderRadius.circular(spacing.radius),
        );
        expect(theme.chipTheme.side, BorderSide.none);
      });

      test('Bottom sheets arredondam só o topo, com raio maior', () {
        final spacing = theme.extension<AppSpacing>()!;
        final shape = theme.bottomSheetTheme.shape as RoundedRectangleBorder;
        expect(
          shape.borderRadius,
          BorderRadius.vertical(top: Radius.circular(spacing.radius * 2)),
        );
        expect(theme.bottomSheetTheme.showDragHandle, isTrue);
      });
    });
  }
}
