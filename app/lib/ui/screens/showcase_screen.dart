import 'package:dl_concept/dl_concept.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../l10n/gen/app_localizations.dart';

/// Vitrine dos widgets de `package:dl_concept` — botões, chips, selos,
/// cards e diálogos temados lado a lado com a lista de itens de verdade
/// (a última seção), que continua sendo o scaffold de referência do
/// SPEC §1: exercita a plumbing de persistência/CRDT/sync de ponta a
/// ponta, não só exemplos estáticos. Strings vêm do sistema de i18n
/// (SPEC §9.2) — nunca literal aqui.
class ShowcaseScreen extends ConsumerWidget {
  const ShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsProvider);
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;
    final sectionPadding = EdgeInsets.symmetric(horizontal: spacing.md);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navShowcase)),
      body: ListView(
        padding: EdgeInsets.only(bottom: spacing.lg),
        children: [
          AppSectionHeader(title: l10n.showcaseButtonsTitle),
          Padding(
            padding: sectionPadding,
            child: Wrap(
              spacing: spacing.sm,
              runSpacing: spacing.sm,
              children: [
                FilledButton(onPressed: () {}, child: Text(l10n.actionConfirm)),
                OutlinedButton(
                  onPressed: () {},
                  child: Text(l10n.actionCancel),
                ),
                TextButton(onPressed: () {}, child: Text(l10n.actionClose)),
              ],
            ),
          ),
          AppSectionHeader(title: l10n.showcaseChipsTitle),
          Padding(
            padding: sectionPadding,
            child: _ChipsDemo(l10n: l10n),
          ),
          AppSectionHeader(title: l10n.showcaseBadgesTitle),
          Padding(
            padding: sectionPadding,
            child: Row(
              children: [
                const AppBadge(),
                SizedBox(width: spacing.lg),
                const AppBadge(count: 3),
                SizedBox(width: spacing.lg),
                const AppBadge(count: 150),
              ],
            ),
          ),
          AppSectionHeader(title: l10n.showcaseCardsTitle),
          Padding(
            padding: sectionPadding,
            child: Column(
              children: [
                Card(
                  child: ListTile(
                    title: Text(l10n.showcaseCardOneTitle),
                    subtitle: Text(l10n.showcaseCardOneSubtitle),
                  ),
                ),
                SizedBox(height: spacing.sm),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.star_outline),
                    title: Text(l10n.showcaseCardTwoTitle),
                    subtitle: Text(l10n.showcaseCardTwoSubtitle),
                  ),
                ),
              ],
            ),
          ),
          AppSectionHeader(title: l10n.showcaseDialogsTitle),
          Padding(
            padding: sectionPadding,
            child: Wrap(
              spacing: spacing.sm,
              runSpacing: spacing.sm,
              children: [
                OutlinedButton(
                  onPressed: () => _openTextDialog(context, l10n),
                  child: Text(l10n.showcaseOpenTextDialogAction),
                ),
                OutlinedButton(
                  onPressed: () => _openConfirmDialog(context, l10n),
                  child: Text(l10n.showcaseOpenConfirmDialogAction),
                ),
                OutlinedButton(
                  onPressed: () => _openBottomSheet(context, l10n),
                  child: Text(l10n.showcaseOpenBottomSheetAction),
                ),
              ],
            ),
          ),
          AppSectionHeader(title: l10n.showcaseListTitle),
          ...itemsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return [
                  AppEmptyState(
                    icon: Icons.checklist_outlined,
                    message: l10n.itemsEmptyState,
                  ),
                ];
              }
              return [
                for (final item in items)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      spacing.md,
                      0,
                      spacing.md,
                      spacing.sm,
                    ),
                    child: AppDismissibleListItem(
                      key: ValueKey(item.id),
                      confirmTitle: l10n.itemDeleteConfirmTitle,
                      confirmMessage: l10n.itemDeleteConfirmMessage(item.title),
                      cancelLabel: l10n.actionCancel,
                      confirmLabel: l10n.itemRemoveTooltip,
                      onConfirmedDismiss: () => _removeItem(
                        context,
                        ref,
                        l10n,
                        id: item.id,
                        title: item.title,
                      ),
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: CheckboxListTile(
                          value: item.done,
                          title: Text(item.title),
                          onChanged: (done) => ref
                              .read(itemRepositoryProvider)
                              .toggleDone(item.id, done: done ?? false),
                          secondary: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: l10n.itemRemoveTooltip,
                            onPressed: () => _confirmAndRemoveItem(
                              context,
                              ref,
                              l10n,
                              id: item.id,
                              title: item.title,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ];
            },
            error: (error, stack) => [
              AppEmptyState(
                icon: Icons.error_outline,
                message: l10n.itemsError(error.toString()),
                iconColor: Theme.of(context).colorScheme.error,
              ),
            ],
            loading: () => [
              const Center(child: CircularProgressIndicator()),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context, ref, l10n),
        tooltip: l10n.itemAddTooltip,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openTextDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final value = await showAppTextInputDialog(
      context,
      title: l10n.showcaseTextDialogTitle,
      hint: l10n.showcaseTextDialogHint,
      cancelLabel: l10n.actionCancel,
      confirmLabel: l10n.actionConfirm,
    );
    if (value != null && context.mounted) {
      showAppSnackBar(context, l10n.showcaseTextDialogResultMessage(value));
    }
  }

  Future<void> _openConfirmDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.showcaseConfirmDialogTitle,
      message: l10n.showcaseConfirmDialogMessage,
      cancelLabel: l10n.actionCancel,
      confirmLabel: l10n.actionConfirm,
    );
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      confirmed ? l10n.showcaseConfirmedMessage : l10n.showcaseCancelledMessage,
    );
  }

  Future<void> _openBottomSheet(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return showAppBottomSheet<void>(
      context,
      builder: (context) => Padding(
        padding: EdgeInsets.all(context.spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.showcaseBottomSheetContent),
            SizedBox(height: context.spacing.md),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.actionClose),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddItemDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final title = await showAppTextInputDialog(
      context,
      title: l10n.itemDialogTitle,
      hint: l10n.itemDialogHint,
      cancelLabel: l10n.actionCancel,
      confirmLabel: l10n.actionAdd,
    );

    if (title != null && title.trim().isNotEmpty) {
      await ref.read(itemRepositoryProvider).add(title.trim());
    }
  }

  /// Pede confirmação e remove — usado pelo botão de remover. O swipe-to-
  /// delete (`AppDismissibleListItem`) já pede sua própria confirmação
  /// antes de chamar [_removeItem] direto, sem passar por aqui.
  Future<void> _confirmAndRemoveItem(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n, {
    required String id,
    required String title,
  }) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.itemDeleteConfirmTitle,
      message: l10n.itemDeleteConfirmMessage(title),
      cancelLabel: l10n.actionCancel,
      confirmLabel: l10n.itemRemoveTooltip,
      destructive: true,
    );

    if (!confirmed || !context.mounted) return;
    await _removeItem(context, ref, l10n, id: id, title: title);
  }

  Future<void> _removeItem(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n, {
    required String id,
    required String title,
  }) async {
    await ref.read(itemRepositoryProvider).remove(id);
    if (context.mounted) {
      showAppSnackBar(context, l10n.itemRemovedMessage(title));
    }
  }
}

/// `FilterChip`s com estado de seleção local — só pra demonstrar o tema
/// de chip do `dl_concept`, sem ligação com nenhum estado do app.
class _ChipsDemo extends StatefulWidget {
  const _ChipsDemo({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_ChipsDemo> createState() => _ChipsDemoState();
}

class _ChipsDemoState extends State<_ChipsDemo> {
  final _selected = <int>{0};

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.spacing.sm,
      children: [
        for (var i = 1; i <= 3; i++)
          FilterChip(
            label: Text(widget.l10n.showcaseChipLabel(i)),
            selected: _selected.contains(i),
            onSelected: (selected) => setState(() {
              if (selected) {
                _selected.add(i);
              } else {
                _selected.remove(i);
              }
            }),
          ),
      ],
    );
  }
}
