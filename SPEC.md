# SPEC.md — Template multiplataforma com sync via Nostr

> Template completo e reprodutível para **Android**, **Linux** e **Web**, com
> sincronização descentralizada via **Nostr**, backend CLI opcional em **Go**,
> e foco em **segurança** e **performance**. UI adaptativa (barra lateral em
> telas grandes, barra inferior em telas pequenas).

---

## 1. Objetivo

Fornecer um ponto de partida *offline-first* e local-first para apps que
sincronizam estado entre os dispositivos do próprio usuário, sem servidor
central obrigatório. A funcionalidade de referência é um **scaffold**: uma
lista de itens simples (criar / editar / apagar) que sincroniza entre
dispositivos, exercitando toda a plumbing de persistência, CRDT e transporte
Nostr. A partir dela, troca-se apenas a camada de domínio.

O template deve funcionar bem — não apenas "rodar" — em **celular, tablet e
desktop**: cada plataforma (Android, Linux, Web) precisa manter paridade de
funcionalidade e uma UX adequada ao tamanho de tela e ao paradigma de entrada
(toque vs. mouse/teclado), sem gambiarras específicas de um único form
factor. Ver §9.

### Não-objetivos

- Não é um app de rede social Nostr; o Nostr é usado apenas como **transporte
  de sincronização** entre os dispositivos do usuário.
- Não visa colaboração multiusuário em tempo real com merge rico de texto
  (isso exigiria Automerge/Loro; ver §6).
- O backend Go **não** é um par CRDT completo — é uma ferramenta auxiliar (§12).

---

## 2. Plataformas-alvo

| Plataforma | Status         | Observações                                        |
|------------|----------------|----------------------------------------------------|
| Android    | 1ª classe      | Chave no Android Keystore                           |
| Linux      | 1ª classe      | GTK; chave no keyring (libsecret)                   |
| Web        | 1ª classe*     | Chave **nunca** no app: NIP-07 / NIP-46 (ver §10)   |
| Go CLI     | opcional       | Backup, automação, nó headless                      |

\* Web é suportada, mas com um modelo de chaves distinto por não haver
armazenamento seguro no navegador.

---

## 3. Stack tecnológica

### App (Flutter / Dart)
- **UI:** Flutter (Material 3)
- **Navegação:** `go_router` (integra com a shell de navegação adaptativa)
- **Estado:** Riverpod
- **Persistência + CRDT:** `sqlite_crdt` (Hybrid Logical Clocks, LWW por campo)
- **Cifra em repouso:** SQLCipher
- **Nostr:** cliente Dart (relays, assinatura, filtros); cifra NIP-44

### Backend (Go, opcional)
- **Nostr:** `go-nostr` (nbd-wtf)
- **CLI:** verbos de backup/sync/export (ver §12)

### Build / reprodutibilidade
- **NixOS é o ambiente de desenvolvimento obrigatório** deste template (ver §13.1).
- **Nix flakes** (`flake.nix`): devShells por alvo + outputs (ver §13)
- **Android SDK/NDK via flake input do GitHub** (`github:tadfisher/android-nixpkgs`),
  nunca instalado manualmente (ver §13.2)

---

## 4. Arquitetura

```
┌───────────────────────────────────────────────────────────┐
│                         UI (Flutter)                        │
│   NavigationBar / NavigationRail / NavigationDrawer         │
│   telas + widgets (Riverpod providers)                      │
├───────────────────────────────────────────────────────────┤
│                     Camada de domínio                       │
│         casos de uso, modelos, validação                    │
├───────────────────────────────────────────────────────────┤
│   Store local (sqlite_crdt + SQLCipher)  ◄── fonte de       │
│   HLC, changesets, snapshots                 verdade da UI  │
├───────────────────────────────────────────────────────────┤
│                     Sync Engine (Dart)                      │
│   snapshot/changeset ↔ eventos Nostr (NIP-44 cifrado)       │
├───────────────────────────────────────────────────────────┤
│                    Transporte Nostr                         │
│   pool de relays (WebSocket), assinatura, filtros           │
└───────────────────────────────────────────────────────────┘
            ▲                                   ▲
            │                                   │
     (relays públicos/privados)          Go CLI (opcional):
                                         backup / import / export
```

