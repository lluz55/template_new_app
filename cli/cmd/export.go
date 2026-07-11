package cmd

import (
	"flag"
	"fmt"
)

// export decifraria e decodificaria o estado remoto para JSON de backup.
// Depende da mesma peça pendente que 'pull' (NIP-44 + protobuf, Fase 4/5,
// SPEC §17). Para arquivar os eventos como estão (ainda cifrados), use
// 'backup', que já funciona hoje.
func runExport(args []string) error {
	fs := flag.NewFlagSet("export", flag.ExitOnError)
	_ = fs.String("out", "export.json", "arquivo de saída")
	_ = fs.String("relays", "wss://relay.damus.io,wss://nos.lol", "relays separados por vírgula")
	_ = fs.String("key", "", "arquivo da chave secreta; default: caminho padrão da keystore")
	if err := fs.Parse(args); err != nil {
		return err
	}

	return fmt.Errorf(
		"export: decifra NIP-44 + decodificação protobuf pendentes (Fase 4/5, SPEC §17); " +
			"use 'backup' para arquivar os eventos ainda cifrados",
	)
}
