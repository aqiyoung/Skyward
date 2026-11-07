part of 'database.dart';

/// An imported module: the file it came from, and whether it is switched on.
///
/// The text is kept verbatim so the file a reader imported is the file we can
/// re-read later -- parsing on import and storing the result would freeze a
/// format the reader might have updated behind our back.
@DataClassName('RawModule')
class Modules extends Table {
  @override
  String get tableName => 'modules';

  IntColumn get id => integer()();

  TextColumn get label => text()();

  TextColumn get url => text().nullable()();

  TextColumn get content => text()();

  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  TextColumn get order => text().nullable()();

  TextColumn get author => text().nullable()();

  TextColumn get version => text().nullable()();

  TextColumn get homepage => text().nullable()();

  TextColumn get policy => text().nullable()();

  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftAccessor(tables: [Modules])
class ModulesDao extends DatabaseAccessor<Database> with _$ModulesDaoMixin {
  ModulesDao(super.attachedDatabase);

  Selectable<Module> queryAll() {
    final query = modules.select()
      ..orderBy([
        (t) => OrderingTerm(expression: t.order, nulls: NullsOrder.last),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query.map((item) => item.toModule());
  }

  Stream<Module?> watchOne(int id) {
    return (modules.select()..where((t) => t.id.equals(id)))
        .watchSingleOrNull()
        .map((item) => item?.toModule());
  }

  Future<int> putModule(Module module) {
    return modules.insertOnConflictUpdate(module.toCompanion());
  }

  Future<void> delModules(Iterable<int> ids) {
    return batch((b) {
      modules.deleteInChunks(b, ids, (t, chunk) => t.id.isIn(chunk));
    });
  }

  Future<void> order({required int id, required String order}) {
    final stmt = modules.update()..where((t) => t.id.equals(id));
    return stmt.write(ModulesCompanion(order: Value(order)));
  }
}

extension RawModuleExt on RawModule {
  Module toModule() {
    return Module(
      id: id,
      label: label,
      url: url,
      content: content,
      enabled: enabled,
      order: order,
      author: author,
      version: version,
      homepage: homepage,
      policy: policy,
      updatedAt: updatedAt,
    );
  }
}

extension ModuleExt on Module {
  ModulesCompanion toCompanion() {
    return ModulesCompanion(
      id: Value(id),
      label: Value(label),
      url: Value(url),
      content: Value(content),
      enabled: Value(enabled),
      order: Value(order),
      author: Value(author),
      version: Value(version),
      homepage: Value(homepage),
      policy: Value(policy),
      updatedAt: Value(updatedAt),
    );
  }
}
