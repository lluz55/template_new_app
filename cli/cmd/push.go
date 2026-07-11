package cmd

import (
	"flag"
	"fmt"
)

// push publica um changeset/snapshot a partir de um arquivo local. A
// conexão e a publicação em si (internal/nostr.Client.Publish) já estão
// prontas; falta serializar o arquivo como protobuf
// (shared/proto/changeset.proto) e cifrar com NIP-44 antes de publicar —
// Fase 4/5 (SPEC §17), mesmo ponto pendente do SyncEngine em Dart.
func runPush(args []string) error {
	fs := flag.NewFlagSet("push", flag.ExitOnError)
	file := fs.String("file", "", "arquivo com o changeset/snapshot a publicar (obrigatório)")
	_ = fs.String("relays", "wss://relay.damus.io,wss://nos.lol", "relays separados por vírgula")
	_ = fs.String("key", "", "arquivo da chave secreta; default: caminho padrão da keystore")
	if err := fs.Parse(args); err != nil {
		return err
	}
	if *file == "" {
		return fmt.Errorf("--file é obrigatório")
	}

	return fmt.Errorf(
		"push: serialização protobuf + cifra NIP-44 pendentes (Fase 4/5, SPEC §17); " +
			"internal/nostr.Client.Publish já está pronto para o payload final",
	)
}