Princípio central: **a UI só fala com o store local.** A sincronização é
assíncrona e em segundo plano. O app é totalmente funcional offline.

---

## 5. Estrutura do repositório

```
.
├── app/                 # Flutter (Android/Linux/Web)
│   ├── lib/
│   │   ├── ui/          # telas (nav adaptativa e tema vêm de packages/dl_concept/, ver §9.1)
│   │   ├── domain/      # modelos, casos de uso
│   │   ├── data/        # store local (sqlite_crdt), repositórios
│   │   ├── sync/        # sync engine + cliente Nostr
│   │   ├── crypto/      # chaves, NIP-44, storage seguro
│   │   └── l10n/        # arquivos .arb + código gerado (ver §9.2)
│   ├── l10n.yaml        # config de codegen do i18n
│   └── pubspec.yaml
├── packages/
│   └── dl_concept/      # design system reutilizável: tema + nav adaptativa (§9.1)
│       ├── lib/
│       └── test/
├── cli/                 # Go (go-nostr)
│   ├── cmd/
│   └── internal/
├── shared/              # protocolo compartilhado
│   ├── proto/           # schema protobuf do changeset
│   └── PROTOCOL.md      # kinds Nostr, formato de payload
├── docs/
│   └── okf/             # bundle OKF (conhecimento do domínio) — ver §8.1
│       ├── index.md     # reservado OKF
│       ├── log.md       # reservado OKF (histórico de curadoria)
│       └── concepts/    # conceitos: data-model, sync, security, ...
├── scripts/             # checagens (perf, OKF lint) — ver §11.4
├── AGENTS.md            # instruções para agentes de IA
├── flake.nix
├── flake.lock
└── SPEC.md
```

---

## 6. Modelo de dados e persistência local

- **Store:** SQLite via `sqlite_crdt`.
- **CRDT:** cada tabela ganha colunas de metadados CRDT (HLC, tombstone). A
  resolução de conflito é **last-write-wins por campo**, ordenada por
  Hybrid Logical Clock — determinística e sem coordenação central.
- **Deleção:** *soft delete* via tombstone (necessário para propagar remoções
  entre dispositivos).
- **Cifra em repouso:** banco aberto com SQLCipher; a chave do banco deriva de
  material guardado no storage seguro da plataforma (§10).

### Quando trocar de estratégia
LWW/HLC é suficiente para dados estruturados (listas, campos, flags). Se um dia
for preciso **edição colaborativa de texto** com merge de caracteres, migrar a
coluna relevante para um CRDT de sequência (Automerge/Loro via FFI). O spec
mantém LWW como padrão por simplicidade e por evitar FFI.

---

## 7. Sincronização via Nostr

O Nostr é tratado como **transporte burro e não confiável**: todo payload é
assinado e cifrado; nenhum relay é fonte de verdade.

### 7.1 Tipos de evento

| Evento     | Kind Nostr                | Retenção     | Papel                                   |
|------------|---------------------------|--------------|-----------------------------------------|
| Snapshot   | 30078 (NIP-78, addressable)| só o último  | estado completo compactado, cifrado     |
| Changeset  | kind regular (1000–9999)*  | append/retido| deltas incrementais desde o snapshot    |

\* Constante do template (ex.: `TEMPLATE_CHANGESET_KIND`), documentada em
`shared/PROTOCOL.md`. **Evitar** faixa efêmera (20000–29999): relays não a
armazenam.

### 7.2 Fluxo

**Publicação (push):**
1. Uma mutação local gera um changeset (deltas HLC).
2. O changeset é serializado (protobuf, §8) e cifrado com **NIP-44 v2** usando
   a própria chave pública como par (auto-cifra).
