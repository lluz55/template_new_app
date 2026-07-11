package cmd

import (
	"context"
	"flag"
	"fmt"
	"time"

	gonostr "github.com/nbd-wtf/go-nostr"

	internalnostr "tpl_new_app/cli/internal/nostr"
	"tpl_new_app/cli/internal/protocol"
)

// pull busca o snapshot mais recente e os changesets do usuário. A busca
// (conexão, filtros, coleta) já é real; decifrar (NIP-44) e decodificar o
// payload protobuf são Fase 4/5 (SPEC §17) — ver shared/PROTOCOL.md §2.
func runPull(args []string) error {
	fs := flag.NewFlagSet("pull", flag.ExitOnError)
	relays := fs.String("relays", "wss://relay.damus.io,wss://nos.lol", "relays separados por vírgula")
	pubkey := fs.String("pubkey", "", "pubkey hex a buscar; default: derivada da chave local")
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

	snapshots, err := client.FetchEvents(ctx, gonostr.Filters{
		gonostr.Filter{
			Kinds:   []int{protocol.TemplateSnapshotKind},
			Authors: []string{pk},
			Tags:    gonostr.TagMap{"d": []string{protocol.SnapshotDTag}},
			Limit:   1,
		},
	})
	if err != nil {
		return err
	}

	changesets, err := client.FetchEvents(ctx, gonostr.Filters{
		gonostr.Filter{
			Kinds:   []int{protocol.TemplateChangesetKind},
			Authors: []string{pk},
		},
	})
	if err != nil {
		return err
	}

	fmt.Printf("recebidos %d snapshot(s) e %d changeset(s), ainda cifrados (NIP-44)\n",
		len(snapshots), len(changesets))
	fmt.Println("decifra + decodificação protobuf pendentes (Fase 4/5, SPEC §17);" +
		" use 'backup' para só arquivar os eventos cifrados")
	return nil
}
