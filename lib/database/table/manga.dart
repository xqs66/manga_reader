import 'package:drift/drift.dart';
import 'package:manga_reader/shared/constants/constants.dart';

@TableIndex(name: 'a_idx_parent_path', columns: {#parentPath})
@TableIndex(name: 'a_idx_title', columns: {#title})
@TableIndex(name: 'a_idx_group_name', columns: {#groupName})
@TableIndex(name: 'a_idx_last_read_page', columns: {#lastReadPage})
class Manga extends Table {
  @override
  String? get tableName => 'manga';

  @override
  Set<Column<Object>>? get primaryKey => {id};

  TextColumn get id => text()();

  TextColumn get parentPath => text()();

  TextColumn get title => text()();

  TextColumn get groupName =>
      text().withDefault(Constant(Constants.defaultGroupName))();

  TextColumn get tags => text().nullable()();

  DateTimeColumn get lastReadTime => dateTime().nullable()();

  IntColumn get lastReadPage => integer().withDefault(Constant(0))();

  IntColumn get sortOrder => integer()();

  ///1 - 文件夹
  IntColumn get type => integer()();

  IntColumn get size => integer()();

  IntColumn get pageCount => integer()();
}
