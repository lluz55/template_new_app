# dl_concept

Sistema de design (tema Material 3 + navegação adaptativa) deste template,
extraído para ser reutilizável sem copy-paste entre projetos.

## Conteúdo

- `AppTheme` / `AppSpacing` (`context.spacing`) — tokens de cor, tipografia e
  espaçamento; Material You via `ColorScheme` injetado por quem consome.
  Também tema botões (`Filled`/`Outlined`/`Text`), inputs, cards, diálogos,
  FAB, `AppBar` (plana, título centralizado), `SnackBar` (flutuante), chips
  e bottom sheets (topo arredondado + handle de arraste) via `*ThemeData`
  — widgets nativos do Flutter, sem wrapper próprio; todos compartilham
  `AppSpacing.radius` como raio de canto.
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
- `AppDismissibleListItem` — item de lista com swipe-to-delete, pedindo
  confirmação (via `showAppConfirmDialog`) antes de remover; complementa,
  não substitui, uma ação de remover por botão (swipe é touch-only, então
  quem consome ainda precisa de outra forma de remover para mouse/teclado).
  Usado em `ItemsScreen` junto com o botão de remover já existente.
- `showAppBottomSheet` — modal bottom sheet com a identidade visual do
  tema; ponto único de entrada, irmão dos `showApp*Dialog`, para nenhuma
  tela reconfigurar `isScrollControlled`/shape na mão.
- `AppSectionHeader` — rótulo de seção + ação opcional à direita, para
  agrupar conteúdo (configurações, categorias, listas agrupadas) em
  qualquer tipo de app.
- `AppBadge` — selo pequeno de contagem/status (ponto simples sem
  `count`, número com `99+` acima de 99) — ex.: notificações não lidas.

Os últimos três (`showAppBottomSheet`, `AppSectionHeader`, `AppBadge`) são
genéricos por design — nenhum app consumidor deste template usa eles
ainda. Ver "Escopo" abaixo.

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

## Escopo

Duas categorias de componente convivem aqui, de propósito:

1. **Extraídos de duplicação real** no app de referência (ex.:
   `showAppTextInputDialog`, `AppDismissibleListItem`) — o caminho
   padrão: nada entra sem um motivo concreto no código que já existe.
2. **Genéricos, não amarrados ao domínio do app de referência** (uma
   lista de itens) — o app de referência é só *um* dos projetos que este
   template pode virar; outros (ex.: um app de configurações, um
   dashboard) precisam de peças que uma lista de tarefas nunca vai usar
   (`AppBadge`, `AppSectionHeader`, chips). Esses entram com a mesma
   régua de qualidade (tema/tokens, testados, documentados aqui) mas sem
   exigir um consumidor no app de referência primeiro.

O que **não** entra em nenhuma categoria: componente decorativo sem uso
claro em nenhum tipo de app plausível, ou reimplementação de um widget
que o Flutter/Material 3 já cobre bem sozinho (prefira temar o widget
nativo — ver `AppTheme` — a envelopar).
