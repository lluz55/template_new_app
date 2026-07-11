package cmd

import (
	"flag"
	"fmt"
)

// import leria um JSON de estado, codificaria como protobuf, cifraria com
// NIP-44 e publicaria — mesma peça pendente de 'push' (Fase 4/5, SPEC §17).
func runImport(args []string) error {
	fs := flag.NewFlagSet("import", flag.ExitOnError)
	file := fs.String("file", "", "arquivo JSON com o estado a importar (obrigatório)")
	_ = fs.String("relays", "wss://relay.damus.io,wss://nos.lol", "relays separados por vírgula")
	_ = fs.String("key", "", "arquivo da chave secreta; default: caminho padrão da keystore")
	if err := fs.Parse(args); err != nil {
		return err
	}
	if *file == "" {
		return fmt.Errorf("--file é obrigatório")
	}

	return fmt.Errorf(
		"import: encode protobuf + cifra NIP-44 pendentes (Fase 4/5, SPEC §17); " +
			"ver 'push', que publica assim que o payload estiver pronto",
	)
}
