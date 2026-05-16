// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $MangaTable extends Manga with TableInfo<$MangaTable, MangaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MangaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentPathMeta = const VerificationMeta(
    'parentPath',
  );
  @override
  late final GeneratedColumn<String> parentPath = GeneratedColumn<String>(
    'parent_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverPathMeta = const VerificationMeta(
    'coverPath',
  );
  @override
  late final GeneratedColumn<String> coverPath = GeneratedColumn<String>(
    'cover_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _groupNameMeta = const VerificationMeta(
    'groupName',
  );
  @override
  late final GeneratedColumn<String> groupName = GeneratedColumn<String>(
    'group_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(Constants.defaultGroupName),
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastReadTimeMeta = const VerificationMeta(
    'lastReadTime',
  );
  @override
  late final GeneratedColumn<DateTime> lastReadTime = GeneratedColumn<DateTime>(
    'last_read_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastReadPageMeta = const VerificationMeta(
    'lastReadPage',
  );
  @override
  late final GeneratedColumn<int> lastReadPage = GeneratedColumn<int>(
    'last_read_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: Constant(0),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageCountMeta = const VerificationMeta(
    'pageCount',
  );
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
    'page_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    parentPath,
    title,
    coverPath,
    groupName,
    tags,
    lastReadTime,
    lastReadPage,
    sortOrder,
    type,
    size,
    pageCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'manga';
  @override
  VerificationContext validateIntegrity(
    Insertable<MangaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('parent_path')) {
      context.handle(
        _parentPathMeta,
        parentPath.isAcceptableOrUnknown(data['parent_path']!, _parentPathMeta),
      );
    } else if (isInserting) {
      context.missing(_parentPathMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('cover_path')) {
      context.handle(
        _coverPathMeta,
        coverPath.isAcceptableOrUnknown(data['cover_path']!, _coverPathMeta),
      );
    }
    if (data.containsKey('group_name')) {
      context.handle(
        _groupNameMeta,
        groupName.isAcceptableOrUnknown(data['group_name']!, _groupNameMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('last_read_time')) {
      context.handle(
        _lastReadTimeMeta,
        lastReadTime.isAcceptableOrUnknown(
          data['last_read_time']!,
          _lastReadTimeMeta,
        ),
      );
    }
    if (data.containsKey('last_read_page')) {
      context.handle(
        _lastReadPageMeta,
        lastReadPage.isAcceptableOrUnknown(
          data['last_read_page']!,
          _lastReadPageMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('page_count')) {
      context.handle(
        _pageCountMeta,
        pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta),
      );
    } else if (isInserting) {
      context.missing(_pageCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MangaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MangaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      parentPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_path'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      coverPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_path'],
      )!,
      groupName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_name'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      lastReadTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_read_time'],
      ),
      lastReadPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_read_page'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
      pageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_count'],
      )!,
    );
  }

  @override
  $MangaTable createAlias(String alias) {
    return $MangaTable(attachedDatabase, alias);
  }
}

class MangaData extends DataClass implements Insertable<MangaData> {
  final String id;
  final String parentPath;
  final String title;
  final String coverPath;
  final String groupName;
  final String? tags;
  final DateTime? lastReadTime;
  final int lastReadPage;
  final int sortOrder;
  final int type;
  final int size;
  final int pageCount;
  const MangaData({
    required this.id,
    required this.parentPath,
    required this.title,
    required this.coverPath,
    required this.groupName,
    this.tags,
    this.lastReadTime,
    required this.lastReadPage,
    required this.sortOrder,
    required this.type,
    required this.size,
    required this.pageCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['parent_path'] = Variable<String>(parentPath);
    map['title'] = Variable<String>(title);
    map['cover_path'] = Variable<String>(coverPath);
    map['group_name'] = Variable<String>(groupName);
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    if (!nullToAbsent || lastReadTime != null) {
      map['last_read_time'] = Variable<DateTime>(lastReadTime);
    }
    map['last_read_page'] = Variable<int>(lastReadPage);
    map['sort_order'] = Variable<int>(sortOrder);
    map['type'] = Variable<int>(type);
    map['size'] = Variable<int>(size);
    map['page_count'] = Variable<int>(pageCount);
    return map;
  }

  MangaCompanion toCompanion(bool nullToAbsent) {
    return MangaCompanion(
      id: Value(id),
      parentPath: Value(parentPath),
      title: Value(title),
      coverPath: Value(coverPath),
      groupName: Value(groupName),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      lastReadTime: lastReadTime == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReadTime),
      lastReadPage: Value(lastReadPage),
      sortOrder: Value(sortOrder),
      type: Value(type),
      size: Value(size),
      pageCount: Value(pageCount),
    );
  }