3. Publicado como evento `changeset` para os relays configurados.
4. Periodicamente (ou por limiar de N changesets), o cliente publica um novo
   **snapshot** (NIP-78) e pode emitir **NIP-09** (deletion) para podar
   changesets antigos, limitando o crescimento no relay.

**Bootstrap / recepção (pull):**
1. Cliente novo pede o último `snapshot` (`kinds:[30078]`, `authors:[pubkey]`).
2. Pede changesets desde o timestamp do snapshot (`kinds:[…]`, `since:`).
3. Decifra, valida assinatura, aplica no store local (merge CRDT idempotente).
4. Mantém assinatura ativa (subscribe) para deltas em tempo real.

### 7.3 Relays
- Lista de relays **configurável** pelo usuário; padrões sensatos incluídos.
- Suporte a relays privados/autenticados (NIP-42) recomendado para dados
  sensíveis — reduz metadados expostos.
- Pool com reconexão, backoff e deduplicação de eventos por `id`.

---

## 8. Protocolo compartilhado

- Formato do changeset definido como **schema protobuf** em `shared/proto/`,
  com codegen para **Dart** e **Go** — fonte única entre app e CLI.
- `shared/PROTOCOL.md` documenta: kinds usados, estrutura do payload, versão do
  esquema (campo `schema_version` para evolução compatível), e convenção de
  auto-cifra NIP-44.
- Versionamento: clientes ignoram com segurança campos desconhecidos; mudanças
  incompatíveis incrementam `schema_version`.

### 8.1 Conhecimento do domínio em OKF

O conhecimento do projeto (o que existe no domínio: modelo de dados, protocolo
de sync, kinds Nostr, modelo de segurança, decisões arquiteturais) é mantido
como um **bundle OKF (Open Knowledge Format)** em `docs/okf/`.

OKF é uma spec aberta (Google Cloud, Apache 2.0) que representa conhecimento
como **Markdown + YAML frontmatter** versionado em Git. Regras adotadas:

- Cada conceito é um arquivo `.md` com frontmatter contendo, no mínimo, o campo
  **`type`** obrigatório (ex.: `type: architecture-decision`, `type: protocol`,
  `type: data-model`, `type: security`).
- Arquivos **reservados**: `index.md` (índice do bundle) e `log.md` (histórico
  de curadoria do conhecimento).
- **Cross-links** entre conceitos via links Markdown relativos
  (`[...](/docs/okf/concepts/sync.md)`).
- Conformidade validável em CI (frontmatter parseável, `type` presente,
  reservados corretos) — ver §11.4 / §15.

Divisão de papéis (são complementares, não redundantes):

| Arquivo        | Responde                                         |
|----------------|--------------------------------------------------|
| `AGENTS.md`    | **Como** o agente deve se comportar no repo      |
| bundle OKF     | **O que** existe no domínio (conceitos, contexto)|
| `SPEC.md`      | A especificação-fonte (este documento)           |

Toda criação, edição ou remoção de conteúdo de conhecimento segue o formato OKF
(o `AGENTS.md` referencia isso explicitamente).

---

## 9. UI adaptativa

**Requisito:** a experiência deve ser boa em **celular, tablet e desktop** —
não apenas "responsiva o suficiente para não quebrar". Cada breakpoint é
tratado como um alvo de UX de primeira classe, não um fallback do outro.

Breakpoints Material 3 (largura em dp lógicos):

| Faixa     | Largura     | Dispositivo típico                           | Navegação                         |
|-----------|-------------|-----------------------------------------------|------------------------------------|
| Compact   | < 600       | Celular                                       | `NavigationBar` (barra inferior)  |
| Medium    | 600–840     | Tablet (retrato) / janela pequena de desktop  | `NavigationRail` (rail lateral)   |
| Expanded  | > 840       | Tablet (paisagem) / desktop                   | `NavigationDrawer` (sidebar fixa) |

