import '../data/local/app_database.dart';
import 'event_verifier.dart';
import 'nip44_cipher.dart';
import 'nostr/kinds.dart';
import 'nostr/relay_pool.dart';

/// Motor de sincronização (SPEC §7.2): traduz changesets/snapshots locais
/// em eventos Nostr cifrados e vice-versa. Roda em segundo plano — a UI
/// nunca depende dele para responder (ver docs/okf/concepts/architecture.md).
///
/// Esqueleto da Fase 4 (SPEC §17): a estrutura e o fluxo (push/pull/
/// bootstrap) seguem o SPEC à risca; a serialização protobuf real
/// (`shared/proto/changeset.proto`, gerada por `scripts/gen-proto.sh`), a
/// cifra NIP-44 (`Nip44Cipher`) e a verificação de assinatura
/// (`EventVerifier`) ainda precisam ser ligadas — hoje são
/// [UnimplementedNip44Cipher] e [UnimplementedEventVerifier].
class SyncEngine {
  SyncEngine({
    required AppDatabase database,
    required RelayPool relayPool,
    Nip44Cipher? cipher,
    EventVerifier? verifier,
  })  : _database = database,
        _relayPool = relayPool,
        _cipher = cipher ?? const UnimplementedNip44Cipher(),
        _verifier = verifier ?? const UnimplementedEventVerifier();

  final AppDatabase _database;
  final RelayPool _relayPool;
  final Nip44Cipher _cipher;
  final EventVerifier _verifier;

  /// Publica os deltas locais desde o último watermark como um evento
  /// `changeset` (kind [templateChangesetKind]), cifrado com NIP-44.
  Future<void> push({
    required String secretKeyHex,
    required String publicKeyHex,
  }) async {
    final changeset = await _database.changeset();
    if (changeset.isEmpty) return;

    // TODO(fase-4): serializar `changeset` como protobuf (Changeset,
    // shared/proto/changeset.proto), cifrar com _cipher.encrypt(...) e
    // publicar via _relayPool.publish(...) com kind=templateChangesetKind
    // e created_at=agora. Requer o cipher real (ver nip44_cipher.dart).
    throw UnimplementedError(
      'SyncEngine.push: serialização protobuf + NIP-44 pendentes (Fase 4, '
      'SPEC §17). cipher atual: ${_cipher.runtimeType}.',
    );
  }

  /// Bootstrap (SPEC §7.2): busca o último snapshot do próprio pubkey,
  /// depois os changesets desde o timestamp do snapshot, decifra, valida
  /// assinatura e aplica no store local via merge CRDT idempotente.
  Future<void> pull({
    required String secretKeyHex,
    required String publicKeyHex,
  }) async {
    await _relayPool.connect();
    _relayPool.subscribe('bootstrap-snapshot', [
      {
        'kinds': [templateSnapshotKind],
        'authors': [publicKeyHex],
        '#d': [snapshotDTag],
        'limit': 1,
      },
    ]);

    // TODO(fase-4): consumir _relayPool.events; para cada evento, PRIMEIRO
    // _verifier.verify(event) (descarta se assinatura inválida — SPEC
    // §10.2/§10.3, relay não é confiável) e só então _cipher.decrypt(...),
    // desserializar Snapshot (protobuf), depois pedir changesets com
    // `since: snapshot.createdAt` e aplicar tudo via _database.merge(...).
    // Ver shared/PROTOCOL.md §2 para o formato exato do payload cifrado.
    throw UnimplementedError(
      'SyncEngine.pull: bootstrap completo pendente (Fase 4, SPEC §17). '
      'verifier atual: ${_verifier.runtimeType}, cipher atual: ${_cipher.runtimeType}.',
    );
  }

  /// Mantém uma subscrição ativa para deltas em tempo real após o
  /// bootstrap (SPEC §7.2, passo 4).
  Stream<void> watchRemoteChanges() {
    // TODO(fase-4): subscrever kind=templateChangesetKind com
    // `since: agora`; verificar assinatura (_verifier.verify) antes de
    // decifrar/aplicar cada evento recebido — nunca aplicar um evento não
    // verificado no store local.
    throw UnimplementedError(
      'SyncEngine.watchRemoteChanges: pendente (Fase 4, SPEC §17). '
      'verifier atual: ${_verifier.runtimeType}.',
    );
  }
}
