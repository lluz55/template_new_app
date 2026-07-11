// Package nostr é um wrapper fino sobre go-nostr (nbd-wtf) para as
// necessidades da CLI: conectar a um pool de relays, publicar e coletar
// eventos por filtro. Relays não são confiáveis (SPEC §10.3) — este
// pacote não decifra nem valida conteúdo de domínio, só transporta.
package nostr

import (
	"context"
	"fmt"

	gonostr "github.com/nbd-wtf/go-nostr"
)

type Client struct {
	relays []*gonostr.Relay
}

// Connect abre uma conexão com cada relay da lista. Falhas de conexão
// individuais interrompem o Connect — para uso resiliente ("melhor
// esforço"), trate erros por URL antes de chamar isto (fase 4, SPEC §7.3
// menciona reconexão/backoff, ainda não implementados aqui).
func Connect(ctx context.Context, urls []string) (*Client, error) {
	c := &Client{}
	for _, u := range urls {
		r, err := gonostr.RelayConnect(ctx, u)
		if err != nil {
			c.Close()
			return nil, fmt.Errorf("conectar a %s: %w", u, err)
		}
		c.relays = append(c.relays, r)
	}
	return c, nil
}

// Publish envia o evento (já assinado) para todos os relays conectados.
// Retorna o primeiro erro encontrado, mas tenta publicar em todos.
func (c *Client) Publish(ctx context.Context, ev gonostr.Event) error {
	var firstErr error
	for _, r := range c.relays {
		if err := r.Publish(ctx, ev); err != nil && firstErr == nil {
			firstErr = fmt.Errorf("publicar em %s: %w", r.URL, err)
		}
	}
	return firstErr
}

// FetchEvents assina os filtros em todos os relays e coleta eventos até
// `ctx` expirar (use context.WithTimeout), deduplicando por id entre
// relays. Não decifra nem valida assinatura — isso é responsabilidade de
// quem consome o resultado.
func (c *Client) FetchEvents(ctx context.Context, filters gonostr.Filters) ([]gonostr.Event, error) {
	seen := make(map[string]bool)
	var events []gonostr.Event

	for _, r := range c.relays {
		sub, err := r.Subscribe(ctx, filters)
		if err != nil {
			return nil, fmt.Errorf("assinar em %s: %w", r.URL, err)
		}
		func() {
			defer sub.Close()
			for {
				select {
				case ev, ok := <-sub.Events:
					if !ok {
						return
					}
					if !seen[ev.ID] {
						seen[ev.ID] = true
						events = append(events, *ev)
					}
				case <-ctx.Done():
					return
				}
			}
		}()
	}
	return events, nil
}

func (c *Client) Close() {
	for _, r := range c.relays {
		r.Close()
	}
}
