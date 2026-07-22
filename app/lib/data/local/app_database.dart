import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';

/// Store local do app (SPEC §6): SQLite via `sqlite_crdt` — HLC + LWW por
/// campo, tombstones para soft delete. Cifra em repouso (SQLCipher) é
/// TODO de Fase 3 (SPEC §17): hoje o banco abre sem cifra para permitir
/// desenvolver a Fase 1/2 (fundação + store local) sem bloquear em chave
/// ainda não gerida pelo KeyManager (`app/lib/crypto/key_manager.dart`).
///
/// Para ligar SQLCipher: abrir com `sqlite3_flutter_libs`/build do sqlite3
/// com suporte a SQLCipher e rodar `PRAGMA key = '<derivado do KeyManager>'`
/// como primeira instrução da conexão, antes de qualquer outra query.
class AppDatabase {
  AppDatabase._(this.crdt);

  final SqliteCrdt crdt;

  static const _schemaVersion = 1;

  // `db` é `dynamic` de propósito: o tipo exato do executor passado por
  // `SqliteCrdt.open`/`openInMemory` (`onCreate`) depende da versão
  // instalada do pacote — confira contra `sqlite_crdt` após `flutter pub get`
  // e troque por um import/tipo concreto se preferir tipagem estrita.
  static Future<void> _onCreate(dynamic db, int version) async {
    await db.execute('''
      CREATE TABLE items (
        id TEXT NOT NULL PRIMARY KEY,
        title TEXT NOT NULL,
        done INTEGER NOT NULL DEFAULT 0
      )
    ''');
    // Linha única (settings.id = 'app'): configurações do usuário que não
    // são uma lista de entidades próprias — hoje só a lista de relays
    // (SPEC §7.3), guardada como JSON. Sincroniza como o resto do domínio
    // (mesmo store CRDT) para acompanhar o usuário entre dispositivos.
    await db.execute('''
      CREATE TABLE settings (
        id TEXT NOT NULL PRIMARY KEY,
        relay_urls TEXT NOT NULL
      )
    ''');
  }

  /// Abre o banco persistente. Em desktop (Linux) usa o backend FFI do
  /// sqflite; em Android/iOS, o sqlite_crdt usa o backend nativo do sqflite
  /// automaticamente.
  static Future<AppDatabase> open({String fileName = 'tpl_new_app.db'}) async {
    if (Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dir = await getApplicationSupportDirectory();
    final path = p.join(dir.path, fileName);

    final crdt = await SqliteCrdt.open(
      path,
      version: _schemaVersion,
      onCreate: _onCreate,
    );
    return AppDatabase._(crdt);
  }

  /// Banco em memória — usado em testes de widget/unidade.
  static Future<AppDatabase> openInMemory() async {
    final crdt = await SqliteCrdt.openInMemory(
      version: _schemaVersion,
      onCreate: _onCreate,
    );
    return AppDatabase._(crdt);
  }

  /// Deltas desde o último watermark — consumido pelo sync engine para
  /// publicar um changeset (SPEC §7.2). Ver docs/okf/concepts/sync.md.
  Future<CrdtChangeset> changeset({Hlc? modifiedAfter}) =>
      crdt.getChangeset(modifiedAfter: modifiedAfter);

  /// Aplica um changeset remoto — merge CRDT idempotente (SPEC §7.2).
  Future<void> merge(CrdtChangeset changeset) => crdt.merge(changeset);

  Future<void> close() => crdt.close();
}
