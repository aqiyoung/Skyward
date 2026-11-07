import 'package:drift/native.dart';
import 'package:skyward/database/database.dart';
import 'package:skyward/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Database database;

  setUp(() {
    database = Database(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('modules come back in their own order, off the list first', () async {
    const first = Module(
      id: 1,
      label: 'First',
      content: '[Rule]\nDOMAIN,a.com,REJECT\n',
      order: 'a0',
    );
    const second = Module(
      id: 2,
      label: 'Second',
      content: '[Rule]\nDOMAIN,b.com,REJECT\n',
      order: 'a1',
    );
    await database.modulesDao.putModule(second);
    await database.modulesDao.putModule(first);

    final modules = await database.modulesDao.queryAll().get();
    expect(modules.map((module) => module.label), ['First', 'Second']);
    expect(modules.first, first);
  });

  test('a switch and a policy survive the round trip', () async {
    const module = Module(
      id: 3,
      label: 'Ads',
      content: '[Rule]\nFINAL,PROXY\n',
      policy: 'Proxy',
    );
    await database.modulesDao.putModule(module);
    await database.modulesDao.putModule(
      module.copyWith(enabled: false, policy: 'Direct'),
    );

    final stored = await database.modulesDao.queryAll().getSingle();
    expect(stored.enabled, isFalse);
    expect(stored.policy, 'Direct');
    expect(stored.content, module.content);
  });

  test('reordering writes the new key', () async {
    const module = Module(id: 4, label: 'Ads', content: 'x');
    await database.modulesDao.putModule(module);
    await database.modulesDao.order(id: module.id, order: 'a5');

    expect((await database.modulesDao.queryAll().getSingle()).order, 'a5');
  });

  test('deleting takes the row with it', () async {
    const module = Module(id: 5, label: 'Ads', content: 'x');
    await database.modulesDao.putModule(module);
    await database.modulesDao.delModules([module.id]);

    expect(await database.modulesDao.queryAll().get(), isEmpty);
  });
}
