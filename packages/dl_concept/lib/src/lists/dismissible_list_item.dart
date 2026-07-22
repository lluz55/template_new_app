import 'package:flutter/material.dart';

import '../dialogs/confirm_dialog.dart';
import '../theme/app_spacing.dart';

/// Item de lista com swipe-to-delete: pede confirmação (via
/// [showAppConfirmDialog]) antes de remover — evita apagar por engano com
/// um swipe acidental. Fundo padrão: ícone de lixeira sobre
/// `colorScheme.errorContainer`, com o mesmo raio dos outros componentes.
///
/// **Complementa, não substitui** uma ação de remover por botão: swipe é
/// um gesto touch-only, então quem consome ainda precisa oferecer outra
/// forma de remover para mouse/teclado — nenhuma funcionalidade pode ficar
/// exclusiva de um form factor.
///
/// Exige um [Key] (repassado ao `Dismissible` interno, que exige um) —
/// normalmente o mesmo `ValueKey` já usado no item da lista.
class AppDismissibleListItem extends StatelessWidget {
  const AppDismissibleListItem({
    required Key key,
    required this.confirmTitle,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onConfirmedDismiss,
    required this.child,
    this.confirmMessage,
  }) : super(key: key);

  final String confirmTitle;
  final String? confirmMessage;
  final String cancelLabel;
  final String confirmLabel;

  /// Chamado só depois da confirmação — quem consome faz a remoção de
  /// verdade aqui (ex.: repositório), sem pedir confirmação de novo.
  final VoidCallback onConfirmedDismiss;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final colorScheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: key!,
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showAppConfirmDialog(
        context,
        title: confirmTitle,
        message: confirmMessage,
        cancelLabel: cancelLabel,
        confirmLabel: confirmLabel,
        destructive: true,
      ),
      onDismissed: (_) => onConfirmedDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: spacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(spacing.radius),
        ),
        child: Icon(Icons.delete_outline, color: colorScheme.onErrorContainer),
      ),
      child: child,
    );
  }
}
