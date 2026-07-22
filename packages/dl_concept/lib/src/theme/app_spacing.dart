import 'dart:ui';

import 'package:flutter/material.dart';

/// Tokens de espaçamento/raio — nunca hardcode um valor de espaçamento num
/// widget; adicione/reuse um token aqui. Acesso via `context.spacing`
/// (extension abaixo).
@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    this.xs = 4,
    this.sm = 8,
    this.md = 16,
    this.lg = 24,
    this.xl = 32,
    this.radius = 12,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double radius;

  @override
  AppSpacing copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? radius,
  }) =>
      AppSpacing(
        xs: xs ?? this.xs,
        sm: sm ?? this.sm,
        md: md ?? this.md,
        lg: lg ?? this.lg,
        xl: xl ?? this.xl,
        radius: radius ?? this.radius,
      );

  @override
  AppSpacing lerp(ThemeExtension<AppSpacing>? other, double t) {
    if (other is! AppSpacing) return this;
    return AppSpacing(
      xs: lerpDouble(xs, other.xs, t)!,
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
      radius: lerpDouble(radius, other.radius, t)!,
    );
  }
}

extension AppSpacingContext on BuildContext {
  AppSpacing get spacing =>
      Theme.of(this).extension<AppSpacing>() ?? const AppSpacing();
}
