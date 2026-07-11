import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Pool de relays Nostr (SPEC §7.3): conecta a múltiplos relays via
/// WebSocket, fala o protocolo NIP-01 "cru" (frames JSON `EVENT`/`REQ`/
/// `CLOSE`/`EOSE`/`OK`) e deduplica eventos recebidos por `id`.
///
/// Isolado da lógica de domínio: [SyncEngine] decide o que publicar/pedir,
/// este pool só fala WebSocket. Relays não são confiáveis (SPEC §10.3) —
/// nenhum evento é aceito aqui sem que a camada de cripto verifique a
/// assinatura antes de aplicar no store local.
class RelayPool {
  RelayPool(this.relayUrls, {WebSocketChannel Function(Uri)? channelFactory})
      : _channelFactory = channelFactory ?? WebSocketChannel.connect;

  final List<String> relayUrls;

  /// Injetável só para teste (SPEC §16 pede cobertura sem depender de rede
  /// real) — em produção é sempre `WebSocketChannel.connect`.
  final WebSocketChannel Function(Uri) _channelFactory;

  final _channels = <String, WebSocketChannel>{};
  final _seenEventIds = <String>{};
  final _incomingController =
      StreamController<Map<String, Object?>>.broadcast();

  /// Eventos brutos (ainda cifrados/não verificados) recebidos de qualquer
  /// relay do pool, já deduplicados por `id`.
  Stream<Map<String, Object?>> get events => _incomingController.stream;

  Future<void> connect() async {
    for (final url in relayUrls) {
      final channel = _channelFactory(Uri.parse(url));
      _channels[url] = channel;
      channel.stream.listen(
        (raw) => _handleFrame(url, raw as String),
        onError: (Object _, StackTrace __) => _channels.remove(url),
        onDone: () => _channels.remove(url),
        cancelOnError: false,
      );
    }
  }

  /// Um relay não é confiável (SPEC §10.3): frame malformado, tipo
  /// inesperado ou campo ausente não pode derrubar o pool inteiro — só o
  /// frame ofensor é descartado.
  void _handleFrame(String relayUrl, String raw) {
    try {
      final frame = jsonDecode(raw) as List<dynamic>;
      if (frame.isEmpty) return;

      switch (frame[0]) {
        case 'EVENT':
          final event = frame[2] as Map<String, Object?>;
          final id = event['id'] as String?;
          if (id != null && _seenEventIds.add(id)) {
            _incomingController.add(event);
          }
        case 'OK':
        case 'EOSE':
        case 'NOTICE':
          // TODO(fase-4, SPEC §7.3): tratar backoff/reconexão e confirmação
          // de publicação (OK) por relay.
          break;
      }
    } on Object {
      // Frame JSON inválido ou com formato inesperado vindo de `relayUrl` —
      // descarta silenciosamente em vez de propagar e derrubar o listener
      // do WebSocket (que encerraria a conexão com esse relay).
    }
  }

  /// Publica um evento (já assinado e com `content` cifrado, ver
  /// `Nip44Cipher`) em todos os relays conectados.
  void publish(Map<String, Object?> signedEvent) {
    final frame = jsonEncode(['EVENT', signedEvent]);
    for (final channel in _channels.values) {
      channel.sink.add(frame);
    }
  }

  /// Assina uma subscrição (`REQ`) em todos os relays conectados.
  void subscribe(String subscriptionId, List<Map<String, Object?>> filters) {
    final frame = jsonEncode(['REQ', subscriptionId, ...filters]);
    for (final channel in _channels.values) {
      channel.sink.add(frame);
    }
  }

  void unsubscribe(String subscriptionId) {
    final frame = jsonEncode(['CLOSE', subscriptionId]);
    for (final channel in _channels.values) {
      channel.sink.add(frame);
    }
  }

  Future<void> close() async {
    for (final channel in _channels.values) {
      await channel.sink.close();
    }
    _channels.clear();
    await _incomingController.close();
  }
}
