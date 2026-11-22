part of 'database.dart';

@DataClassName('RawChain')
class Chains extends Table {
  @override
  String get tableName => 'chains';

  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get hops => text().map(const StringListConverter())();
  TextColumn get targetGroup => text().nullable()();
  BoolColumn get offered => boolean().withDefault(const Constant(true))();
  BoolColumn get heal => boolean().withDefault(const Constant(false))();
  IntColumn get order => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftAccessor(tables: [Chains])
class ChainsDao extends DatabaseAccessor<Database> with _$ChainsDaoMixin {
  ChainsDao(super.attachedDatabase);

  Selectable<ChainSpec> query() {
    return chains.readable(
      (row) => row.toChain(),
      orderBy: [
        (t) => OrderingTerm(expression: t.order, nulls: NullsOrder.last),
        (t) => OrderingTerm.asc(t.id),
      ],
    );
  }

  Future<void> put(ChainSpec chain, {int? order}) async {
    await chains.insertOnConflictUpdate(chain.toCompanion(order));
  }

  Future<void> remove(int id) async {
    await (delete(chains)..where((t) => t.id.equals(id))).go();
  }

  Future<void> clear() => chains.deleteAll();

  void putAllWithBatch(Batch batch, Iterable<ChainSpec> items) {
    batch.insertAllOnConflictUpdate(chains, items.map((c) => c.toCompanion()));
  }
}

extension RawChainExt on RawChain {
  ChainSpec toChain() => ChainSpec(
        id: id,
        name: name,
        hops: hops,
        offered: offered,
        targetGroup: targetGroup,
        heal: heal,
      );
}

extension ChainSpecExt on ChainSpec {
  ChainsCompanion toCompanion([int? order]) => ChainsCompanion.insert(
        id: Value(id),
        name: name,
        hops: hops,
        offered: Value(offered),
        targetGroup: Value(targetGroup),
        heal: Value(heal),
        order: Value(order),
      );
}
