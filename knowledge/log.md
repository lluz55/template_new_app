---
type: log
---

# Log de curadoria do conhecimento

Histórico de mudanças relevantes no bundle OKF (`knowledge/`). Cada entrada:
data, o que mudou, por quê.

## 2026-07-11

- Bundle OKF criado junto com o scaffold inicial do template (fundação:
  `flake.nix`, app Flutter, CLI Go, protocolo compartilhado). Conceitos
  iniciais: `environment`, `architecture`, `data-model`, `sync`, `protocol`,
  `security`, `ui-adaptive`, `performance`. Motivo: registrar o "porquê" das
  decisões já tomadas em SPEC.md antes que o código cresça e o contexto se
  perca.
- Adicionados `theming` e `i18n` (SPEC §9.1/§9.2): sistema de temas
  (tokens, Material You via `dynamic_color`) e internacionalização
  (`flutter_localizations`/`intl`, `pt`+`en` desde o início) formalizados
  como requisitos de primeira classe, com wiring real em `app/lib/main.dart`,
  `app/lib/ui/router.dart` e nas telas existentes.
- Adicionado `testing`: convenção de onde cada camada de teste vive e a
  armadilha `pumpAndSettle()` × `CircularProgressIndicator` indeterminado,
  descoberta ao corrigir `app/test/widget/adaptive_nav_test.dart` (o teste
  travava por timeout, não por bug real de sincronização). Motivo: essa
  lição não é óbvia lendo só o código — vale documentar antes que alguém
  reintroduza `pumpAndSettle()` num teste futuro com spinner na árvore.
