import 'package:manga_reader/database/database.dart';

class GroupDao {
  static Future<List<String>> selectAllGroups() async {
    final groups = await appDb.select(appDb.group).get();
    return groups.map((e) => e.groupName).toList();
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
}
