// Package keystore guarda a chave secreta Nostr da CLI em disco.
//
// Modelo deliberadamente mais simples que o do app (SPEC §10.1,
// Keystore/libsecret via flutter_secure_storage): a CLI é uma ferramenta
// headless (SPEC §12), sem sessão gráfica para um keyring de SO. O arquivo
// é gravado com permissão 0600 e o diretório com 0700, mas o segredo fica
// em texto plano no disco — proteja o host que rodar a CLI (disco cifrado,
// backups seguros). Nunca versione o arquivo da chave (ver .gitignore).
package keystore

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

func DefaultPath() (string, error) {
	dir, err := os.UserConfigDir()
	if err != nil {
		return "", fmt.Errorf("localizar diretório de config: %w", err)
	}
	return filepath.Join(dir, "tpl-new-app", "nostr.key"), nil
}

func Load(path string) (string, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(data)), nil
}

func Save(path, secretKeyHex string) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return fmt.Errorf("criar diretório: %w", err)
	}
	return os.WriteFile(path, []byte(secretKeyHex+"\n"), 0o600)
}