  factory MangaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MangaData(
      id: serializer.fromJson<String>(json['id']),
      parentPath: serializer.fromJson<String>(json['parentPath']),
      title: serializer.fromJson<String>(json['title']),
      coverPath: serializer.fromJson<String>(json['coverPath']),
      groupName: serializer.fromJson<String>(json['groupName']),
      tags: serializer.fromJson<String?>(json['tags']),
      lastReadTime: serializer.fromJson<DateTime?>(json['lastReadTime']),
      lastReadPage: serializer.fromJson<int>(json['lastReadPage']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      type: serializer.fromJson<int>(json['type']),
      size: serializer.fromJson<int>(json['size']),
      pageCount: serializer.fromJson<int>(json['pageCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parentPath': serializer.toJson<String>(parentPath),
      'title': serializer.toJson<String>(title),
      'coverPath': serializer.toJson<String>(coverPath),
      'groupName': serializer.toJson<String>(groupName),
      'tags': serializer.toJson<String?>(tags),
      'lastReadTime': serializer.toJson<DateTime?>(lastReadTime),
      'lastReadPage': serializer.toJson<int>(lastReadPage),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'type': serializer.toJson<int>(type),
      'size': serializer.toJson<int>(size),
      'pageCount': serializer.toJson<int>(pageCount),
    };
  }

  MangaData copyWith({
    String? id,
    String? parentPath,
    String? title,
    String? coverPath,
    String? groupName,
    Value<String?> tags = const Value.absent(),
    Value<DateTime?> lastReadTime = const Value.absent(),
    int? lastReadPage,
    int? sortOrder,
    int? type,
    int? size,
    int? pageCount,
  }) => MangaData(
    id: id ?? this.id,
    parentPath: parentPath ?? this.parentPath,
    title: title ?? this.title,
    coverPath: coverPath ?? this.coverPath,
    groupName: groupName ?? this.groupName,
    tags: tags.present ? tags.value : this.tags,
    lastReadTime: lastReadTime.present ? lastReadTime.value : this.lastReadTime,
    lastReadPage: lastReadPage ?? this.lastReadPage,
    sortOrder: sortOrder ?? this.sortOrder,
    type: type ?? this.type,
    size: size ?? this.size,
    pageCount: pageCount ?? this.pageCount,
  );
  MangaData copyWithCompanion(MangaCompanion data) {
    return MangaData(
      id: data.id.present ? data.id.value : this.id,
      parentPath: data.parentPath.present
          ? data.parentPath.value
          : this.parentPath,
      title: data.title.present ? data.title.value : this.title,
      coverPath: data.coverPath.present ? data.coverPath.value : this.coverPath,
      groupName: data.groupName.present ? data.groupName.value : this.groupName,
      tags: data.tags.present ? data.tags.value : this.tags,
      lastReadTime: data.lastReadTime.present
          ? data.lastReadTime.value
          : this.lastReadTime,
      lastReadPage: data.lastReadPage.present
          ? data.lastReadPage.value
          : this.lastReadPage,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      type: data.type.present ? data.type.value : this.type,
      size: data.size.present ? data.size.value : this.size,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MangaData(')
          ..write('id: $id, ')
          ..write('parentPath: $parentPath, ')
          ..write('title: $title, ')
          ..write('coverPath: $coverPath, ')
          ..write('groupName: $groupName, ')
          ..write('tags: $tags, ')
          ..write('lastReadTime: $lastReadTime, ')
          ..write('lastReadPage: $lastReadPage, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('type: $type, ')
          ..write('size: $size, ')
          ..write('pageCount: $pageCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    parentPath,
    title,
    coverPath,
    groupName,
    tags,
    lastReadTime,
    lastReadPage,
    sortOrder,
    type,
    size,
    pageCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MangaData &&
          other.id == this.id &&
          other.parentPath == this.parentPath &&
          other.title == this.title &&
          other.coverPath == this.coverPath &&
          other.groupName == this.groupName &&
          other.tags == this.tags &&
          other.lastReadTime == this.lastReadTime &&
          other.lastReadPage == this.lastReadPage &&
          other.sortOrder == this.sortOrder &&
          other.type == this.type &&
          other.size == this.size &&
          other.pageCount == this.pageCount);
}

class MangaCompanion extends UpdateCompanion<MangaData> {
  final Value<String> id;
  final Value<String> parentPath;
  final Value<String> title;
  final Value<String> coverPath;
  final Value<String> groupName;
  final Value<String?> tags;
  final Value<DateTime?> lastReadTime;
  final Value<int> lastReadPage;
  final Value<int> sortOrder;
  final Value<int> type;
  final Value<int> size;
  final Value<int> pageCount;
  final Value<int> rowid;
  const MangaCompanion({
    this.id = const Value.absent(),
    this.parentPath = const Value.absent(),
    this.title = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.groupName = const Value.absent(),
    this.tags = const Value.absent(),
    this.lastReadTime = const Value.absent(),
    this.lastReadPage = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.type = const Value.absent(),
    this.size = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MangaCompanion.insert({
    required String id,
    required String parentPath,
    required String title,
    this.coverPath = const Value.absent(),
    this.groupName = const Value.absent(),
    this.tags = const Value.absent(),
    this.lastReadTime = const Value.absent(),
    this.lastReadPage = const Value.absent(),
    required int sortOrder,
    required int type,
    required int size,
    required int pageCount,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       parentPath = Value(parentPath),
       title = Value(title),
       sortOrder = Value(sortOrder),
       type = Value(type),
       size = Value(size),
       pageCount = Value(pageCount);
  static Insertable<MangaData> custom({
    Expression<String>? id,
    Expression<String>? parentPath,
    Expression<String>? title,
    Expression<String>? coverPath,
    Expression<String>? groupName,
    Expression<String>? tags,
    Expression<DateTime>? lastReadTime,
    Expression<int>? lastReadPage,
    Expression<int>? sortOrder,
    Expression<int>? type,
    Expression<int>? size,
    Expression<int>? pageCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentPath != null) 'parent_path': parentPath,
      if (title != null) 'title': title,
      if (coverPath != null) 'cover_path': coverPath,
      if (groupName != null) 'group_name': groupName,
      if (tags != null) 'tags': tags,
      if (lastReadTime != null) 'last_read_time': lastReadTime,
      if (lastReadPage != null) 'last_read_page': lastReadPage,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (type != null) 'type': type,
      if (size != null) 'size': size,
      if (pageCount != null) 'page_count': pageCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MangaCompanion copyWith({
    Value<String>? id,
    Value<String>? parentPath,
    Value<String>? title,
    Value<String>? coverPath,
    Value<String>? groupName,
    Value<String?>? tags,
    Value<DateTime?>? lastReadTime,
    Value<int>? lastReadPage,
    Value<int>? sortOrder,
    Value<int>? type,
    Value<int>? size,
    Value<int>? pageCount,
    Value<int>? rowid,
  }) {
    return MangaCompanion(
      id: id ?? this.id,
      parentPath: parentPath ?? this.parentPath,
      title: title ?? this.title,
      coverPath: coverPath ?? this.coverPath,
      groupName: groupName ?? this.groupName,
      tags: tags ?? this.tags,
      lastReadTime: lastReadTime ?? this.lastReadTime,
      lastReadPage: lastReadPage ?? this.lastReadPage,
      sortOrder: sortOrder ?? this.sortOrder,
      type: type ?? this.type,
      size: size ?? this.size,
      pageCount: pageCount ?? this.pageCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (parentPath.present) {
      map['parent_path'] = Variable<String>(parentPath.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (coverPath.present) {
      map['cover_path'] = Variable<String>(coverPath.value);
    }
    if (groupName.present) {
      map['group_name'] = Variable<String>(groupName.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (lastReadTime.present) {
      map['last_read_time'] = Variable<DateTime>(lastReadTime.value);
    }
    if (lastReadPage.present) {
      map['last_read_page'] = Variable<int>(lastReadPage.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MangaCompanion(')
          ..write('id: $id, ')
          ..write('parentPath: $parentPath, ')
          ..write('title: $title, ')
          ..write('coverPath: $coverPath, ')
          ..write('groupName: $groupName, ')
          ..write('tags: $tags, ')
          ..write('lastReadTime: $lastReadTime, ')
          ..write('lastReadPage: $lastReadPage, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('type: $type, ')
          ..write('size: $size, ')
          ..write('pageCount: $pageCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupTable extends Group with TableInfo<$GroupTable, GroupData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupNameMeta = const VerificationMeta(
    'groupName',
  );
  @override
  late final GeneratedColumn<String> groupName = GeneratedColumn<String>(
    'group_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentPathMeta = const VerificationMeta(
    'parentPath',
  );
  @override
  late final GeneratedColumn<String> parentPath = GeneratedColumn<String>(
    'parent_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isExpandedMeta = const VerificationMeta(
    'isExpanded',
  );
  @override
  late final GeneratedColumn<bool> isExpanded = GeneratedColumn<bool>(
    'is_expanded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_expanded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    groupName,
    parentPath,
    sortOrder,
    isExpanded,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group';
  @override
  VerificationContext validateIntegrity(
    Insertable<GroupData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_name')) {
      context.handle(
        _groupNameMeta,
        groupName.isAcceptableOrUnknown(data['group_name']!, _groupNameMeta),
      );
    } else if (isInserting) {
      context.missing(_groupNameMeta);
    }
    if (data.containsKey('parent_path')) {
      context.handle(
        _parentPathMeta,
        parentPath.isAcceptableOrUnknown(data['parent_path']!, _parentPathMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('is_expanded')) {
      context.handle(
        _isExpandedMeta,
        isExpanded.isAcceptableOrUnknown(data['is_expanded']!, _isExpandedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupName, parentPath};
  @override
  GroupData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupData(
      groupName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_name'],
      )!,
      parentPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_path'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isExpanded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_expanded'],
      )!,
    );
  }

  @override
  $GroupTable createAlias(String alias) {
    return $GroupTable(attachedDatabase, alias);
  }
}

class GroupData extends DataClass implements Insertable<GroupData> {
  final String groupName;
  final String parentPath;
  final int sortOrder;
  final bool isExpanded;
  const GroupData({
    required this.groupName,
    required this.parentPath,
    required this.sortOrder,
    required this.isExpanded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_name'] = Variable<String>(groupName);
    map['parent_path'] = Variable<String>(parentPath);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_expanded'] = Variable<bool>(isExpanded);
    return map;
  }

  GroupCompanion toCompanion(bool nullToAbsent) {
    return GroupCompanion(
      groupName: Value(groupName),
      parentPath: Value(parentPath),
      sortOrder: Value(sortOrder),
      isExpanded: Value(isExpanded),
    );
  }

  factory GroupData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupData(
      groupName: serializer.fromJson<String>(json['groupName']),
      parentPath: serializer.fromJson<String>(json['parentPath']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isExpanded: serializer.fromJson<bool>(json['isExpanded']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupName': serializer.toJson<String>(groupName),
      'parentPath': serializer.toJson<String>(parentPath),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isExpanded': serializer.toJson<bool>(isExpanded),
    };
  }

  GroupData copyWith({
    String? groupName,
    String? parentPath,
    int? sortOrder,
    bool? isExpanded,
  }) => GroupData(
    groupName: groupName ?? this.groupName,
    parentPath: parentPath ?? this.parentPath,
    sortOrder: sortOrder ?? this.sortOrder,
    isExpanded: isExpanded ?? this.isExpanded,
  );
  GroupData copyWithCompanion(GroupCompanion data) {
    return GroupData(
      groupName: data.groupName.present ? data.groupName.value : this.groupName,
      parentPath: data.parentPath.present
          ? data.parentPath.value
          : this.parentPath,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isExpanded: data.isExpanded.present
          ? data.isExpanded.value
          : this.isExpanded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupData(')
          ..write('groupName: $groupName, ')
          ..write('parentPath: $parentPath, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isExpanded: $isExpanded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(groupName, parentPath, sortOrder, isExpanded);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupData &&
          other.groupName == this.groupName &&
          other.parentPath == this.parentPath &&
          other.sortOrder == this.sortOrder &&
          other.isExpanded == this.isExpanded);
}

class GroupCompanion extends UpdateCompanion<GroupData> {
  final Value<String> groupName;
  final Value<String> parentPath;
  final Value<int> sortOrder;
  final Value<bool> isExpanded;
  final Value<int> rowid;
  const GroupCompanion({
    this.groupName = const Value.absent(),
    this.parentPath = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isExpanded = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupCompanion.insert({
    required String groupName,
    this.parentPath = const Value.absent(),
    required int sortOrder,
    this.isExpanded = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : groupName = Value(groupName),
       sortOrder = Value(sortOrder);
  static Insertable<GroupData> custom({
    Expression<String>? groupName,
    Expression<String>? parentPath,
    Expression<int>? sortOrder,
    Expression<bool>? isExpanded,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupName != null) 'group_name': groupName,
      if (parentPath != null) 'parent_path': parentPath,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isExpanded != null) 'is_expanded': isExpanded,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupCompanion copyWith({
    Value<String>? groupName,
    Value<String>? parentPath,
    Value<int>? sortOrder,
    Value<bool>? isExpanded,
    Value<int>? rowid,
  }) {
    return GroupCompanion(
      groupName: groupName ?? this.groupName,
      parentPath: parentPath ?? this.parentPath,
      sortOrder: sortOrder ?? this.sortOrder,
      isExpanded: isExpanded ?? this.isExpanded,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupName.present) {
      map['group_name'] = Variable<String>(groupName.value);
    }
    if (parentPath.present) {
      map['parent_path'] = Variable<String>(parentPath.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isExpanded.present) {
      map['is_expanded'] = Variable<bool>(isExpanded.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupCompanion(')
          ..write('groupName: $groupName, ')
          ..write('parentPath: $parentPath, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isExpanded: $isExpanded, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MangaTable manga = $MangaTable(this);
  late final $GroupTable group = $GroupTable(this);
  late final Index aIdxParentPath = Index(
    'a_idx_parent_path',
    'CREATE INDEX a_idx_parent_path ON manga (parent_path)',
  );
  late final Index aIdxTitle = Index(
    'a_idx_title',
    'CREATE INDEX a_idx_title ON manga (title)',
  );
  late final Index aIdxGroupName = Index(
    'a_idx_group_name',
    'CREATE INDEX a_idx_group_name ON manga (group_name)',
  );
  late final Index aIdxLastReadPage = Index(
    'a_idx_last_read_page',
    'CREATE INDEX a_idx_last_read_page ON manga (last_read_page)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    manga,
    group,
    aIdxParentPath,
    aIdxTitle,
    aIdxGroupName,
    aIdxLastReadPage,
  ];
}

typedef $$MangaTableCreateCompanionBuilder =
    MangaCompanion Function({
      required String id,
      required String parentPath,
      required String title,
      Value<String> coverPath,
      Value<String> groupName,
      Value<String?> tags,
      Value<DateTime?> lastReadTime,
      Value<int> lastReadPage,
      required int sortOrder,
      required int type,
      required int size,
      required int pageCount,
      Value<int> rowid,
    });
typedef $$MangaTableUpdateCompanionBuilder =
    MangaCompanion Function({
      Value<String> id,
      Value<String> parentPath,
      Value<String> title,
      Value<String> coverPath,
      Value<String> groupName,
      Value<String?> tags,
      Value<DateTime?> lastReadTime,
      Value<int> lastReadPage,
      Value<int> sortOrder,
      Value<int> type,
      Value<int> size,
      Value<int> pageCount,
      Value<int> rowid,
    });

class $$MangaTableFilterComposer extends Composer<_$AppDatabase, $MangaTable> {
  $$MangaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentPath => $composableBuilder(
    column: $table.parentPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReadTime => $composableBuilder(
    column: $table.lastReadTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastReadPage => $composableBuilder(
    column: $table.lastReadPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MangaTableOrderingComposer
    extends Composer<_$AppDatabase, $MangaTable> {
  $$MangaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentPath => $composableBuilder(
    column: $table.parentPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReadTime => $composableBuilder(
    column: $table.lastReadTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastReadPage => $composableBuilder(
    column: $table.lastReadPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MangaTableAnnotationComposer
    extends Composer<_$AppDatabase, $MangaTable> {
  $$MangaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get parentPath => $composableBuilder(
    column: $table.parentPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get coverPath =>
      $composableBuilder(column: $table.coverPath, builder: (column) => column);

  GeneratedColumn<String> get groupName =>
      $composableBuilder(column: $table.groupName, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReadTime => $composableBuilder(
    column: $table.lastReadTime,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastReadPage => $composableBuilder(
    column: $table.lastReadPage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);
}

class $$MangaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MangaTable,
          MangaData,
          $$MangaTableFilterComposer,
          $$MangaTableOrderingComposer,
          $$MangaTableAnnotationComposer,
          $$MangaTableCreateCompanionBuilder,
          $$MangaTableUpdateCompanionBuilder,
          (MangaData, BaseReferences<_$AppDatabase, $MangaTable, MangaData>),
          MangaData,
          PrefetchHooks Function()
        > {
  $$MangaTableTableManager(_$AppDatabase db, $MangaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MangaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MangaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MangaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> parentPath = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> coverPath = const Value.absent(),
                Value<String> groupName = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<DateTime?> lastReadTime = const Value.absent(),
                Value<int> lastReadPage = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<int> pageCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MangaCompanion(
                id: id,
                parentPath: parentPath,
                title: title,
                coverPath: coverPath,
                groupName: groupName,
                tags: tags,
                lastReadTime: lastReadTime,
                lastReadPage: lastReadPage,
                sortOrder: sortOrder,
                type: type,
                size: size,
                pageCount: pageCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String parentPath,
                required String title,
                Value<String> coverPath = const Value.absent(),
                Value<String> groupName = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<DateTime?> lastReadTime = const Value.absent(),
                Value<int> lastReadPage = const Value.absent(),
                required int sortOrder,
                required int type,
                required int size,
                required int pageCount,
                Value<int> rowid = const Value.absent(),
              }) => MangaCompanion.insert(
                id: id,
                parentPath: parentPath,
                title: title,
                coverPath: coverPath,
                groupName: groupName,
                tags: tags,
                lastReadTime: lastReadTime,
                lastReadPage: lastReadPage,
                sortOrder: sortOrder,
                type: type,
                size: size,
                pageCount: pageCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MangaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MangaTable,
      MangaData,
      $$MangaTableFilterComposer,
      $$MangaTableOrderingComposer,
      $$MangaTableAnnotationComposer,
      $$MangaTableCreateCompanionBuilder,
      $$MangaTableUpdateCompanionBuilder,
      (MangaData, BaseReferences<_$AppDatabase, $MangaTable, MangaData>),
      MangaData,
      PrefetchHooks Function()
    >;
typedef $$GroupTableCreateCompanionBuilder =
    GroupCompanion Function({
      required String groupName,
      Value<String> parentPath,
      required int sortOrder,
      Value<bool> isExpanded,
      Value<int> rowid,
    });
typedef $$GroupTableUpdateCompanionBuilder =
    GroupCompanion Function({
      Value<String> groupName,
      Value<String> parentPath,
      Value<int> sortOrder,
      Value<bool> isExpanded,
      Value<int> rowid,
    });

class $$GroupTableFilterComposer extends Composer<_$AppDatabase, $GroupTable> {
  $$GroupTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentPath => $composableBuilder(
    column: $table.parentPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isExpanded => $composableBuilder(
    column: $table.isExpanded,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GroupTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupTable> {
  $$GroupTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentPath => $composableBuilder(
    column: $table.parentPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isExpanded => $composableBuilder(
    column: $table.isExpanded,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GroupTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupTable> {
  $$GroupTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get groupName =>
      $composableBuilder(column: $table.groupName, builder: (column) => column);

  GeneratedColumn<String> get parentPath => $composableBuilder(
    column: $table.parentPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isExpanded => $composableBuilder(
    column: $table.isExpanded,
    builder: (column) => column,
  );
}

class $$GroupTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupTable,
          GroupData,
          $$GroupTableFilterComposer,
          $$GroupTableOrderingComposer,
          $$GroupTableAnnotationComposer,
          $$GroupTableCreateCompanionBuilder,
          $$GroupTableUpdateCompanionBuilder,
          (GroupData, BaseReferences<_$AppDatabase, $GroupTable, GroupData>),
          GroupData,
          PrefetchHooks Function()
        > {
  $$GroupTableTableManager(_$AppDatabase db, $GroupTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> groupName = const Value.absent(),
                Value<String> parentPath = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isExpanded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupCompanion(
                groupName: groupName,
                parentPath: parentPath,
                sortOrder: sortOrder,
                isExpanded: isExpanded,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String groupName,
                Value<String> parentPath = const Value.absent(),
                required int sortOrder,
                Value<bool> isExpanded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupCompanion.insert(
                groupName: groupName,
                parentPath: parentPath,
                sortOrder: sortOrder,
                isExpanded: isExpanded,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GroupTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupTable,
      GroupData,
      $$GroupTableFilterComposer,
      $$GroupTableOrderingComposer,
      $$GroupTableAnnotationComposer,
      $$GroupTableCreateCompanionBuilder,
      $$GroupTableUpdateCompanionBuilder,
      (GroupData, BaseReferences<_$AppDatabase, $GroupTable, GroupData>),
      GroupData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MangaTableTableManager get manga =>
      $$MangaTableTableManager(_db, _db.manga);
  $$GroupTableTableManager get group =>
      $$GroupTableTableManager(_db, _db.group);
}
