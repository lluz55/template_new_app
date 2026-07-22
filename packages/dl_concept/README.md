# dl_concept

Sistema de design (tema Material 3 + navegação adaptativa) deste template,
extraído para ser reutilizável sem copy-paste entre projetos.

## Conteúdo

- `AppTheme` / `AppSpacing` (`context.spacing`) — tokens de cor, tipografia e
  espaçamento; Material You via `ColorScheme` injetado por quem consome.
  Também tema botões (`Filled`/`Outlined`/`Text`), inputs, cards, diálogos,
  FAB, `AppBar` (plana, título centralizado) e `SnackBar` (flutuante) via
  `*ThemeData` — widgets nativos do Flutter, sem wrapper próprio; todos
  compartilham `AppSpacing.radius` como raio de canto.
- `AppBreakpoint` / `breakpointForWidth` — breakpoints Material 3
  (compact/medium/expanded).
- `AdaptiveScaffold` / `AdaptiveDestination` — shell de navegação adaptativa
  (`NavigationBar`/`NavigationRail`/`NavigationDrawer`), integrada a
  `StatefulNavigationShell` do `go_router`.
- `showAppTextInputDialog` — `AlertDialog` com um `TextField` e ações
  cancelar/confirmar; extraído de `ItemsScreen`/`SettingsScreen`, que
  repetiam o mesmo padrão para pedir um texto curto ou multilinha.
- `showAppConfirmDialog` — `AlertDialog` de confirmação simples
  (título/mensagem opcional + cancelar/confirmar), com variante
  `destructive` (botão de confirmar em `colorScheme.error`) para ações
  irreversíveis; usado em `ItemsScreen` antes de remover um item.
- `AppEmptyState` — ícone + mensagem centralizados, para o par "sem
  dados"/"erro ao carregar" que aparece nos dois ramos não-`loading` de
  qualquer `AsyncValue.when()`; `iconColor` diferencia o caso de erro.
- `showAppSnackBar` — ponto único de entrada para feedback transitório
  (esconde a `SnackBar` anterior antes de mostrar a próxima); usado em
  `ItemsScreen` para confirmar a remoção de um item.

## Uso

```yaml
# pubspec.yaml do app consumidor
dependencies:
  dl_concept:
    path: ../packages/dl_concept
    # ou, em outro repo:
    # git:
    #   url: <url-deste-repo>
    #   path: packages/dl_concept
```

```dart
import 'package:dl_concept/dl_concept.dart';
```

Escopo: só componentes que já existem em algum app consumidor — nada
especulativo. Cresce organicamente conforme o design system evolui.