- Uma **shell de navegação** única (via `go_router` `ShellRoute`) decide o
  componente por `MediaQuery`/`LayoutBuilder`, preservando o estado das abas.
- Conteúdo com largura máxima e *padding* responsivo em telas expandidas;
  listas/detalhe podem virar layout de duas colunas (list-detail) no expanded.
- **Alvos de toque** ≥ 48×48dp em compact/medium (celular/tablet); em
  expanded/desktop, suportar também **mouse e teclado** (hover states, foco
  visível, atalhos de teclado, scroll com roda do mouse) sem depender de
  gestos exclusivos de touch.
- Janela de desktop (Linux) é **redimensionável**: o layout deve se adaptar
  a qualquer largura em tempo real, não só nos três pontos de corte nominais.
- Nenhuma funcionalidade exclusiva de um form factor — o que existe em
  compact deve estar acessível (mesmo que reorganizado) em medium/expanded, e
  vice-versa.

### 9.1 Sistema de temas (design tokens)

**Requisito:** existe um **sistema de temas único**, no pacote reutilizável
`packages/dl_concept/` (`package:dl_concept`) — cores, tipografia,
espaçamento e formas nunca são hardcoded em widgets; tudo vem de tokens
centralizados. Isso vale desde o primeiro commit e **por toda
a manutenção** do app: toda tela/feature nova consome os tokens existentes
ou propõe uma extensão neles, nunca um valor solto.

- Base de cor: `ColorScheme.fromSeed` (Material 3) com **Material You**
  (cores dinâmicas do SO) via `DynamicColorBuilder` (`package:dynamic_color`)
  no Android/Linux/desktop quando disponível; fallback determinístico (seed
  fixo) onde não há paleta dinâmica.
- **Temas claro e escuro sempre implementados em paralelo** — nenhuma
  feature nova entra só com um dos dois.
- Tokens além de cor (espaçamento, raio) vivem em um `ThemeExtension`
  próprio (`AppSpacing`, registrado em `ThemeData.extensions`), acessível
  via `context.spacing` — não em constantes soltas espalhadas pelo código.
- Escala de fonte e contraste do sistema (acessibilidade) são respeitadas —
  nunca fixar `textScaleFactor` nem tamanhos de fonte absolutos que ignorem
  a preferência do usuário.
- Checklist (mesmo peso do de segurança/performance):
  - [ ] Nenhuma cor/spacing hardcoded fora de `package:dl_concept` (`packages/dl_concept/`)
  - [ ] Light e dark cobertos para toda tela nova
  - [ ] Testado nos três breakpoints (§9)
  - [ ] Material You ligado (com fallback determinístico) via `dynamic_color`

### 9.2 Internacionalização (i18n)

**Requisito:** o app é internacionalizável **desde a fundação** — nenhuma
string de UI é hardcoded no código-fonte fora do mecanismo de i18n. Decisão
tomada cedo de propósito: retrofitting i18n depois que strings já estão
espalhadas pelo código é caro.

- Mecanismo: `flutter_localizations` + `intl`, arquivos `.arb` em
  `app/lib/l10n/`, geração via `flutter gen-l10n` (config em `app/l10n.yaml`,
  acionada automaticamente por `flutter pub get`/build via `generate: true`
  no `pubspec.yaml`). Acesso em runtime via `AppLocalizations.of(context)!`.
- Locale-fonte: **`pt`** (idioma dos documentos do projeto) + **`en`** como
  segundo locale mantido desde o início — ter dois locales desde o começo
  força o hábito de nunca hardcodar string de UI.
- Formatação de data/número/plural via `intl` (nunca montar string à mão) —
  cobre plurais corretamente e deixa o suporte a um locale RTL futuro
  praticamente pronto.
- Só texto de **UI** é traduzido — nomes de tabela, chaves de protocolo e
  identificadores de domínio não são.
