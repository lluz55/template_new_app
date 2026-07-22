# AGENTS.md

App offline-first multiplataforma (Android/Linux/Web) com sync descentralizado
via Nostr. A especificação-fonte é [SPEC.md](/SPEC.md) — leia-a antes de
mudanças arquiteturais.

## Stack

- **App:** Flutter (Material 3), Dart. Estado: Riverpod. Rotas: go_router.
- **Tema e navegação adaptativa:** pacote local `packages/dl_concept/`
  (`package:dl_concept`) — `AppTheme`/`AppSpacing`, `AdaptiveScaffold`,
  `breakpointForWidth`. Material You via `dynamic_color`, wireado em
  `app/lib/main.dart`. **i18n:** `flutter_localizations`/`intl`, `pt`+`en`
  desde o início. Ver [SPEC §9.1/§9.2].
- **Persistência:** `sqlite_crdt` (HLC/LWW) + SQLCipher.
- **Sync:** cliente Nostr em Dart, payloads cifrados NIP-44. Ver [SPEC §7].
- **CLI opcional:** Go + `go-nostr`.
- **Build:** Nix flakes. **Conhecimento:** bundle OKF em `docs/okf/`.

## Ambiente de desenvolvimento (Nix/NixOS obrigatório)

- **NixOS é o ambiente de desenvolvimento obrigatório** deste projeto (ou, no
  mínimo, Nix ≥ 2.18 com flakes habilitados sobre outra distro/macOS). Ver
  [SPEC §13.1].
- **Toda** ação de build/lint/teste roda dentro de um `nix develop` — nunca
  com `flutter`, `go` ou Android SDK instalados manualmente no sistema.
- **Android SDK/NDK vêm exclusivamente do flake input do GitHub**
  `github:tadfisher/android-nixpkgs` (ver [SPEC §13.2]) — nunca do
  `androidenv` cru do nixpkgs, nem de Android Studio/`sdkmanager` instalado à
  mão. Versões de build-tools/platform/NDK são pinadas explicitamente no
  `flake.nix`.
- `nixpkgs.config.allowUnfree = true` é necessário (licença do Android SDK).
- Atualizar o SDK: `nix flake lock --update-input android-nixpkgs` + bump
  explícito das versões pinadas — nunca edição manual do SDK já materializado.

## Comandos

```bash
# ambientes (Nix)
nix develop .#app-linux     # Flutter + deps Linux
nix develop .#android       # SDK/NDK Android
nix develop .#cli           # Go
nix develop .#tools         # gitleaks (scripts/check-secrets.sh)

# primeira vez neste checkout (idempotente — não faz nada se já existir)
scripts/bootstrap-platforms.sh   # gera app/android, app/linux, app/web

# visão rápida do que falta implementar, agrupado por fase (SPEC §17)
scripts/list-todos.sh

# instanciar o template para um projeto novo (rename em todo o repo) e
# bump de versão (SPEC §15) — nenhum dos dois commita/dá push sozinho
scripts/rename-template.sh --dry-run novo_nome
scripts/bump-version.sh 0.2.0

# rodar
cd app && flutter run -d linux        # ou -d chrome / apk

# checagens (rode ANTES de commitar) — cobre app/ e packages/dl_concept/
(cd app && dart format . && dart analyze --fatal-infos)
(cd packages/dl_concept && dart format . && dart analyze --fatal-infos)
scripts/perf-check.sh                 # perf, OKF, versão↔tag (ver SPEC §11.4) — já roda os dois via check-flutter.sh
scripts/check-secrets.sh              # gitleaks — nunca commitar chave/nsec
cd cli && go vet ./... && go test ./...

# teste único (preferir escopo estreito)
cd app && flutter test test/caminho_do_teste.dart
```

### Convenções ao rodar comandos Flutter/Dart

