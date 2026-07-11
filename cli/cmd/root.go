// Package cmd implementa os subcomandos da CLI (SPEC §12): keygen, pull,
// push, export, import, backup. Ferramenta headless, leve de propósito —
// não é um par CRDT completo.
package cmd

import (
	"fmt"
	"strings"

	"tpl_new_app/cli/internal/keystore"
)

var commands = map[string]func([]string) error{
	"keygen": runKeygen,
	"pull":   runPull,
	"push":   runPush,
	"export": runExport,
	"import": runImport,
	"backup": runBackup,
}

func Execute(args []string) error {
	if len(args) == 0 {
		printUsage()
		return fmt.Errorf("nenhum comando informado")
	}
	fn, ok := commands[args[0]]
	if !ok {
		printUsage()
		return fmt.Errorf("comando desconhecido: %s", args[0])
	}
	return fn(args[1:])
}

func printUsage() {
	fmt.Println(`tpl-new-app-cli — ferramenta headless de backup/sync/export (SPEC.md §12)

Uso:
  tpl-new-app-cli <comando> [flags]

Comandos:
  keygen   Gera par de chaves Nostr (nsec/npub)
  pull     Baixa snapshot + changesets do relay (decifra: pendente, ver TODO)
  push     Publica um changeset/snapshot a partir de um arquivo (pendente)
  export   Exporta o estado decifrado (JSON) para backup (pendente)
  import   Importa estado de um arquivo e publica (pendente)
  backup   Arquiva os eventos cifrados (snapshot+changesets) para armazenamento frio`)
}

// loadKey resolve o caminho da chave (explícito ou default) e a carrega.
func loadKey(explicitPath string) (string, error) {
	path := explicitPath
	if path == "" {
		p, err := keystore.DefaultPath()
		if err != nil {
			return "", err
		}
		path = p
	}
	sk, err := keystore.Load(path)
	if err != nil {
		return "", fmt.Errorf("carregar chave de %s: %w (rode 'keygen' primeiro)", path, err)
	}
	return sk, nil
}

func splitRelays(csv string) []string {
	parts := strings.Split(csv, ",")
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		if p = strings.TrimSpace(p); p != "" {
			out = append(out, p)
		}
	}
	return out
}
