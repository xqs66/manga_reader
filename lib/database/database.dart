import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:manga_reader/database/table/group.dart';
import 'package:manga_reader/shared/constants/constants.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'table/manga.dart';

part 'database.g.dart';

AppDatabase appDb = AppDatabase();

@DriftDatabase(tables: [Manga, Group])
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal() : super(_openConnection());

  static final AppDatabase _instance = AppDatabase._internal();

  factory AppDatabase() => _instance;

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _insertDefaultGroup();
      },
      onUpgrade: (Migrator m, int oldVersion, int newVersion) async {},
    );
  }

  Future<void> _insertDefaultGroup() async {
    await into(
      group,
    ).insert(GroupCompanion.insert(groupName: '默认分组', sortOrder: 0));
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(dbFolder.path, 'sqlite.db'));
    return NativeDatabase(dbFile);
  });
}
