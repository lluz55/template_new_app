import 'package:dl_concept/dl_concept.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/local/app_database.dart';
import 'data/providers.dart';
import 'l10n/gen/app_localizations.dart';
import 'ui/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Abre o store local antes de `runApp` — a UI já nasce com dados
  // disponíveis, sem tela de loading no caminho feliz (SPEC §11.2:
  // abertura a cargo < 1s).
  final database = await AppDatabase.open();

  runApp(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // Material You (SPEC §9.1): usa a paleta dinâmica do SO quando
    // disponível (Android 12+, Linux/desktop com suporte); cai para o
    // seed color determinístico de AppTheme nos demais casos.
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(dynamicScheme: lightDynamic),
        darkTheme: AppTheme.dark(dynamicScheme: darkDynamic),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: appRouter,
      ),
    );
  }
}
