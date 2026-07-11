/// Cifra dos payloads sincronizados (SPEC §7.2, §10.2): NIP-44 v2
/// (ChaCha20 + HMAC), auto-cifra (remetente e destinatário são a mesma
/// identidade — os próprios dispositivos do usuário).
///
/// Interface isolada de qualquer pacote específico para que a Fase 3
/// (SPEC §17) possa trocar a implementação sem tocar em [SyncEngine] nem
/// nos testes que dependem desta interface.
abstract class Nip44Cipher {
  /// Cifra `plaintext` (bytes do protobuf serializado) usando a chave
  /// secreta e a própria chave pública como par (auto-cifra).
  String encrypt({
    required String secretKeyHex,
    required String ownPublicKeyHex,
    required List<int> plaintext,
  });

  List<int> decrypt({
    required String secretKeyHex,
    required String ownPublicKeyHex,
    required String ciphertext,
  });
}

/// TODO(fase-3, SPEC §17): implementar sobre `package:nostr` (ou
/// substituir por um pacote dedicado a NIP-44, ex. `dart-nip44`) e cobrir
/// com o teste de interop Dart↔Go descrito em `shared/PROTOCOL.md` §6.
/// Deixado sem implementação de propósito: cifra é código de segurança
/// crítico e não deve ser escrito sem verificação contra vetores de teste
/// oficiais da NIP-44.
class UnimplementedNip44Cipher implements Nip44Cipher {
  const UnimplementedNip44Cipher();

  @override
  String encrypt({
    required String secretKeyHex,
    required String ownPublicKeyHex,
    required List<int> plaintext,
  }) =>
      throw UnimplementedError(
        'Nip44Cipher.encrypt: implementar na Fase 3 (SPEC §17) contra os '
        'vetores de teste oficiais da NIP-44.',
      );

  @override
  List<int> decrypt({
    required String secretKeyHex,
    required String ownPublicKeyHex,
    required String ciphertext,
  }) =>
      throw UnimplementedError(
        'Nip44Cipher.decrypt: implementar na Fase 3 (SPEC §17) contra os '
        'vetores de teste oficiais da NIP-44.',
      );
}
