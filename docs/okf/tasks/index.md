---
type: index
---

# Índice de tarefas (fases de implementação — SPEC §17)

Cada fase de [SPEC §17](/SPEC.md#17-fases-de-implementação) tem um arquivo de
tarefa aqui, com escopo, sub-tarefas e status. Isso **complementa**, não
substitui, os marcadores `TODO(fase-N)`/`"Fase N"` no código — os marcadores
são o detalhe granular (linha exata pendente); estes arquivos são a visão de
progresso por fase. Ao concluir sub-tarefas, mantenha os dois em sincronia:
remova o marcador do código **e** marque a sub-tarefa aqui.

Status é atualizado manualmente ao terminar trabalho relevante — confira
`scripts/list-todos.sh --count` antes de marcar uma fase como concluída (deve
retornar zero ocorrências para o número da fase).

## Fases

| # | Task | Status | Progresso |
|---|------|--------|-----------|
| 1 | [Fundação](01-fundacao.md) | ✅ concluída | 4/4 |
| 2 | [Store local](02-store-local.md) | 🔄 em andamento | 2/3 |
| 3 | [Cripto e chaves](03-cripto-e-chaves.md) | 🔄 em andamento | 1/4 |
| 4 | [Sync engine](04-sync-engine.md) | 🔄 em andamento | 1/5 |
| 5 | [Go CLI](05-go-cli.md) | 🔄 em andamento | 2/4 |
| 6 | [Polimento](06-polimento.md) | ⏳ não iniciada | 0/5 |

## Relacionado

[tasks.md](../concepts/tasks.md) (convenção `TODO(fase-N)` +
`scripts/list-todos.sh`), [architecture.md](../concepts/architecture.md).