- Checklist:
  - [ ] Toda string de UI nova entra em `app/lib/l10n/*.arb` (nunca literal
        num widget)
  - [ ] `pt` e `en` sempre atualizados juntos (nunca uma chave só num arquivo)
  - [ ] `flutter gen-l10n` roda sem erro no CI (via `flutter pub get`)

---

## 10. Segurança

### 10.1 Gestão de chaves (a decisão mais crítica)
A chave secreta Nostr **é** a identidade **e** a chave de cifra. Vazou =
comprometeu tudo.

| Plataforma | Estratégia                                                        |
|------------|-------------------------------------------------------------------|
| Android    | Chave em **Android Keystore** via `flutter_secure_storage`         |
| Linux      | Chave no **keyring** do SO (libsecret) via `flutter_secure_storage`|
| Web        | App **nunca** segura a chave: **NIP-07** (extensão) ou **NIP-46** (assinador remoto/bunker) |

- A chave do **SQLCipher** deriva de segredo no storage seguro; nunca em texto
  plano no disco.
- Opção recomendada mesmo em desktop/mobile: suportar **NIP-46** para quem
  preferir manter a chave fora do app.

### 10.2 Cifra e integridade
- Todos os payloads sincronizados: **NIP-44 v2** (ChaCha20 + HMAC), auto-cifra.
- Assinatura Schnorr (secp256k1) verificada em **todo** evento recebido.
- Banco local cifrado em repouso (SQLCipher).

### 10.3 Modelo de confiança
- **Relays não são confiáveis:** não veem conteúdo (cifrado), não podem forjar
  eventos (assinatura), no máximo omitem/atrasam. Mitigar com múltiplos relays.
- Preferir relays autenticados (NIP-42) para reduzir exposição de metadados
  (quem publica, quando, com que frequência).

### 10.4 Cadeia de suprimentos e build
- **Builds reprodutíveis via Nix**: dependências fixadas em `flake.lock`.
- `pubspec.lock` e `go.sum` versionados.
- **Sem telemetria.** Nenhuma coleta de dados por padrão.

### 10.5 Checklist de segurança
- [ ] Chave privada nunca persistida em texto plano
- [ ] Web usa NIP-07/NIP-46 (sem chave no bundle)
- [ ] Assinatura verificada em todo evento recebido
- [ ] Payloads sempre cifrados (NIP-44) antes de publicar
- [ ] Banco local com SQLCipher
- [ ] Relays tratados como não confiáveis
- [ ] Dependências fixadas (flake.lock / lockfiles)
- [ ] Sem telemetria / rede fora dos relays configurados

---

## 11. Performance

### 11.1 Diretrizes
- **Local-first:** UI só lê/escreve no store local → resposta imediata; sync em
  background.
- **Isolates:** cifra/decifra (NIP-44) e verificação de assinatura fora da
  thread de UI.
- **Batching/debounce:** agrupar mutações em changesets; não publicar por
  tecla digitada.
- **Snapshots periódicos:** encurtam o bootstrap e limitam o replay de deltas.
- **Pool de relays** com deduplicação e limites de subscrição.
- **Web:** usar o renderer moderno (WASM/skwasm), *lazy loading* de rotas,
  tree-shaking de ícones; medir o *first load*.

### 11.2 Alvos (orçamento de performance)
| Métrica                              | Alvo                     |
|--------------------------------------|--------------------------|
| Abertura a cargo (dados locais)      | < 1 s                    |
| Latência de mutação (UI → store)     | < 16 ms (1 frame)        |
| Aplicar changeset recebido           | sem *jank* (off-thread)  |
| Bundle web (first load, gzip)        | orçamento definido no CI |

### 11.3 Checklist de performance
- [ ] UI nunca bloqueia em I/O de rede
- [ ] Cripto em isolate
- [ ] Mutações agrupadas/debounced
- [ ] Snapshots limitam replay de deltas
- [ ] Renderer web otimizado + rotas lazy
- [ ] Orçamento de bundle web checado no CI

