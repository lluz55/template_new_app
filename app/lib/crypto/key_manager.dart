import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nostr/nostr.dart';

/// Gestão da chave secreta Nostr (SPEC §10.1). A chave **é** a identidade
/// **e** a chave de cifra — vazou, comprometeu tudo. Nunca logar, nunca
/// serializar em texto plano fora do storage seguro da plataforma.
///
/// | Plataforma | Estratégia                                            |
/// |------------|--------------------------------------------------------|
/// | Android    | Android Keystore via `flutter_secure_storage`          |
/// | Linux      | keyring (libsecret) via `flutter_secure_storage`       |
/// | Web        | **não suportado aqui** — usar NIP-07/NIP-46 (ver TODO) |
class KeyManager {
  KeyManager({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              // Explícito de propósito, mesmo igual ao default do pacote:
              // deixa a postura de segurança auditável no código em vez de
              // depender de conhecer o default de uma versão específica do
              // `flutter_secure_storage`. AndroidOptions() sem `.biometric()`
              // usa Android Keystore (AES-GCM + RSA-OAEP) sem exigir prompt —
              // deliberado: KeyManager é lido por operações em segundo plano
              // (sync, SPEC §4), que não têm contexto de UI para autenticar.
              aOptions: AndroidOptions.defaultOptions,
              lOptions: LinuxOptions.defaultOptions,
            );

  final FlutterSecureStorage _storage;
  static const _secretKeyStorageKey = 'nostr_secret_key';

  /// Carrega a chave existente ou gera e persiste uma nova.
  ///
  /// TODO(fase-3, SPEC §10.1): na Web, esta classe não deve ser usada — o
  /// app nunca guarda a chave no navegador. Web usa NIP-07 (extensão) ou
  /// NIP-46 (assinador remoto/bunker); implementar um `WebSigner`
  /// equivalente em `app/lib/crypto/` que não persista segredo local.
  Future<Keys> loadOrCreate() async {
    if (kIsWeb) {
      throw UnsupportedError(
        'KeyManager não se aplica à Web — use NIP-07/NIP-46 (SPEC §10.1).',
      );
    }

    final existing = await _storage.read(key: _secretKeyStorageKey);
    if (existing != null) {
      return Keys(existing);
    }

    final keys = Keys.generate();
    await _storage.write(key: _secretKeyStorageKey, value: keys.secret);
    return keys;
  }

  Future<void> clear() => _storage.delete(key: _secretKeyStorageKey);
}
