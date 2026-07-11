#!/usr/bin/env bash
# bootstrap-platforms.sh — gera a scaffolding de plataforma do Flutter
# (app/android, app/linux, app/web) se ainda não existir.
#
# Por quê isso é um script e não passos manuais no README: `flutter create`
# não é hermético (gera timestamps, arquivos de IDE, um .gitignore/README
# próprios) e esses diretórios não são versionados neste template (native
# scaffolding é regenerada, não commitada — mesmo tratamento de
# app/lib/l10n/gen/ e shared/proto/gen/, ver .gitignore). Rodar isso à mão
# de forma consistente (e sem sujar o repo com .idea/*.iml) é chato de
# lembrar — inclusive para um agente de IA operando no repo pela primeira
# vez — daí o script.
#
# Idempotente: não faz nada se app/android, app/linux e app/web já existem.
# Chamado automaticamente por scripts/check-web-bundle.sh e
# scripts/check-apk-size.sh antes de buildar.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/app" 2>/dev/null || { echo "diretório app/ não encontrado — pulando"; exit 0; }

if [ -d android ] && [ -d linux ] && [ -d web ]; then
  echo "scaffolding de plataforma já existe (app/android, app/linux, app/web) — nada a fazer."
  exit 0
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter não encontrado — pulando (entre no devShell app-linux)"; exit 0
fi

echo "Gerando scaffolding de plataforma (flutter create . --platforms=android,linux,web)..."
# Nunca --overwrite: sem essa flag, `flutter create` só grava o que falta
# (os diretórios de plataforma) e pula arquivos já existentes no projeto
# (pubspec.yaml, analysis_options.yaml, lib/main.dart, ...) em vez de
# substituí-los pelo boilerplate padrão do Flutter.
flutter create . \
  --platforms=android,linux,web \
  --org dev.tpl_new_app \
  --project-name tpl_new_app

# `flutter create` também gera arquivos que não fazem sentido versionar aqui:
# projeto de IDE (.idea/, *.iml), e um .gitignore/README/test de exemplo que
# duplicam o que este template já define na raiz.
rm -rf .idea tpl_new_app.iml android/*.iml .gitignore README.md test/widget_test.dart

echo "Scaffolding de plataforma pronta em app/android, app/linux, app/web."
