---
type: architecture-decision
---

# Sistema de temas (design tokens)

## Decisão

Existe um sistema de temas único em `app/lib/ui/theme/` — cor, tipografia e
espaçamento nunca são hardcoded em widgets. Base: `ColorScheme.fromSeed`
(Material 3) com Material You via `dynamic_color` (`DynamicColorBuilder`)
quando o SO expõe paleta dinâmica; fallback determinístico por seed color
nos demais casos (ver `AppTheme`). Tokens de espaçamento/raio vivem num
`ThemeExtension` próprio (`AppSpacing`), acessível via `context.spacing`.
Light e dark são sempre implementados em paralelo — nunca uma feature só
com um dos dois.

## Por quê

Tratado como sistema desde o início (não retrofit) porque cor/spacing
soltos pelo código são o tipo de dívida técnica que se espalha rápido e
fica cara de consolidar depois — cada widget vira um lugar a mais para
caçar quando o tema muda.

## Onde isso vive no código

`app/lib/ui/theme/app_theme.dart` (`AppTheme.light/dark`),
`app/lib/ui/theme/app_spacing.dart` (`AppSpacing`, `context.spacing`),
wiring de Material You em `app/lib/main.dart` (`DynamicColorBuilder`).

Relacionado: [ui-adaptive.md](ui-adaptive.md), [i18n.md](i18n.md) (mesma
lógica de "nunca hardcode, sempre token/recurso central" aplicada a texto).