### 11.4 Scripts de checagem de performance

Scripts em `scripts/` automatizam a detecção de problemas comuns de
performance. Rodam localmente e no CI (§15). Orçamentos são configuráveis por
variáveis de ambiente para não travar o desenvolvimento.

| Script                        | O que checa                                                        |
|-------------------------------|--------------------------------------------------------------------|
| `scripts/perf-check.sh`       | Orquestrador: roda todas as checagens abaixo, agrega o resultado   |
| `scripts/check-web-bundle.sh` | Build web + tamanho gzip do bundle vs orçamento (`WEB_BUDGET_KB`)  |
| `scripts/check-apk-size.sh`   | Build APK release + tamanho vs orçamento (`APK_BUDGET_MB`)         |
| `scripts/check-flutter.sh`    | `dart analyze` (lints de performance) + `const` faltando           |
| `scripts/check-antipatterns.sh`| Grep por padrões de risco na thread de UI (I/O/JSON síncrono, etc.)|
| `scripts/check-go.sh`         | `go vet`, benchmarks e tamanho do binário da CLI                   |
| `scripts/check-okf.sh`        | Conformidade do bundle OKF (frontmatter, `type`, reservados)       |

Problemas comuns cobertos: bundle web acima do orçamento; APK inchado; widgets
sem `const`; trabalho pesado (cripto/JSON/I/O) na thread de UI; regressão de
benchmark no Go; e binário da CLI crescendo sem controle. Detalhes de cada
regra ficam como conceitos no bundle OKF (§8.1).

---

## 12. Backend Go CLI (opcional)

Ferramenta headless, **leve de propósito** (não é par CRDT completo): lê/escreve
os mesmos eventos cifrados via `go-nostr` e o schema protobuf de `shared/`.

| Comando            | Descrição                                                     |
|--------------------|---------------------------------------------------------------|
| `keygen`           | Gera par de chaves Nostr (nsec/npub)                          |
| `pull`             | Baixa snapshot + changesets, decifra, exporta                 |
| `push`             | Publica um changeset/snapshot a partir de um arquivo          |
| `export`           | Exporta o estado decifrado (JSON) para backup                 |
| `import`           | Importa estado de um arquivo e publica                        |
| `backup`           | Snapshot cifrado dos eventos para armazenamento frio          |

Casos de uso: backup automatizado (cron), migração, scripts, integração CI, ou
um nó de agregação pessoal que mantém o histórico.

---

## 13. Ambiente de desenvolvimento e flake.nix

### 13.1 NixOS como ambiente de desenvolvimento obrigatório

Este template assume **NixOS** — ou, no mínimo, o Nix package manager com
flakes habilitados sobre outra distro/macOS — como **ambiente de
desenvolvimento canônico e obrigatório**. Motivos:

- **Reprodutibilidade real:** toda a toolchain (Flutter, Go, Android SDK/NDK,
  GTK e demais deps de sistema do Linux) é fixada em `flake.lock`, eliminando
  divergência entre máquinas ("funciona na minha máquina").
- **Isolamento:** nenhuma dependência de build é instalada globalmente no
  host; tudo entra via `devShell`.
- **Paridade dev/CI:** desenvolvedores e o CI usam exatamente os mesmos
  pacotes/versões, pinados pelo mesmo `flake.lock`.

Requisitos mínimos:
- NixOS instalado, **ou** Nix ≥ 2.18 com
  `experimental-features = nix-command flakes` habilitado (`/etc/nix/nix.conf`
  ou `~/.config/nix/nix.conf`).
- `nixpkgs.config.allowUnfree = true` (necessário para o Android SDK — licença
  não-livre).
- Em NixOS, via `configuration.nix` (system-wide) — ou apenas via `nix develop`,
  sem exigir mudança no system config:
  ```nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  ```
