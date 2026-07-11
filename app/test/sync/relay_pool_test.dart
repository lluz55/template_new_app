import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stream_channel/stream_channel.dart' show StreamChannelMixin;
import 'package:tpl_new_app/sync/nostr/relay_pool.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Dublê de [WebSocketSink] — só coleta o que foi enviado, ignorando
/// `closeCode`/`closeReason` (não fazem sentido fora de um WebSocket real).
class _FakeWebSocketSink implements WebSocketSink {
  _FakeWebSocketSink(this._outgoing);

  final StreamController<dynamic> _outgoing;

  @override
  void add(dynamic event) => _outgoing.add(event);

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _outgoing.addError(error, stackTrace);

  @override
  Future addStream(Stream stream) => _outgoing.addStream(stream);

  @override
  Future close([int? closeCode, String? closeReason]) => _outgoing.close();

  @override
  Future get done => _outgoing.done;
}

/// Dublê de [WebSocketChannel] sobre dois `StreamController`s planos (um
/// para o que o "relay" manda, outro para o que o [RelayPool] publica) —
/// deixa testar o parsing/dedupe de frames sem WebSocket real (SPEC §16
/// pede cobertura de sync sem depender de rede/relay externo).
class FakeWebSocketChannel extends StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  FakeWebSocketChannel(
      {required StreamController<dynamic> incoming,
      required StreamController<dynamic> outgoing})
      : stream = incoming.stream,
        sink = _FakeWebSocketSink(outgoing);

  @override
  final Stream stream;

  @override
  final WebSocketSink sink;

  @override
  String? get protocol => null;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  Future<void> get ready => Future.value();
}

void main() {
  late StreamController<dynamic> incoming;
  late StreamController<dynamic> outgoing;
  late RelayPool pool;

  setUp(() async {
    incoming = StreamController<dynamic>.broadcast();
    outgoing = StreamController<dynamic>.broadcast();
    pool = RelayPool(
      ['wss://fake.relay.test'],
      channelFactory: (_) =>
          FakeWebSocketChannel(incoming: incoming, outgoing: outgoing),
    );
    await pool.connect();
  });

  tearDown(() async {
    await pool.close();
    await outgoing.close();
  });

  /// Simula o relay mandando um frame cru, como faria por WebSocket.
  void relaySends(Object frame) => incoming.add(jsonEncode(frame));

  test('EVENT chega em events()', () async {
    final future = pool.events.first;
    relaySends([
      'EVENT',
      'sub-1',
      {'id': 'abc', 'content': 'cifrado'}
    ]);

    final event = await future;
    expect(event['id'], 'abc');
  });

  test('EVENT repetido (mesmo id) não duplica em events()', () async {
    final received = <Map<String, Object?>>[];
    final sub = pool.events.listen(received.add);

    relaySends([
      'EVENT',
      'sub-1',
      {'id': 'dup', 'content': 'x'}
    ]);
    relaySends([
      'EVENT',
      'sub-1',
      {'id': 'dup', 'content': 'x'}
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await sub.cancel();

    expect(received, hasLength(1));
  });

  test('frame JSON malformado não derruba o pool nem propaga erro', () async {
    final received = <Map<String, Object?>>[];
    final errors = <Object>[];
    final sub = pool.events.listen(received.add, onError: errors.add);

    incoming.add('isto não é JSON válido {{{');
    relaySends([
      'EVENT',
      'sub-1',
      {'id': 'depois-do-lixo', 'content': 'x'}
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await sub.cancel();

    expect(errors, isEmpty);
    expect(received.map((e) => e['id']), ['depois-do-lixo']);
  });

  test(
      'OK/EOSE/NOTICE são ignorados sem erro (ainda sem tratamento, SPEC §7.3)',
      () async {
    final received = <Map<String, Object?>>[];
    final errors = <Object>[];
    final sub = pool.events.listen(received.add, onError: errors.add);

    relaySends(['EOSE', 'sub-1']);
    relaySends(['OK', 'event-id', true, '']);
    relaySends(['NOTICE', 'mensagem do relay']);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await sub.cancel();

    expect(errors, isEmpty);
    expect(received, isEmpty);
  });

  test('publish() envia o evento assinado pelo sink do relay', () async {
    final sentFrames = <dynamic>[];
    final sub = outgoing.stream.listen(sentFrames.add);

    pool.publish({'id': 'evt-1', 'sig': 'fake-sig', 'content': 'cifrado'});
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await sub.cancel();

    expect(sentFrames, hasLength(1));
    final frame = jsonDecode(sentFrames.single as String) as List<dynamic>;
    expect(frame[0], 'EVENT');
    expect((frame[1] as Map)['id'], 'evt-1');
  });
}
