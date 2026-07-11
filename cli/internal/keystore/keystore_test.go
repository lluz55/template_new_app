package keystore

import (
	"path/filepath"
	"testing"
)

func TestSaveLoadRoundTrip(t *testing.T) {
	path := filepath.Join(t.TempDir(), "nested", "nostr.key")

	if err := Save(path, "deadbeef"); err != nil {
		t.Fatalf("Save: %v", err)
	}

	got, err := Load(path)
	if err != nil {
		t.Fatalf("Load: %v", err)
	}
	if got != "deadbeef" {
		t.Errorf("got %q, want %q", got, "deadbeef")
	}
}

func TestLoadMissingFile(t *testing.T) {
	_, err := Load(filepath.Join(t.TempDir(), "não-existe.key"))
	if err == nil {
		t.Fatal("esperava erro para arquivo inexistente")
	}
}