- Para build/deploy em Android físico/emulador a partir de NixOS:
  `programs.adb.enable = true;` e o usuário no grupo `adbusers` (ajuste de
  sistema NixOS; fora do escopo do flake do projeto).

**Regra:** todo comando de build/lint/teste do projeto roda **dentro** de um
`nix develop` (ver §14). Toolchains (`flutter`, `go`, Android SDK/NDK, etc.)
**não** devem ser instaladas manualmente fora do Nix — isso quebra a garantia
de reprodutibilidade que é o propósito central desta seção.

### 13.2 Android SDK/NDK: flake input do GitHub

O Android SDK/NDK **não** vem do `androidenv` "cru" do nixpkgs nem é baixado
manualmente (Android Studio, `sdkmanager` avulso). Ele entra como **flake
input dedicado hospedado no GitHub**:
[`github:tadfisher/android-nixpkgs`](https://github.com/tadfisher/android-nixpkgs),
que empacota SDK/NDK de forma reprodutível e pinada por `flake.lock`.

```nix
# flake.nix — input
inputs.android-nixpkgs = {
  url = "github:tadfisher/android-nixpkgs";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Uso no devShell `android`:

```nix
androidSdk = android-nixpkgs.sdk.${system} (sdkPkgs: with sdkPkgs; [
  cmdline-tools-latest
  build-tools-34-0-0
  platform-tools
  platforms-android-34
  ndk-26-1-10909125
  emulator
]);
```

Regras:
- Versões de `build-tools`/`platform`/NDK são **pinadas explicitamente** no
  `flake.nix` (nunca "latest" implícito) — builds reprodutíveis dependem disso.
- Atualizar o SDK é `nix flake lock --update-input android-nixpkgs` seguido de
  bump explícito das versões pinadas na lista acima — nunca edição manual de
  um SDK já instalado no sistema.
- O devShell `android` exporta `ANDROID_HOME`/`ANDROID_SDK_ROOT` apontando
  para o resultado de `android-nixpkgs`, sem exigir Android Studio instalado.

DevShells separados por alvo e outputs de build.

```nix
# esboço (não exaustivo)
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, android-nixpkgs, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        androidSdk = android-nixpkgs.sdk.${system} (sdkPkgs: with sdkPkgs; [
          cmdline-tools-latest build-tools-34-0-0 platform-tools
          platforms-android-34 ndk-26-1-10909125
        ]);
      in {
        devShells = {
          # Flutter + Linux (GTK, pkg-config, clang, cmake, ninja)
          app-linux = pkgs.mkShell { buildInputs = [ pkgs.flutter pkgs.gtk3 /* ... */ ]; };
          # Android SDK/NDK vindo do flake input github:tadfisher/android-nixpkgs
          android = pkgs.mkShell {
            buildInputs = [ pkgs.flutter androidSdk ];
            ANDROID_HOME = "${androidSdk}/share/android-sdk";
            ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
          };
          # Go para a CLI
          cli = pkgs.mkShell { buildInputs = [ pkgs.go pkgs.protobuf ]; };
        };
        packages = {
          cli        = pkgs.buildGoModule { /* ... */ };   # binário Go
          app-linux  = /* bundle Flutter Linux */;
          # web: derivação que roda `flutter build web`
        };
      });
}
```

**Honestidade sobre Android:** um APK 100% reprodutível em Nix é trabalhoso
(licenciamento do SDK, toolchain). O padrão do template: o **devShell `android`
provê o SDK/NDK via `github:tadfisher/android-nixpkgs`** e o build roda via
`flutter build apk`. A CLI Go e o app Linux têm builds mais próximos de
reprodutíveis puros.

---

## 14. Build e execução

Pressupõe NixOS/Nix com flakes habilitados (ver §13.1). Nenhum comando abaixo
deve rodar com toolchains instaladas fora do Nix.

```bash
# entrar no ambiente (exemplos)
nix develop .#app-linux    # Flutter + deps Linux
nix develop .#android      # SDK/NDK Android
nix develop .#cli          # Go

