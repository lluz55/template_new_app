import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Ícone + mensagem centralizados, com o espaçamento do design system — o
/// padrão repetido pelo estado "sem dados" e pelo estado "erro ao carregar"
/// de qualquer tela em cima de um `AsyncValue`/`Stream` (mesmo par que
/// aparece nos dois ramos de `itemsAsync.when()` em `ShowcaseScreen`). A
/// diferença entre os dois casos é só o ícone e a cor: passe [iconColor]
/// para o caso de erro (`colorScheme.error`); sem ele, usa
/// `colorScheme.onSurfaceVariant`, neutro para o caso "vazio, mas sem erro".
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.iconColor,
  });

  final IconData icon;
  final String message;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: iconColor ?? theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: spacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
