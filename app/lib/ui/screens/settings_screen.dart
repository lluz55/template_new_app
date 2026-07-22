import 'package:dl_concept/dl_concept.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/providers.dart';
import '../../l10n/gen/app_localizations.dart';

/// Versão exibida em runtime via `package_info_plus` — nunca hardcoded
/// (SPEC §15). Em build de release, deve bater com a tag Git `vX.Y.Z`
/// (checado no CI, ver .github/workflows/ci.yml). Strings vêm do sistema
/// de i18n (SPEC §9.2).
///
/// Lista de relays (SPEC §7.3): lida/gravada via [relaysProvider] —
/// [RelaySettingsRepository], mesmo store CRDT local do resto do domínio.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final relays = ref.watch(relaysProvider).asData?.value;

    String subtitle;
    if (relays == null) {
      subtitle = l10n.settingsRelaysSubtitle;
    } else if (relays.isEmpty) {
      subtitle = l10n.settingsRelaysEmpty;
    } else {
      subtitle = relays.join(', ');
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsScreenTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: Text(l10n.settingsRelaysTitle),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.edit_outlined),
            onTap: relays == null
                ? null
                : () => _showEditRelaysDialog(context, ref, l10n, relays),
          ),
          const Divider(),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final info = snapshot.data;
              return ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.settingsVersionTitle),
                subtitle: Text(
                  info == null
                      ? l10n.settingsVersionLoading
                      : '${info.version}+${info.buildNumber}',
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showEditRelaysDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<String> currentUrls,
  ) async {
    final result = await showAppTextInputDialog(
      context,
      title: l10n.settingsRelaysDialogTitle,
      hint: l10n.settingsRelaysDialogHint,
      initialText: currentUrls.join('\n'),
      minLines: 3,
      maxLines: 6,
      cancelLabel: l10n.actionCancel,
      confirmLabel: l10n.actionSave,
    );

    if (result == null) return;
    final urls = result
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    await ref.read(relaySettingsRepositoryProvider).setRelays(urls);
  }
}
