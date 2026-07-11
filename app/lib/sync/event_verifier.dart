/// Verificação de assinatura dos eventos Nostr recebidos (SPEC §10.2, §10.3):
/// relays não são confiáveis — nenhum evento é aplicado no store local sem
/// que a assinatura Schnorr (secp256k1) seja verificada primeiro.
///
/// Interface isolada de qualquer pacote específico pelo mesmo motivo de
/// [Nip44Cipher] (ver `nip44_cipher.dart`): a Fase 4 (SPEC §17) liga a
/// implementação real sem tocar em [SyncEngine] nem nos testes que dependem
/// desta interface.
abstract class EventVerifier {
  /// Retorna `true` se `event` tem uma assinatura Schnorr válida para o seu
  /// `pubkey`/`id` declarados. Eventos que falham aqui devem ser descartados
  /// antes de qualquer decifra ou merge no store local.
  bool verify(Map<String, Object?> event);
}

/// TODO(fase-4, SPEC §17): implementar sobre `package:nostr` (ou o pacote
/// escolhido para [Nip44Cipher]) e cobrir com vetores de teste de
/// assinatura válida/inválida/adulterada. Deixado sem implementação de
/// propósito, pelo mesmo motivo de [UnimplementedNip44Cipher]: verificação
/// de assinatura é código de segurança crítico.
class UnimplementedEventVerifier implements EventVerifier {
  const UnimplementedEventVerifier();

  @override
  bool verify(Map<String, Object?> event) => throw UnimplementedError(
        'EventVerifier.verify: implementar na Fase 4 (SPEC §17) antes de '
        'aplicar qualquer evento recebido de relay no store local.',
      );
}