# app
cd app
flutter run -d linux
flutter run -d chrome      # web
flutter build apk          # android (dentro do devShell android)

# cli
cd cli && go build ./...
```

---

## 15. Versionamento e releases

- **Fonte única da versão:** a versão do app vive em `app/pubspec.yaml`
  (`version: X.Y.Z+build`) e da CLI em uma tag/ldflag do Go. Segue
  **SemVer** e commits **Conventional Commits** (habilita changelog automático).
- **O app exibe a versão do release corrente** (ex.: tela "Sobre" e/ou rodapé
  da sidebar), lida em runtime via `package_info_plus` — nunca hardcoded. Em
  builds de release a versão deve bater com a tag Git (`vX.Y.Z`), checado no CI.
- **Releases no GitHub via `gh` CLI.** Ao criar uma tag `vX.Y.Z`, o pipeline
  publica um release e anexa os artefatos:

```bash
# criar release e subir artefatos (executado no CI ou manualmente)
gh release create "v${VERSION}" \
  --title "v${VERSION}" \
  --notes-file CHANGELOG.md \
  build/app-release.apk \
  build/app-linux.tar.gz \
  build/web.tar.gz \
  build/cli-linux-amd64 \
  checksums.txt
```

- **Integridade dos artefatos (segurança):** gerar e anexar `checksums.txt`
  (SHA-256) e, idealmente, assinar os artefatos. Assim o usuário verifica o
  download.
- **Consistência:** um check de CI falha o build se a versão do `pubspec.yaml`
  não corresponder à tag do release.

---

## 16. Testes e CI

- **Dart:** testes de unidade (domínio, merge CRDT, cifra), testes de
  integração do fluxo de sync no `app/`; testes de unidade
  (`breakpointForWidth`) e widget tests da shell adaptativa nos três
  breakpoints (celular/tablet/desktop) em `packages/dl_concept/test/`.
- **Go:** testes de unidade da CLI e da (de)serialização protobuf.
- **Interoperabilidade:** teste que gera um changeset em Dart, lê em Go (e
  vice-versa), garantindo paridade do protocolo.
- **CI:** `nix flake check`, lint/format (dart format, gofmt), `scripts/perf-check.sh`
  (§11.4), conformidade OKF (`scripts/check-okf.sh`), check de consistência de
  versão↔tag (§15), e build dos três alvos.
- **Release:** ao publicar tag `vX.Y.Z`, o job de release constrói os artefatos
  e usa `gh release create` (§15).

---

## 17. Fases de implementação

1. **Fundação:** flake.nix + devShells; app Flutter com nav adaptativa
   (barra/rail/drawer) e a lista de exemplo (só local).
2. **Store local:** `sqlite_crdt` + SQLCipher; CRUD com merge CRDT.
3. **Cripto e chaves:** geração de chave, storage seguro por plataforma,
   NIP-44 (auto-cifra), NIP-07/46 na web.
4. **Sync engine:** publicação/recepção de changesets + snapshots; pool de
   relays; bootstrap.
5. **Go CLI:** protobuf compartilhado + comandos de backup/export/import.
6. **Polimento:** performance (isolates, batching, renderer web), testes de
   interop, CI, documentação.

---

## 18. Decisões em aberto

- ~~Número final do `TEMPLATE_CHANGESET_KIND`~~ — **resolvido:** `9411`,
  registrado em [`shared/PROTOCOL.md`](/shared/PROTOCOL.md#4-constantes-compartilhadas).
- Cadência de snapshot (por tempo vs por nº de changesets).
- Relays padrão a incluir.
- Estratégia de rotação/backup da chave para o usuário final.
- Assinatura de artefatos de release (minisign/cosign vs só checksums).
- Distribuição no F-Droid (combina com o perfil de privacidade/segurança).
