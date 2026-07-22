---
type: log
---

# Log de curadoria do conhecimento

Histórico de mudanças relevantes no bundle OKF (`docs/okf/`). Cada entrada:
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

## 2026-07-19

- Bundle movido de `knowledge/` para `docs/okf/` (todas as referências em
  SPEC.md, AGENTS.md, README.md, CHANGELOG.md, `scripts/check-okf.sh`,
  `scripts/check-protocol-parity.sh`, `scripts/rename-template.sh` e
  `app/pubspec.yaml` atualizadas). Motivo: alinhar o caminho do bundle à
  convenção `docs/okf/` esperada pelo workflow de agente do projeto.
- Adicionado `tasks`: rastreamento de trabalho pendente em dois níveis —
  marcadores `TODO(fase-N)`/`"Fase N"` inline no código (granular) e um
  arquivo por fase em `docs/okf/tasks/` (`01-fundacao.md` … `06-polimento.md`
  + `index.md` com o resumo de progresso), amarrados às 6 fases do SPEC §17.
  Motivo: dar visão de progresso por fase sem perder o detalhe granular já
  coberto por `scripts/list-todos.sh`; os dois níveis devem ficar
  sincronizados ao fechar sub-tarefas.
- Tema e navegação adaptativa extraídos de `app/lib/ui/theme/` e
  `app/lib/ui/nav/` para o pacote reutilizável `packages/dl_concept/`
  (consumido pelo app via path dependency em `app/pubspec.yaml`), atualizando
  `theming.md`, `ui-adaptive.md` e `docs/okf/tasks/01-fundacao.md`. Motivo:
  permitir que outros projetos (instanciados deste template ou não)
  reaproveitem o design system sem copy-paste, via git dependency apontando
  pro subdiretório `packages/dl_concept`. Escopo v1 é só relocação do que já
  existia — sem componentes novos.

## 2026-07-22

- Atualizado `testing`: nova armadilha — `sqflite_common_ffi` (isolate real
  por trás de toda consulta) trava indefinidamente dentro de `testWidgets`,
  mesmo com `tester.runAsync()`, sem lançar exceção. Descoberta investigando
  um relato de "nenhum componente novo aparece na tela inicial": não havia
  bug — nenhum teste populava `ItemsScreen` com dados reais antes
  (`adaptive_nav_test.dart` só cobre a shell de navegação, com lista sempre
  vazia). Corrigido testando `ItemsScreen` contra um `ItemRepository` fake
  (`app/test/widget/items_screen_test.dart`), que prova a árvore renderiza
  `Card`/`AppDismissibleListItem` corretamente com dados — sem depender do
  banco real. Motivo: essa armadilha custou várias tentativas de diagnóstico
  (aumentar `pump()`, tentar `runAsync()`) antes de identificar que o
  problema era do binding de teste, não do código; vale documentar antes que
  alguém repita o mesmo caminho.
