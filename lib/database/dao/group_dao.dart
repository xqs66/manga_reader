import 'package:manga_reader/database/database.dart';

class GroupDao {
  static Future<List<GroupData>> selectAllGroups() {
    return appDb.select(appDb.group).get();
  }

  static Future<void> insertGroup(String groupName) {
    return appDb
        .into(appDb.group)
        .insert(GroupCompanion.insert(groupName: groupName, sortOrder: 0));
  }

  static Future<int> deleteGroup(String groupName) async {
    return (appDb.delete(
      appDb.group,
    )..where((group) => group.groupName.equals(groupName))).go();
  }

  static Future<int> updateGroup(
    String groupName,
    GroupCompanion companion,
  ) async {
    return (appDb.update(
      appDb.group,
    )..where((group) => group.groupName.equals(groupName))).write(companion);
  }
}
