import 'package:flutter_test/flutter_test.dart';
import 'package:tpl_new_app/data/local/app_database.dart';
import 'package:tpl_new_app/data/local/item_local_repository.dart';

void main() {
  late AppDatabase database;
  late ItemLocalRepository repository;

  setUp(() async {
    database = await AppDatabase.openInMemory();
    repository = ItemLocalRepository(database);
  });

  tearDown(() => database.close());

  test('add cria um item não concluído', () async {
    await repository.add('Comprar leite');
    final items = await repository.watchAll().first;
    expect(items, hasLength(1));
    expect(items.single.title, 'Comprar leite');
    expect(items.single.done, isFalse);
  });

  test('toggleDone marca como concluído', () async {
    await repository.add('Lavar louça');
    final id = (await repository.watchAll().first).single.id;

    await repository.toggleDone(id, done: true);

    final items = await repository.watchAll().first;
    expect(items.single.done, isTrue);
  });

  test('remove faz soft delete (item some da listagem)', () async {
    await repository.add('Item temporário');
    final id = (await repository.watchAll().first).single.id;

    await repository.remove(id);

    final items = await repository.watchAll().first;
    expect(items, isEmpty);
  });
}
