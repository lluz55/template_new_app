---
type: task
phase: 1
status: done
---

# Fase 1 — Fundação

## Escopo (SPEC §17)

`flake.nix` + devShells; app Flutter com nav adaptativa (barra/rail/drawer) e
a lista de exemplo (só local).

## Sub-tarefas

- [x] `flake.nix` com devShells `app-linux`/`android`/`cli`/`tools`
- [x] Scaffold Flutter com nav adaptativa (`NavigationBar`→`NavigationRail`→`NavigationDrawer`)
- [x] Lista de exemplo local (sem sync ainda)
- [x] Tema/tokens + i18n (`pt`/`en`) wireados desde o início (ver
      [theming.md](../concepts/theming.md), [i18n.md](../concepts/i18n.md))

## Onde isso vive no código

`flake.nix`; `app/lib/ui/`; `packages/dl_concept/` (tema + nav adaptativa,
extraído do app — ver [theming.md](../concepts/theming.md),
[ui-adaptive.md](../concepts/ui-adaptive.md)); `app/lib/l10n/`.

## Relacionado

[architecture.md](../concepts/architecture.md),
[environment.md](../concepts/environment.md).
