package cmd

import (
	"flag"
	"fmt"

	gonostr "github.com/nbd-wtf/go-nostr"
	"github.com/nbd-wtf/go-nostr/nip19"

	"tpl_new_app/cli/internal/keystore"
)

func runKeygen(args []string) error {
	fs := flag.NewFlagSet("keygen", flag.ExitOnError)
	out := fs.String("out", "", "arquivo para salvar a chave secreta; default: "+
		"caminho padrão da keystore")
	force := fs.Bool("force", false, "sobrescreve a chave existente")
	showSecret := fs.Bool("show-secret", false,
		"imprime o nsec no stdout (default: só o npub — nsec em scrollback de "+
			"terminal/histórico de multiplexador é uma forma comum de vazamento)")
	if err := fs.Parse(args); err != nil {
		return err
	}

	path := *out
	if path == "" {
		p, err := keystore.DefaultPath()
		if err != nil {
			return err
		}
		path = p
	}

	if !*force {
		if _, err := keystore.Load(path); err == nil {
			return fmt.Errorf("já existe uma chave em %s (use --force para sobrescrever)", path)
		}
	}

	sk := gonostr.GeneratePrivateKey()
	pk, err := gonostr.GetPublicKey(sk)
	if err != nil {
		return fmt.Errorf("derivar chave pública: %w", err)
	}
	if err := keystore.Save(path, sk); err != nil {
		return fmt.Errorf("salvar chave: %w", err)
	}

	nsec, err := nip19.EncodePrivateKey(sk)
	if err != nil {
		return err
	}
	npub, err := nip19.EncodePublicKey(pk)
	if err != nil {
		return err
	}

	fmt.Printf("chave salva em: %s\n", path)
	fmt.Printf("npub: %s\n", npub)
	if *showSecret {
		fmt.Printf("nsec: %s\n", nsec)
		fmt.Println()
		fmt.Println("NUNCA compartilhe o nsec — é a identidade e a chave de cifra (SPEC §10.1).")
	} else {
		fmt.Println()
		fmt.Println("nsec não impresso (evita vazar via scrollback/histórico) — use " +
			"--show-secret se precisar dele, ou leia diretamente do arquivo salvo.")
	}
	return nil
}
