package cmd

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"time"

	gonostr "github.com/nbd-wtf/go-nostr"

	internalnostr "tpl_new_app/cli/internal/nostr"
	"tpl_new_app/cli/internal/protocol"
)

// backup arquiva os eventos snapshot+changeset do usuário tal como estão
// no relay — ainda cifrados (NIP-44). Diferente de pull/export, não
// precisa decifrar: é só uma cópia fria dos eventos publicados (SPEC §12).
func runBackup(args []string) error {
	fs := flag.NewFlagSet("backup", flag.ExitOnError)
	out := fs.String("out", "backup.json", "arquivo de saída")
	relays := fs.String("relays", "wss://relay.damus.io,wss://nos.lol", "relays separados por vírgula")
	pubkey := fs.String("pubkey", "", "pubkey hex a arquivar; default: derivada da chave local")
	keyPath := fs.String("key", "", "arquivo da chave secreta; default: caminho padrão da keystore")
	timeout := fs.Duration("timeout", 10*time.Second, "tempo máximo de coleta")
	if err := fs.Parse(args); err != nil {
		return err
	}

	pk := *pubkey
	if pk == "" {
		sk, err := loadKey(*keyPath)
		if err != nil {
			return fmt.Errorf("--pubkey não informado e chave local indisponível: %w", err)
		}
		pk, err = gonostr.GetPublicKey(sk)
		if err != nil {
			return err
		}
	}

	ctx, cancel := context.WithTimeout(context.Background(), *timeout)
	defer cancel()

	client, err := internalnostr.Connect(ctx, splitRelays(*relays))
	if err != nil {
		return err
	}
	defer client.Close()

	events, err := client.FetchEvents(ctx, gonostr.Filters{
		gonostr.Filter{
			Kinds:   []int{protocol.TemplateSnapshotKind, protocol.TemplateChangesetKind},
			Authors: []string{pk},
		},
	})
	if err != nil {
		return err
	}

	data, err := json.MarshalIndent(events, "", "  ")
	if err != nil {
		return err
	}
	if err := os.WriteFile(*out, data, 0o600); err != nil {
		return err
	}

	fmt.Printf("backup: %d eventos (conteúdo ainda cifrado, NIP-44) salvos em %s\n", len(events), *out)
	return nil
}
