import 'package:drift/drift.dart';

class Group extends Table {
  @override
  String? get tableName => 'group';

  @override
  Set<Column<Object>>? get primaryKey => {groupName};

  TextColumn get groupName => text()();

  IntColumn get sortOrder => integer()();
}
