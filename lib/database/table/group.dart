import 'package:drift/drift.dart';

class Group extends Table {
  @override
  String? get tableName => 'group';

  @override
  Set<Column<Object>>? get primaryKey => {groupName, parentPath};

  TextColumn get groupName => text()();

  TextColumn get parentPath => text().withDefault(const Constant(''))();

  IntColumn get sortOrder => integer()();

  BoolColumn get isExpanded => boolean().withDefault(const Constant(false))();
}
