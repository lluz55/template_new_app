---
type: task
phase: 6
status: pending
---

# Fase 6 — Polimento

## Escopo (SPEC §17)

Performance (isolates, batching, renderer web), testes de interop, CI,
documentação.

## Sub-tarefas

- [ ] Isolates (`compute`) para I/O de rede/JSON grande/cripto fora da thread
      de UI (ver [performance.md](../concepts/performance.md))
- [ ] Batching de writes/CRDT merge
- [ ] Escolha/config do renderer web (checar `scripts/check-web-bundle.sh`)
- [ ] Teste de interoperabilidade Dart↔Go completo (gera `Changeset` em
      Dart, decifra/decodifica em Go e vice-versa) — depende do protobuf real
      da Fase 4/5, ver [testing.md](../concepts/testing.md)
- [ ] CI cobrindo os scripts de checagem (`check-okf.sh`,
      `check-protocol-parity.sh`, `perf-check.sh`, `check-secrets.sh`)

Ainda sem marcadores `TODO(fase-6)` no código — normal, é a última fase e
depende das anteriores estarem fechadas.

## Onde isso vive no código

`scripts/perf-check.sh`; `scripts/check-web-bundle.sh`;
`scripts/check-apk-size.sh`; `.github/`.

## Relacionado

[performance.md](../concepts/performance.md),
[testing.md](../concepts/testing.md).