- **`flutter analyze`/`dart analyze`**: ao ler a saída, foque nos **erros** —
  não pare a tarefa para corrigir warnings/infos por conta própria. Só
  trate warnings se isso for **explicitamente pedido** (ex.: "corrija os
  warnings do analyze"). Isso não muda os scripts do repo: `check-flutter.sh`
  e o CI continuam usando `dart analyze --fatal-infos` de propósito (padrão
  de qualidade do projeto) — a diferença é só o que exige ação imediata
  durante o trabalho.
- **Comandos `flutter`** que suportam `--[no-]pub` (`test`, `run`, `build
  apk/web/linux`, `analyze`, entre outros — `dart analyze`/`dart format` não
  têm esse flag, já não rodam pub get): use **`--no-pub`** por padrão, já
  que `flutter pub get` já roda explicitamente quando necessário (ver
  Comandos acima). Só omita `--no-pub` (ou rode `flutter pub get` antes)
  quando `pubspec.yaml`/`pubspec.lock` mudaram desde a última execução, ou
  quando pedirem explicitamente.

## Estrutura (capacidades, não caminhos fixos)

- Telas vivem em `app/lib/ui/`. Navegação adaptativa (barra/rail/drawer) e
  tema (design tokens) vivem no pacote `packages/dl_concept/`
  (`package:dl_concept`), consumido via path dependency — não redefina esses
  componentes no app, estenda o pacote.
- i18n (`.arb` + código gerado) em `app/lib/l10n/` — config em `app/l10n.yaml`.
- Store local + repositórios em `app/lib/data/`; sync/Nostr em `app/lib/sync/`.
- Chaves e cripto em `app/lib/crypto/`.
- Protocolo compartilhado (Dart↔Go) em `shared/`.
- Detalhes e o "porquê" das decisões: bundle OKF em `docs/okf/`.

## Ao alterar/inserir código: segurança e performance

Segurança (ver [SPEC §10]):
- **Nunca** logar, serializar em texto plano ou versionar a chave privada Nostr,
  nsec, ou a chave do SQLCipher.
- Todo payload publicado é cifrado (NIP-44); toda assinatura recebida é
  verificada. Não confie em relays.
- Não introduza telemetria nem tráfego de rede fora dos relays configurados.

Performance (ver [SPEC §11]):
- A UI só fala com o store local; **nunca** bloquear a thread de UI com I/O de
  rede, JSON grande ou cripto — use isolates (`compute`).
- Use `const` em widgets; componentes pequenos; diffs pequenos.
- Se adicionar dependência pesada, meça o impacto no bundle web/APK
  (`scripts/check-web-bundle.sh`, `scripts/check-apk-size.sh`).

## Design e código

Siga o guideline já estabelecido no [SPEC §9] e nos conceitos de `docs/okf/`:
- **Não** hardcode cores/spacing — use os tokens de `package:dl_concept`
  (`ColorScheme`/`AppTheme`, `AppSpacing` via `context.spacing`). Ver [SPEC §9.1].
- **Não** hardcode string de UI — toda string visível ao usuário vai em
  `app/lib/l10n/app_pt.arb` **e** `app_en.arb`, acessada via
  `AppLocalizations.of(context)!`. Ver [SPEC §9.2]. Exceção: texto puramente
  de domínio/protocolo (não visível na UI) não entra no i18n.
- Widgets funcionais; evite `Container` desnecessário; prefira o componente
  existente a criar um novo.
- Nav adaptativa por breakpoint (compact→`NavigationBar`, expanded→`NavigationDrawer`).
- **Toda tela/feature nova precisa funcionar bem em celular, tablet e
  desktop** (compact/medium/expanded) — não só "não quebrar". Antes de
  considerar concluído, verifique nos três breakpoints: alvos de toque
  adequados em compact/medium, suporte a mouse/teclado (hover, foco, atalhos)
  em expanded, e nenhuma funcionalidade perdida entre form factors.
- Toda tela nova cobre **light e dark** e as duas locales (`pt`/`en`) — não é
  opcional, é parte de "concluído" tanto quanto os três breakpoints.

## Conhecimento do domínio: padrão OKF

**Obrigatório:** antes de escrever código — em especial mudanças que toquem
arquitetura, protocolo, segurança, sync ou modelo de dados — **leia, entenda
e siga** o bundle OKF em `docs/okf/`. Comece por
[`docs/okf/index.md`](/docs/okf/index.md) e os conceitos relevantes em
`docs/okf/concepts/`; eles são a fonte de verdade sobre o "porquê" das
decisões já tomadas. Não decida algo já coberto ali sem consultar antes, e
não contradiga um conceito existente sem atualizá-lo.

Ao **criar, editar ou remover** conhecimento (decisões, protocolo, contexto do
domínio), faça no bundle OKF em `docs/okf/` (ver [SPEC §8.1]):
- Cada conceito é um `.md` com frontmatter YAML e campo **`type`** obrigatório.
- Mantenha `index.md` e `log.md` (reservados); registre mudanças relevantes no
  `log.md`.
- Use cross-links relativos entre conceitos.
- Valide com `scripts/check-okf.sh` antes de commitar.

## Versionamento e releases

- A versão é única em `app/pubspec.yaml` (SemVer) e **o app exibe a versão do
  release corrente** em runtime (`package_info_plus`) — nunca hardcoded.
- Em release, a versão **deve** bater com a tag Git `vX.Y.Z` (checado no CI).
- Use `scripts/bump-version.sh X.Y.Z` para atualizar `pubspec.yaml`,
  `flake.nix` (`packages.cli.version`) e mover `[Unreleased]` do
  `CHANGELOG.md` para uma seção datada — não edite esses três a mão para não
  desalinhar. `scripts/bump-version.sh --tag` cria a tag local (sem push).
- Releases são feitos no GitHub com a **`gh` CLI**, anexando os artefatos e
  `checksums.txt` (ver [SPEC §15]):
  ```bash
  gh release create "v${VERSION}" --notes-file CHANGELOG.md \
    build/*.apk build/app-linux.tar.gz build/web.tar.gz build/cli-* checksums.txt
  ```

## Git

- Commits em **Conventional Commits** (`feat:`, `fix:`, `perf:`, `docs:` …).
- PR só entra com `dart format`, `dart analyze` e `scripts/perf-check.sh` verdes.
- **REGRA MANDATÓRIA, sem exceção:** nenhuma mensagem de commit (nem PR)
  pode conter `Co-Authored-By`, "Generated with", assinatura de ferramenta
  de IA, ou qualquer variação que atribua coautoria a um agente/LLM —
  mesmo que o comportamento padrão do agente/ferramenta usado sugira
  adicionar isso automaticamente. Se a ferramenta inserir isso por padrão,
  **remova antes de commitar**. Autoria do commit é sempre só do humano
  responsável pela sessão.

## Fronteiras

**Pode sem perguntar:** ler arquivos, `dart format`, `dart analyze`, testes
unitários, rodar os scripts de checagem.

**Pergunte antes:** instalar dependências novas, `git push`, apagar arquivos,
mexer em `flake.nix`/lockfiles, alterar o formato do protocolo em `shared/`,
publicar releases, rodar `scripts/rename-template.sh` (reescreve nome de
projeto em ~20 arquivos de uma vez — só faça se pedirem explicitamente).

**Nunca:** commitar segredos/chaves, adicionar telemetria, reduzir verificação
de assinatura ou cifra, hardcodar a versão do app, publicar payload não
cifrado, instalar toolchains (Flutter, Go, Android SDK/NDK) fora do ambiente
Nix, trocar a origem do Android SDK para algo diferente do flake input
`github:tadfisher/android-nixpkgs` sem alinhar antes, hardcodar cor/spacing
fora de `package:dl_concept` (`packages/dl_concept/`), hardcodar string de UI
fora do sistema de i18n (`app/lib/l10n/`), ou **adicionar `Co-Authored-By`/
atribuição de coautoria de IA em commits ou PRs** (ver "Git" acima —
mandatório, sem exceção).

## Quando estiver em dúvida

Não faça mudanças grandes e especulativas. Proponha um plano curto, faça um diff
pequeno, ou abra um PR em rascunho com notas e uma pergunta objetiva.
