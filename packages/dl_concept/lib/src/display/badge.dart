import 'package:flutter/material.dart';

/// Selo pequeno para contagem ou status (ex.: notificações não lidas,
/// indicador de "novo"). Sem [count], vira um ponto simples; com [count],
/// mostra o número (`99+` acima de 99). Genérico — não amarrado a nenhum
/// domínio de app específico.
class AppBadge extends StatelessWidget {
  const AppBadge({super.key, this.count, this.color});

  /// `null` mostra um ponto simples em vez de um número.
  final int? count;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = color ?? colorScheme.error;
    final label = switch (count) {
      null => null,
      > 99 => '99+',
      final n => '$n',
    };

    if (label == null) {
      return Container(
        width: 8,
        height: 8,
        decoration:
            BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      );
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: colorScheme.onError,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );
  }
}
