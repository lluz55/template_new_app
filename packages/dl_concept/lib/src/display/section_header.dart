import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Cabeçalho de seção: rótulo + ação opcional à direita (ex.: "ver tudo",
/// um botão de adicionar). Padrão comum pra agrupar conteúdo em qualquer
/// tipo de app — configurações, categorias, listas agrupadas — não
/// amarrado a nenhum domínio específico.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        spacing.md,
        spacing.lg,
        spacing.md,
        spacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
