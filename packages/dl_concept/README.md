# dl_concept

Sistema de design (tema Material 3 + navegação adaptativa) deste template,
extraído para ser reutilizável sem copy-paste entre projetos.

## Conteúdo

- `AppTheme` / `AppSpacing` (`context.spacing`) — tokens de cor, tipografia e
  espaçamento; Material You via `ColorScheme` injetado por quem consome.
- `AppBreakpoint` / `breakpointForWidth` — breakpoints Material 3
  (compact/medium/expanded).
- `AdaptiveScaffold` / `AdaptiveDestination` — shell de navegação adaptativa
  (`NavigationBar`/`NavigationRail`/`NavigationDrawer`), integrada a
  `StatefulNavigationShell` do `go_router`.

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
