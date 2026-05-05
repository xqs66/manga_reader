import 'package:manga_reader/database/database.dart';

class GroupDao {
  static Future<List<GroupData>> selectAllGroups(String parentPath) {
    return (appDb.select(appDb.group)
          ..where((g) => g.parentPath.equals(parentPath)))
        .get();
  }

  static Future<void> insertGroup(String groupName, String parentPath) {
    return appDb.into(appDb.group).insert(
          GroupCompanion.insert(
              groupName: groupName, parentPath: parentPath, sortOrder: 0),
        );
  }

  static Future<int> deleteGroup(String groupName, String parentPath) async {
    return (appDb.delete(appDb.group)
          ..where((g) => g.groupName.equals(groupName))
          ..where((g) => g.parentPath.equals(parentPath)))
        .go();
  }

  static Future<int> updateGroup(
    String groupName,
    String parentPath,
    GroupCompanion companion,
  ) async {
    return (appDb.update(appDb.group)
          ..where((g) => g.groupName.equals(groupName))
          ..where((g) => g.parentPath.equals(parentPath)))
        .write(companion);
  }
}
