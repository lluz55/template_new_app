import 'package:dl_concept/dl_concept.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../l10n/gen/app_localizations.dart';

/// Scaffold de referência (SPEC §1): lista de itens local, criar/editar/
/// apagar, exercitando a plumbing de persistência + CRDT. Sync via Nostr é
/// transparente para esta tela — ela só fala com [itemsProvider]. Strings
/// vêm do sistema de i18n (SPEC §9.2) — nunca literal aqui.
class ItemsScreen extends ConsumerWidget {
  const ItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navItems)),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Padding(
              padding: EdgeInsets.all(context.spacing.lg),
              child: Center(child: Text(l10n.itemsEmptyState)),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.md,
              vertical: context.spacing.sm,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: EdgeInsets.only(bottom: context.spacing.sm),
                child: CheckboxListTile(
                  key: ValueKey(item.id),
                  value: item.done,
                  title: Text(item.title),
                  onChanged: (done) => ref
                      .read(itemRepositoryProvider)
                      .toggleDone(item.id, done: done ?? false),
                  secondary: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n.itemRemoveTooltip,
                    onPressed: () =>
                        ref.read(itemRepositoryProvider).remove(item.id),
                  ),
                ),
              );
            },
          );
        },
        error: (error, stack) => Padding(
          padding: EdgeInsets.all(context.spacing.lg),
          child: Center(child: Text(l10n.itemsError(error.toString()))),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context, ref, l10n),
        tooltip: l10n.itemAddTooltip,
        child: const Icon(Icons.add),
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
}
