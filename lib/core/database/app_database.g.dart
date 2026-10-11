// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TodosTable extends Todos with TableInfo<$TodosTable, Todo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TodosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
      'due_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dueTimeMeta =
      const VerificationMeta('dueTime');
  @override
  late final GeneratedColumn<String> dueTime = GeneratedColumn<String>(
      'due_time', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isTopMeta = const VerificationMeta('isTop');
  @override
  late final GeneratedColumn<bool> isTop = GeneratedColumn<bool>(
      'is_top', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_top" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _estimatedPomodorosMeta =
      const VerificationMeta('estimatedPomodoros');
  @override
  late final GeneratedColumn<int> estimatedPomodoros = GeneratedColumn<int>(
      'estimated_pomodoros', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _actualPomodorosMeta =
      const VerificationMeta('actualPomodoros');
  @override
  late final GeneratedColumn<int> actualPomodoros = GeneratedColumn<int>(
      'actual_pomodoros', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        description,
        priority,
        status,
        dueDate,
        dueTime,
        categoryId,
        isTop,
        estimatedPomodoros,
        actualPomodoros,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'todos';
  @override
  VerificationContext validateIntegrity(Insertable<Todo> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('due_time')) {
      context.handle(_dueTimeMeta,
          dueTime.isAcceptableOrUnknown(data['due_time']!, _dueTimeMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('is_top')) {
      context.handle(
          _isTopMeta, isTop.isAcceptableOrUnknown(data['is_top']!, _isTopMeta));
    }
    if (data.containsKey('estimated_pomodoros')) {
      context.handle(
          _estimatedPomodorosMeta,
          estimatedPomodoros.isAcceptableOrUnknown(
              data['estimated_pomodoros']!, _estimatedPomodorosMeta));
    }
    if (data.containsKey('actual_pomodoros')) {
      context.handle(
          _actualPomodorosMeta,
          actualPomodoros.isAcceptableOrUnknown(
              data['actual_pomodoros']!, _actualPomodorosMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Todo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Todo(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}due_date']),
      dueTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}due_time']),
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      isTop: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_top'])!,
      estimatedPomodoros: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}estimated_pomodoros'])!,
      actualPomodoros: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}actual_pomodoros'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $TodosTable createAlias(String alias) {
    return $TodosTable(attachedDatabase, alias);
  }
}

class Todo extends DataClass implements Insertable<Todo> {
  final String id;
  final String title;
  final String? description;
  final int priority;
  final String status;
  final String? dueDate;
  final String? dueTime;
  final String? categoryId;
  final bool isTop;
  final int estimatedPomodoros;
  final int actualPomodoros;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const Todo(
      {required this.id,
      required this.title,
      this.description,
      required this.priority,
      required this.status,
      this.dueDate,
      this.dueTime,
      this.categoryId,
      required this.isTop,
      required this.estimatedPomodoros,
      required this.actualPomodoros,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['priority'] = Variable<int>(priority);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<String>(dueDate);
    }
    if (!nullToAbsent || dueTime != null) {
      map['due_time'] = Variable<String>(dueTime);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['is_top'] = Variable<bool>(isTop);
    map['estimated_pomodoros'] = Variable<int>(estimatedPomodoros);
    map['actual_pomodoros'] = Variable<int>(actualPomodoros);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  TodosCompanion toCompanion(bool nullToAbsent) {
    return TodosCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      priority: Value(priority),
      status: Value(status),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      dueTime: dueTime == null && nullToAbsent
          ? const Value.absent()
          : Value(dueTime),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      isTop: Value(isTop),
      estimatedPomodoros: Value(estimatedPomodoros),
      actualPomodoros: Value(actualPomodoros),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Todo.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Todo(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      priority: serializer.fromJson<int>(json['priority']),
      status: serializer.fromJson<String>(json['status']),
      dueDate: serializer.fromJson<String?>(json['dueDate']),
      dueTime: serializer.fromJson<String?>(json['dueTime']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      isTop: serializer.fromJson<bool>(json['isTop']),
      estimatedPomodoros: serializer.fromJson<int>(json['estimatedPomodoros']),
      actualPomodoros: serializer.fromJson<int>(json['actualPomodoros']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'priority': serializer.toJson<int>(priority),
      'status': serializer.toJson<String>(status),
      'dueDate': serializer.toJson<String?>(dueDate),
      'dueTime': serializer.toJson<String?>(dueTime),
      'categoryId': serializer.toJson<String?>(categoryId),
      'isTop': serializer.toJson<bool>(isTop),
      'estimatedPomodoros': serializer.toJson<int>(estimatedPomodoros),
      'actualPomodoros': serializer.toJson<int>(actualPomodoros),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  Todo copyWith(
          {String? id,
          String? title,
          Value<String?> description = const Value.absent(),
          int? priority,
          String? status,
          Value<String?> dueDate = const Value.absent(),
          Value<String?> dueTime = const Value.absent(),
          Value<String?> categoryId = const Value.absent(),
          bool? isTop,
          int? estimatedPomodoros,
          int? actualPomodoros,
          int? createdAt,
          int? updatedAt,
          Value<int?> deletedAt = const Value.absent()}) =>
      Todo(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        dueTime: dueTime.present ? dueTime.value : this.dueTime,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        isTop: isTop ?? this.isTop,
        estimatedPomodoros: estimatedPomodoros ?? this.estimatedPomodoros,
        actualPomodoros: actualPomodoros ?? this.actualPomodoros,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Todo copyWithCompanion(TodosCompanion data) {
    return Todo(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      priority: data.priority.present ? data.priority.value : this.priority,
      status: data.status.present ? data.status.value : this.status,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      dueTime: data.dueTime.present ? data.dueTime.value : this.dueTime,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      isTop: data.isTop.present ? data.isTop.value : this.isTop,
      estimatedPomodoros: data.estimatedPomodoros.present
          ? data.estimatedPomodoros.value
          : this.estimatedPomodoros,
      actualPomodoros: data.actualPomodoros.present
          ? data.actualPomodoros.value
          : this.actualPomodoros,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Todo(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('dueDate: $dueDate, ')
          ..write('dueTime: $dueTime, ')
          ..write('categoryId: $categoryId, ')
          ..write('isTop: $isTop, ')
          ..write('estimatedPomodoros: $estimatedPomodoros, ')
          ..write('actualPomodoros: $actualPomodoros, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      description,
      priority,
      status,
      dueDate,
      dueTime,
      categoryId,
      isTop,
      estimatedPomodoros,
      actualPomodoros,
      createdAt,
      updatedAt,
      deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Todo &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.priority == this.priority &&
          other.status == this.status &&
          other.dueDate == this.dueDate &&
          other.dueTime == this.dueTime &&
          other.categoryId == this.categoryId &&
          other.isTop == this.isTop &&
          other.estimatedPomodoros == this.estimatedPomodoros &&
          other.actualPomodoros == this.actualPomodoros &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class TodosCompanion extends UpdateCompanion<Todo> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<int> priority;
  final Value<String> status;
  final Value<String?> dueDate;
  final Value<String?> dueTime;
  final Value<String?> categoryId;
  final Value<bool> isTop;
  final Value<int> estimatedPomodoros;
  final Value<int> actualPomodoros;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const TodosCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.dueTime = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.isTop = const Value.absent(),
    this.estimatedPomodoros = const Value.absent(),
    this.actualPomodoros = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TodosCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.dueTime = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.isTop = const Value.absent(),
    this.estimatedPomodoros = const Value.absent(),
    this.actualPomodoros = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Todo> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? priority,
    Expression<String>? status,
    Expression<String>? dueDate,
    Expression<String>? dueTime,
    Expression<String>? categoryId,
    Expression<bool>? isTop,
    Expression<int>? estimatedPomodoros,
    Expression<int>? actualPomodoros,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (dueDate != null) 'due_date': dueDate,
      if (dueTime != null) 'due_time': dueTime,
      if (categoryId != null) 'category_id': categoryId,
      if (isTop != null) 'is_top': isTop,
      if (estimatedPomodoros != null) 'estimated_pomodoros': estimatedPomodoros,
      if (actualPomodoros != null) 'actual_pomodoros': actualPomodoros,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TodosCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String?>? description,
      Value<int>? priority,
      Value<String>? status,
      Value<String?>? dueDate,
      Value<String?>? dueTime,
      Value<String?>? categoryId,
      Value<bool>? isTop,
      Value<int>? estimatedPomodoros,
      Value<int>? actualPomodoros,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return TodosCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      categoryId: categoryId ?? this.categoryId,
      isTop: isTop ?? this.isTop,
      estimatedPomodoros: estimatedPomodoros ?? this.estimatedPomodoros,
      actualPomodoros: actualPomodoros ?? this.actualPomodoros,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (dueTime.present) {
      map['due_time'] = Variable<String>(dueTime.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (isTop.present) {
      map['is_top'] = Variable<bool>(isTop.value);
    }
    if (estimatedPomodoros.present) {
      map['estimated_pomodoros'] = Variable<int>(estimatedPomodoros.value);
    }
    if (actualPomodoros.present) {
      map['actual_pomodoros'] = Variable<int>(actualPomodoros.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodosCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('dueDate: $dueDate, ')
          ..write('dueTime: $dueTime, ')
          ..write('categoryId: $categoryId, ')
          ..write('isTop: $isTop, ')
          ..write('estimatedPomodoros: $estimatedPomodoros, ')
          ..write('actualPomodoros: $actualPomodoros, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SubtasksTable extends Subtasks with TableInfo<$SubtasksTable, Subtask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubtasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _todoIdMeta = const VerificationMeta('todoId');
  @override
  late final GeneratedColumn<String> todoId = GeneratedColumn<String>(
      'todo_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isCompletedMeta =
      const VerificationMeta('isCompleted');
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
      'is_completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        todoId,
        title,
        isCompleted,
        sortOrder,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subtasks';
  @override
  VerificationContext validateIntegrity(Insertable<Subtask> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('todo_id')) {
      context.handle(_todoIdMeta,
          todoId.isAcceptableOrUnknown(data['todo_id']!, _todoIdMeta));
    } else if (isInserting) {
      context.missing(_todoIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
          _isCompletedMeta,
          isCompleted.isAcceptableOrUnknown(
              data['is_completed']!, _isCompletedMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Subtask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subtask(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      todoId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}todo_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      isCompleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_completed'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $SubtasksTable createAlias(String alias) {
    return $SubtasksTable(attachedDatabase, alias);
  }
}

class Subtask extends DataClass implements Insertable<Subtask> {
  final String id;
  final String todoId;
  final String title;
  final bool isCompleted;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const Subtask(
      {required this.id,
      required this.todoId,
      required this.title,
      required this.isCompleted,
      required this.sortOrder,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['todo_id'] = Variable<String>(todoId);
    map['title'] = Variable<String>(title);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  SubtasksCompanion toCompanion(bool nullToAbsent) {
    return SubtasksCompanion(
      id: Value(id),
      todoId: Value(todoId),
      title: Value(title),
      isCompleted: Value(isCompleted),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Subtask.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subtask(
      id: serializer.fromJson<String>(json['id']),
      todoId: serializer.fromJson<String>(json['todoId']),
      title: serializer.fromJson<String>(json['title']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'todoId': serializer.toJson<String>(todoId),
      'title': serializer.toJson<String>(title),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  Subtask copyWith(
          {String? id,
          String? todoId,
          String? title,
          bool? isCompleted,
          int? sortOrder,
          int? createdAt,
          int? updatedAt,
          Value<int?> deletedAt = const Value.absent()}) =>
      Subtask(
        id: id ?? this.id,
        todoId: todoId ?? this.todoId,
        title: title ?? this.title,
        isCompleted: isCompleted ?? this.isCompleted,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Subtask copyWithCompanion(SubtasksCompanion data) {
    return Subtask(
      id: data.id.present ? data.id.value : this.id,
      todoId: data.todoId.present ? data.todoId.value : this.todoId,
      title: data.title.present ? data.title.value : this.title,
      isCompleted:
          data.isCompleted.present ? data.isCompleted.value : this.isCompleted,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subtask(')
          ..write('id: $id, ')
          ..write('todoId: $todoId, ')
          ..write('title: $title, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, todoId, title, isCompleted, sortOrder,
      createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subtask &&
          other.id == this.id &&
          other.todoId == this.todoId &&
          other.title == this.title &&
          other.isCompleted == this.isCompleted &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class SubtasksCompanion extends UpdateCompanion<Subtask> {
  final Value<String> id;
  final Value<String> todoId;
  final Value<String> title;
  final Value<bool> isCompleted;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const SubtasksCompanion({
    this.id = const Value.absent(),
    this.todoId = const Value.absent(),
    this.title = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubtasksCompanion.insert({
    required String id,
    required String todoId,
    required String title,
    this.isCompleted = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        todoId = Value(todoId),
        title = Value(title),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Subtask> custom({
    Expression<String>? id,
    Expression<String>? todoId,
    Expression<String>? title,
    Expression<bool>? isCompleted,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (todoId != null) 'todo_id': todoId,
      if (title != null) 'title': title,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubtasksCompanion copyWith(
      {Value<String>? id,
      Value<String>? todoId,
      Value<String>? title,
      Value<bool>? isCompleted,
      Value<int>? sortOrder,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return SubtasksCompanion(
      id: id ?? this.id,
      todoId: todoId ?? this.todoId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (todoId.present) {
      map['todo_id'] = Variable<String>(todoId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubtasksCompanion(')
          ..write('id: $id, ')
          ..write('todoId: $todoId, ')
          ..write('title: $title, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SchedulesTable extends Schedules
    with TableInfo<$SchedulesTable, Schedule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchedulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _todoIdMeta = const VerificationMeta('todoId');
  @override
  late final GeneratedColumn<String> todoId = GeneratedColumn<String>(
      'todo_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<int> startTime = GeneratedColumn<int>(
      'start_time', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<int> endTime = GeneratedColumn<int>(
      'end_time', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _allDayMeta = const VerificationMeta('allDay');
  @override
  late final GeneratedColumn<bool> allDay = GeneratedColumn<bool>(
      'all_day', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("all_day" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _colorHexMeta =
      const VerificationMeta('colorHex');
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
      'color_hex', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('#4A90E2'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        todoId,
        title,
        startTime,
        endTime,
        allDay,
        colorHex,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedules';
  @override
  VerificationContext validateIntegrity(Insertable<Schedule> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('todo_id')) {
      context.handle(_todoIdMeta,
          todoId.isAcceptableOrUnknown(data['todo_id']!, _todoIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('all_day')) {
      context.handle(_allDayMeta,
          allDay.isAcceptableOrUnknown(data['all_day']!, _allDayMeta));
    }
    if (data.containsKey('color_hex')) {
      context.handle(_colorHexMeta,
          colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Schedule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Schedule(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      todoId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}todo_id']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end_time'])!,
      allDay: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}all_day'])!,
      colorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_hex'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $SchedulesTable createAlias(String alias) {
    return $SchedulesTable(attachedDatabase, alias);
  }
}

class Schedule extends DataClass implements Insertable<Schedule> {
  final String id;
  final String? todoId;
  final String title;
  final int startTime;
  final int endTime;
  final bool allDay;
  final String colorHex;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const Schedule(
      {required this.id,
      this.todoId,
      required this.title,
      required this.startTime,
      required this.endTime,
      required this.allDay,
      required this.colorHex,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || todoId != null) {
      map['todo_id'] = Variable<String>(todoId);
    }
    map['title'] = Variable<String>(title);
    map['start_time'] = Variable<int>(startTime);
    map['end_time'] = Variable<int>(endTime);
    map['all_day'] = Variable<bool>(allDay);
    map['color_hex'] = Variable<String>(colorHex);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  SchedulesCompanion toCompanion(bool nullToAbsent) {
    return SchedulesCompanion(
      id: Value(id),
      todoId:
          todoId == null && nullToAbsent ? const Value.absent() : Value(todoId),
      title: Value(title),
      startTime: Value(startTime),
      endTime: Value(endTime),
      allDay: Value(allDay),
      colorHex: Value(colorHex),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Schedule.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Schedule(
      id: serializer.fromJson<String>(json['id']),
      todoId: serializer.fromJson<String?>(json['todoId']),
      title: serializer.fromJson<String>(json['title']),
      startTime: serializer.fromJson<int>(json['startTime']),
      endTime: serializer.fromJson<int>(json['endTime']),
      allDay: serializer.fromJson<bool>(json['allDay']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'todoId': serializer.toJson<String?>(todoId),
      'title': serializer.toJson<String>(title),
      'startTime': serializer.toJson<int>(startTime),
      'endTime': serializer.toJson<int>(endTime),
      'allDay': serializer.toJson<bool>(allDay),
      'colorHex': serializer.toJson<String>(colorHex),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  Schedule copyWith(
          {String? id,
          Value<String?> todoId = const Value.absent(),
          String? title,
          int? startTime,
          int? endTime,
          bool? allDay,
          String? colorHex,
          int? createdAt,
          int? updatedAt,
          Value<int?> deletedAt = const Value.absent()}) =>
      Schedule(
        id: id ?? this.id,
        todoId: todoId.present ? todoId.value : this.todoId,
        title: title ?? this.title,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        allDay: allDay ?? this.allDay,
        colorHex: colorHex ?? this.colorHex,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Schedule copyWithCompanion(SchedulesCompanion data) {
    return Schedule(
      id: data.id.present ? data.id.value : this.id,
      todoId: data.todoId.present ? data.todoId.value : this.todoId,
      title: data.title.present ? data.title.value : this.title,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      allDay: data.allDay.present ? data.allDay.value : this.allDay,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Schedule(')
          ..write('id: $id, ')
          ..write('todoId: $todoId, ')
          ..write('title: $title, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('allDay: $allDay, ')
          ..write('colorHex: $colorHex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, todoId, title, startTime, endTime, allDay,
      colorHex, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Schedule &&
          other.id == this.id &&
          other.todoId == this.todoId &&
          other.title == this.title &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.allDay == this.allDay &&
          other.colorHex == this.colorHex &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class SchedulesCompanion extends UpdateCompanion<Schedule> {
  final Value<String> id;
  final Value<String?> todoId;
  final Value<String> title;
  final Value<int> startTime;
  final Value<int> endTime;
  final Value<bool> allDay;
  final Value<String> colorHex;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const SchedulesCompanion({
    this.id = const Value.absent(),
    this.todoId = const Value.absent(),
    this.title = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.allDay = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SchedulesCompanion.insert({
    required String id,
    this.todoId = const Value.absent(),
    required String title,
    required int startTime,
    required int endTime,
    this.allDay = const Value.absent(),
    this.colorHex = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        startTime = Value(startTime),
        endTime = Value(endTime),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Schedule> custom({
    Expression<String>? id,
    Expression<String>? todoId,
    Expression<String>? title,
    Expression<int>? startTime,
    Expression<int>? endTime,
    Expression<bool>? allDay,
    Expression<String>? colorHex,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (todoId != null) 'todo_id': todoId,
      if (title != null) 'title': title,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (allDay != null) 'all_day': allDay,
      if (colorHex != null) 'color_hex': colorHex,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SchedulesCompanion copyWith(
      {Value<String>? id,
      Value<String?>? todoId,
      Value<String>? title,
      Value<int>? startTime,
      Value<int>? endTime,
      Value<bool>? allDay,
      Value<String>? colorHex,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return SchedulesCompanion(
      id: id ?? this.id,
      todoId: todoId ?? this.todoId,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      allDay: allDay ?? this.allDay,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (todoId.present) {
      map['todo_id'] = Variable<String>(todoId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<int>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<int>(endTime.value);
    }
    if (allDay.present) {
      map['all_day'] = Variable<bool>(allDay.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SchedulesCompanion(')
          ..write('id: $id, ')
          ..write('todoId: $todoId, ')
          ..write('title: $title, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('allDay: $allDay, ')
          ..write('colorHex: $colorHex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemosTable extends Memos with TableInfo<$MemosTable, Memo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorHexMeta =
      const VerificationMeta('colorHex');
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
      'color_hex', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('#F9F9FB'));
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
      'tag', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isPinnedMeta =
      const VerificationMeta('isPinned');
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
      'is_pinned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_pinned" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, content, colorHex, tag, isPinned, createdAt, updatedAt, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memos';
  @override
  VerificationContext validateIntegrity(Insertable<Memo> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(_colorHexMeta,
          colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta));
    }
    if (data.containsKey('tag')) {
      context.handle(
          _tagMeta, tag.isAcceptableOrUnknown(data['tag']!, _tagMeta));
    }
    if (data.containsKey('is_pinned')) {
      context.handle(_isPinnedMeta,
          isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Memo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Memo(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      colorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_hex'])!,
      tag: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tag']),
      isPinned: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_pinned'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $MemosTable createAlias(String alias) {
    return $MemosTable(attachedDatabase, alias);
  }
}

class Memo extends DataClass implements Insertable<Memo> {
  final String id;
  final String content;
  final String colorHex;
  final String? tag;
  final bool isPinned;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const Memo(
      {required this.id,
      required this.content,
      required this.colorHex,
      this.tag,
      required this.isPinned,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['content'] = Variable<String>(content);
    map['color_hex'] = Variable<String>(colorHex);
    if (!nullToAbsent || tag != null) {
      map['tag'] = Variable<String>(tag);
    }
    map['is_pinned'] = Variable<bool>(isPinned);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  MemosCompanion toCompanion(bool nullToAbsent) {
    return MemosCompanion(
      id: Value(id),
      content: Value(content),
      colorHex: Value(colorHex),
      tag: tag == null && nullToAbsent ? const Value.absent() : Value(tag),
      isPinned: Value(isPinned),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Memo.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Memo(
      id: serializer.fromJson<String>(json['id']),
      content: serializer.fromJson<String>(json['content']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      tag: serializer.fromJson<String?>(json['tag']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'content': serializer.toJson<String>(content),
      'colorHex': serializer.toJson<String>(colorHex),
      'tag': serializer.toJson<String?>(tag),
      'isPinned': serializer.toJson<bool>(isPinned),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  Memo copyWith(
          {String? id,
          String? content,
          String? colorHex,
          Value<String?> tag = const Value.absent(),
          bool? isPinned,
          int? createdAt,
          int? updatedAt,
          Value<int?> deletedAt = const Value.absent()}) =>
      Memo(
        id: id ?? this.id,
        content: content ?? this.content,
        colorHex: colorHex ?? this.colorHex,
        tag: tag.present ? tag.value : this.tag,
        isPinned: isPinned ?? this.isPinned,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Memo copyWithCompanion(MemosCompanion data) {
    return Memo(
      id: data.id.present ? data.id.value : this.id,
      content: data.content.present ? data.content.value : this.content,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      tag: data.tag.present ? data.tag.value : this.tag,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Memo(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('colorHex: $colorHex, ')
          ..write('tag: $tag, ')
          ..write('isPinned: $isPinned, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, content, colorHex, tag, isPinned, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Memo &&
          other.id == this.id &&
          other.content == this.content &&
          other.colorHex == this.colorHex &&
          other.tag == this.tag &&
          other.isPinned == this.isPinned &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class MemosCompanion extends UpdateCompanion<Memo> {
  final Value<String> id;
  final Value<String> content;
  final Value<String> colorHex;
  final Value<String?> tag;
  final Value<bool> isPinned;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const MemosCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.tag = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemosCompanion.insert({
    required String id,
    required String content,
    this.colorHex = const Value.absent(),
    this.tag = const Value.absent(),
    this.isPinned = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        content = Value(content),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Memo> custom({
    Expression<String>? id,
    Expression<String>? content,
    Expression<String>? colorHex,
    Expression<String>? tag,
    Expression<bool>? isPinned,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (content != null) 'content': content,
      if (colorHex != null) 'color_hex': colorHex,
      if (tag != null) 'tag': tag,
      if (isPinned != null) 'is_pinned': isPinned,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemosCompanion copyWith(
      {Value<String>? id,
      Value<String>? content,
      Value<String>? colorHex,
      Value<String?>? tag,
      Value<bool>? isPinned,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return MemosCompanion(
      id: id ?? this.id,
      content: content ?? this.content,
      colorHex: colorHex ?? this.colorHex,
      tag: tag ?? this.tag,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemosCompanion(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('colorHex: $colorHex, ')
          ..write('tag: $tag, ')
          ..write('isPinned: $isPinned, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PomodoroLogsTable extends PomodoroLogs
    with TableInfo<$PomodoroLogsTable, PomodoroLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PomodoroLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _todoIdMeta = const VerificationMeta('todoId');
  @override
  late final GeneratedColumn<String> todoId = GeneratedColumn<String>(
      'todo_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _durationMinutesMeta =
      const VerificationMeta('durationMinutes');
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
      'duration_minutes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
      'mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pomodoro'));
  static const VerificationMeta _cycleRoundMeta =
      const VerificationMeta('cycleRound');
  @override
  late final GeneratedColumn<int> cycleRound = GeneratedColumn<int>(
      'cycle_round', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
      'started_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _endedAtMeta =
      const VerificationMeta('endedAt');
  @override
  late final GeneratedColumn<int> endedAt = GeneratedColumn<int>(
      'ended_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        todoId,
        durationMinutes,
        mode,
        cycleRound,
        startedAt,
        endedAt,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pomodoro_logs';
  @override
  VerificationContext validateIntegrity(Insertable<PomodoroLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('todo_id')) {
      context.handle(_todoIdMeta,
          todoId.isAcceptableOrUnknown(data['todo_id']!, _todoIdMeta));
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
          _durationMinutesMeta,
          durationMinutes.isAcceptableOrUnknown(
              data['duration_minutes']!, _durationMinutesMeta));
    } else if (isInserting) {
      context.missing(_durationMinutesMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
          _modeMeta, mode.isAcceptableOrUnknown(data['mode']!, _modeMeta));
    }
    if (data.containsKey('cycle_round')) {
      context.handle(
          _cycleRoundMeta,
          cycleRound.isAcceptableOrUnknown(
              data['cycle_round']!, _cycleRoundMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(_endedAtMeta,
          endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta));
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PomodoroLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PomodoroLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      todoId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}todo_id']),
      durationMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_minutes'])!,
      mode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mode'])!,
      cycleRound: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cycle_round'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}started_at'])!,
      endedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ended_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $PomodoroLogsTable createAlias(String alias) {
    return $PomodoroLogsTable(attachedDatabase, alias);
  }
}

class PomodoroLog extends DataClass implements Insertable<PomodoroLog> {
  final String id;
  final String? todoId;
  final int durationMinutes;
  final String mode;
  final int cycleRound;
  final int startedAt;
  final int endedAt;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const PomodoroLog(
      {required this.id,
      this.todoId,
      required this.durationMinutes,
      required this.mode,
      required this.cycleRound,
      required this.startedAt,
      required this.endedAt,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || todoId != null) {
      map['todo_id'] = Variable<String>(todoId);
    }
    map['duration_minutes'] = Variable<int>(durationMinutes);
    map['mode'] = Variable<String>(mode);
    map['cycle_round'] = Variable<int>(cycleRound);
    map['started_at'] = Variable<int>(startedAt);
    map['ended_at'] = Variable<int>(endedAt);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  PomodoroLogsCompanion toCompanion(bool nullToAbsent) {
    return PomodoroLogsCompanion(
      id: Value(id),
      todoId:
          todoId == null && nullToAbsent ? const Value.absent() : Value(todoId),
      durationMinutes: Value(durationMinutes),
      mode: Value(mode),
      cycleRound: Value(cycleRound),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory PomodoroLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PomodoroLog(
      id: serializer.fromJson<String>(json['id']),
      todoId: serializer.fromJson<String?>(json['todoId']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      mode: serializer.fromJson<String>(json['mode']),
      cycleRound: serializer.fromJson<int>(json['cycleRound']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      endedAt: serializer.fromJson<int>(json['endedAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'todoId': serializer.toJson<String?>(todoId),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'mode': serializer.toJson<String>(mode),
      'cycleRound': serializer.toJson<int>(cycleRound),
      'startedAt': serializer.toJson<int>(startedAt),
      'endedAt': serializer.toJson<int>(endedAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  PomodoroLog copyWith(
          {String? id,
          Value<String?> todoId = const Value.absent(),
          int? durationMinutes,
          String? mode,
          int? cycleRound,
          int? startedAt,
          int? endedAt,
          int? createdAt,
          int? updatedAt,
          Value<int?> deletedAt = const Value.absent()}) =>
      PomodoroLog(
        id: id ?? this.id,
        todoId: todoId.present ? todoId.value : this.todoId,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        mode: mode ?? this.mode,
        cycleRound: cycleRound ?? this.cycleRound,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt ?? this.endedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  PomodoroLog copyWithCompanion(PomodoroLogsCompanion data) {
    return PomodoroLog(
      id: data.id.present ? data.id.value : this.id,
      todoId: data.todoId.present ? data.todoId.value : this.todoId,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      mode: data.mode.present ? data.mode.value : this.mode,
      cycleRound:
          data.cycleRound.present ? data.cycleRound.value : this.cycleRound,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PomodoroLog(')
          ..write('id: $id, ')
          ..write('todoId: $todoId, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('mode: $mode, ')
          ..write('cycleRound: $cycleRound, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, todoId, durationMinutes, mode, cycleRound,
      startedAt, endedAt, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PomodoroLog &&
          other.id == this.id &&
          other.todoId == this.todoId &&
          other.durationMinutes == this.durationMinutes &&
          other.mode == this.mode &&
          other.cycleRound == this.cycleRound &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class PomodoroLogsCompanion extends UpdateCompanion<PomodoroLog> {
  final Value<String> id;
  final Value<String?> todoId;
  final Value<int> durationMinutes;
  final Value<String> mode;
  final Value<int> cycleRound;
  final Value<int> startedAt;
  final Value<int> endedAt;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const PomodoroLogsCompanion({
    this.id = const Value.absent(),
    this.todoId = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.mode = const Value.absent(),
    this.cycleRound = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PomodoroLogsCompanion.insert({
    required String id,
    this.todoId = const Value.absent(),
    required int durationMinutes,
    this.mode = const Value.absent(),
    this.cycleRound = const Value.absent(),
    required int startedAt,
    required int endedAt,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        durationMinutes = Value(durationMinutes),
        startedAt = Value(startedAt),
        endedAt = Value(endedAt),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<PomodoroLog> custom({
    Expression<String>? id,
    Expression<String>? todoId,
    Expression<int>? durationMinutes,
    Expression<String>? mode,
    Expression<int>? cycleRound,
    Expression<int>? startedAt,
    Expression<int>? endedAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (todoId != null) 'todo_id': todoId,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (mode != null) 'mode': mode,
      if (cycleRound != null) 'cycle_round': cycleRound,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PomodoroLogsCompanion copyWith(
      {Value<String>? id,
      Value<String?>? todoId,
      Value<int>? durationMinutes,
      Value<String>? mode,
      Value<int>? cycleRound,
      Value<int>? startedAt,
      Value<int>? endedAt,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return PomodoroLogsCompanion(
      id: id ?? this.id,
      todoId: todoId ?? this.todoId,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      mode: mode ?? this.mode,
      cycleRound: cycleRound ?? this.cycleRound,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (todoId.present) {
      map['todo_id'] = Variable<String>(todoId.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (cycleRound.present) {
      map['cycle_round'] = Variable<int>(cycleRound.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<int>(endedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PomodoroLogsCompanion(')
          ..write('id: $id, ')
          ..write('todoId: $todoId, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('mode: $mode, ')
          ..write('cycleRound: $cycleRound, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HabitsTable extends Habits with TableInfo<$HabitsTable, Habit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _frequencyTypeMeta =
      const VerificationMeta('frequencyType');
  @override
  late final GeneratedColumn<String> frequencyType = GeneratedColumn<String>(
      'frequency_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetDaysPerWeekMeta =
      const VerificationMeta('targetDaysPerWeek');
  @override
  late final GeneratedColumn<int> targetDaysPerWeek = GeneratedColumn<int>(
      'target_days_per_week', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _iconNameMeta =
      const VerificationMeta('iconName');
  @override
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
      'icon_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('check_circle'));
  static const VerificationMeta _colorHexMeta =
      const VerificationMeta('colorHex');
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
      'color_hex', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('#52C41A'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        frequencyType,
        targetDaysPerWeek,
        iconName,
        colorHex,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habits';
  @override
  VerificationContext validateIntegrity(Insertable<Habit> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('frequency_type')) {
      context.handle(
          _frequencyTypeMeta,
          frequencyType.isAcceptableOrUnknown(
              data['frequency_type']!, _frequencyTypeMeta));
    } else if (isInserting) {
      context.missing(_frequencyTypeMeta);
    }
    if (data.containsKey('target_days_per_week')) {
      context.handle(
          _targetDaysPerWeekMeta,
          targetDaysPerWeek.isAcceptableOrUnknown(
              data['target_days_per_week']!, _targetDaysPerWeekMeta));
    }
    if (data.containsKey('icon_name')) {
      context.handle(_iconNameMeta,
          iconName.isAcceptableOrUnknown(data['icon_name']!, _iconNameMeta));
    }
    if (data.containsKey('color_hex')) {
      context.handle(_colorHexMeta,
          colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Habit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Habit(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      frequencyType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}frequency_type'])!,
      targetDaysPerWeek: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}target_days_per_week']),
      iconName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_name'])!,
      colorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_hex'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $HabitsTable createAlias(String alias) {
    return $HabitsTable(attachedDatabase, alias);
  }
}

class Habit extends DataClass implements Insertable<Habit> {
  final String id;
  final String name;
  final String frequencyType;
  final int? targetDaysPerWeek;
  final String iconName;
  final String colorHex;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const Habit(
      {required this.id,
      required this.name,
      required this.frequencyType,
      this.targetDaysPerWeek,
      required this.iconName,
      required this.colorHex,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['frequency_type'] = Variable<String>(frequencyType);
    if (!nullToAbsent || targetDaysPerWeek != null) {
      map['target_days_per_week'] = Variable<int>(targetDaysPerWeek);
    }
    map['icon_name'] = Variable<String>(iconName);
    map['color_hex'] = Variable<String>(colorHex);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  HabitsCompanion toCompanion(bool nullToAbsent) {
    return HabitsCompanion(
      id: Value(id),
      name: Value(name),
      frequencyType: Value(frequencyType),
      targetDaysPerWeek: targetDaysPerWeek == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDaysPerWeek),
      iconName: Value(iconName),
      colorHex: Value(colorHex),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Habit.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Habit(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      frequencyType: serializer.fromJson<String>(json['frequencyType']),
      targetDaysPerWeek: serializer.fromJson<int?>(json['targetDaysPerWeek']),
      iconName: serializer.fromJson<String>(json['iconName']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'frequencyType': serializer.toJson<String>(frequencyType),
      'targetDaysPerWeek': serializer.toJson<int?>(targetDaysPerWeek),
      'iconName': serializer.toJson<String>(iconName),
      'colorHex': serializer.toJson<String>(colorHex),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  Habit copyWith(
          {String? id,
          String? name,
          String? frequencyType,
          Value<int?> targetDaysPerWeek = const Value.absent(),
          String? iconName,
          String? colorHex,
          int? createdAt,
          int? updatedAt,
          Value<int?> deletedAt = const Value.absent()}) =>
      Habit(
        id: id ?? this.id,
        name: name ?? this.name,
        frequencyType: frequencyType ?? this.frequencyType,
        targetDaysPerWeek: targetDaysPerWeek.present
            ? targetDaysPerWeek.value
            : this.targetDaysPerWeek,
        iconName: iconName ?? this.iconName,
        colorHex: colorHex ?? this.colorHex,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Habit copyWithCompanion(HabitsCompanion data) {
    return Habit(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      frequencyType: data.frequencyType.present
          ? data.frequencyType.value
          : this.frequencyType,
      targetDaysPerWeek: data.targetDaysPerWeek.present
          ? data.targetDaysPerWeek.value
          : this.targetDaysPerWeek,
      iconName: data.iconName.present ? data.iconName.value : this.iconName,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Habit(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('frequencyType: $frequencyType, ')
          ..write('targetDaysPerWeek: $targetDaysPerWeek, ')
          ..write('iconName: $iconName, ')
          ..write('colorHex: $colorHex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, frequencyType, targetDaysPerWeek,
      iconName, colorHex, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Habit &&
          other.id == this.id &&
          other.name == this.name &&
          other.frequencyType == this.frequencyType &&
          other.targetDaysPerWeek == this.targetDaysPerWeek &&
          other.iconName == this.iconName &&
          other.colorHex == this.colorHex &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class HabitsCompanion extends UpdateCompanion<Habit> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> frequencyType;
  final Value<int?> targetDaysPerWeek;
  final Value<String> iconName;
  final Value<String> colorHex;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const HabitsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.frequencyType = const Value.absent(),
    this.targetDaysPerWeek = const Value.absent(),
    this.iconName = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitsCompanion.insert({
    required String id,
    required String name,
    required String frequencyType,
    this.targetDaysPerWeek = const Value.absent(),
    this.iconName = const Value.absent(),
    this.colorHex = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        frequencyType = Value(frequencyType),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Habit> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? frequencyType,
    Expression<int>? targetDaysPerWeek,
    Expression<String>? iconName,
    Expression<String>? colorHex,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (frequencyType != null) 'frequency_type': frequencyType,
      if (targetDaysPerWeek != null) 'target_days_per_week': targetDaysPerWeek,
      if (iconName != null) 'icon_name': iconName,
      if (colorHex != null) 'color_hex': colorHex,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? frequencyType,
      Value<int?>? targetDaysPerWeek,
      Value<String>? iconName,
      Value<String>? colorHex,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return HabitsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      frequencyType: frequencyType ?? this.frequencyType,
      targetDaysPerWeek: targetDaysPerWeek ?? this.targetDaysPerWeek,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (frequencyType.present) {
      map['frequency_type'] = Variable<String>(frequencyType.value);
    }
    if (targetDaysPerWeek.present) {
      map['target_days_per_week'] = Variable<int>(targetDaysPerWeek.value);
    }
    if (iconName.present) {
      map['icon_name'] = Variable<String>(iconName.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('frequencyType: $frequencyType, ')
          ..write('targetDaysPerWeek: $targetDaysPerWeek, ')
          ..write('iconName: $iconName, ')
          ..write('colorHex: $colorHex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HabitRecordsTable extends HabitRecords
    with TableInfo<$HabitRecordsTable, HabitRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _habitIdMeta =
      const VerificationMeta('habitId');
  @override
  late final GeneratedColumn<String> habitId = GeneratedColumn<String>(
      'habit_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recordDateMeta =
      const VerificationMeta('recordDate');
  @override
  late final GeneratedColumn<String> recordDate = GeneratedColumn<String>(
      'record_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, habitId, recordDate, createdAt, updatedAt, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_records';
  @override
  VerificationContext validateIntegrity(Insertable<HabitRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('habit_id')) {
      context.handle(_habitIdMeta,
          habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta));
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('record_date')) {
      context.handle(
          _recordDateMeta,
          recordDate.isAcceptableOrUnknown(
              data['record_date']!, _recordDateMeta));
    } else if (isInserting) {
      context.missing(_recordDateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {habitId, recordDate},
      ];
  @override
  HabitRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      habitId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}habit_id'])!,
      recordDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}record_date'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $HabitRecordsTable createAlias(String alias) {
    return $HabitRecordsTable(attachedDatabase, alias);
  }
}

class HabitRecord extends DataClass implements Insertable<HabitRecord> {
  final String id;
  final String habitId;
  final String recordDate;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const HabitRecord(
      {required this.id,
      required this.habitId,
      required this.recordDate,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['habit_id'] = Variable<String>(habitId);
    map['record_date'] = Variable<String>(recordDate);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  HabitRecordsCompanion toCompanion(bool nullToAbsent) {
    return HabitRecordsCompanion(
      id: Value(id),
      habitId: Value(habitId),
      recordDate: Value(recordDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory HabitRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitRecord(
      id: serializer.fromJson<String>(json['id']),
      habitId: serializer.fromJson<String>(json['habitId']),
      recordDate: serializer.fromJson<String>(json['recordDate']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'habitId': serializer.toJson<String>(habitId),
      'recordDate': serializer.toJson<String>(recordDate),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  HabitRecord copyWith(
          {String? id,
          String? habitId,
          String? recordDate,
          int? createdAt,
          int? updatedAt,
          Value<int?> deletedAt = const Value.absent()}) =>
      HabitRecord(
        id: id ?? this.id,
        habitId: habitId ?? this.habitId,
        recordDate: recordDate ?? this.recordDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  HabitRecord copyWithCompanion(HabitRecordsCompanion data) {
    return HabitRecord(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      recordDate:
          data.recordDate.present ? data.recordDate.value : this.recordDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitRecord(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('recordDate: $recordDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, habitId, recordDate, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitRecord &&
          other.id == this.id &&
          other.habitId == this.habitId &&
          other.recordDate == this.recordDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class HabitRecordsCompanion extends UpdateCompanion<HabitRecord> {
  final Value<String> id;
  final Value<String> habitId;
  final Value<String> recordDate;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const HabitRecordsCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.recordDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitRecordsCompanion.insert({
    required String id,
    required String habitId,
    required String recordDate,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        habitId = Value(habitId),
        recordDate = Value(recordDate),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<HabitRecord> custom({
    Expression<String>? id,
    Expression<String>? habitId,
    Expression<String>? recordDate,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (recordDate != null) 'record_date': recordDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitRecordsCompanion copyWith(
      {Value<String>? id,
      Value<String>? habitId,
      Value<String>? recordDate,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return HabitRecordsCompanion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      recordDate: recordDate ?? this.recordDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<String>(habitId.value);
    }
    if (recordDate.present) {
      map['record_date'] = Variable<String>(recordDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitRecordsCompanion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('recordDate: $recordDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncDevicesTable extends SyncDevices
    with TableInfo<$SyncDevicesTable, SyncDevice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncDevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deviceNameMeta =
      const VerificationMeta('deviceName');
  @override
  late final GeneratedColumn<String> deviceName = GeneratedColumn<String>(
      'device_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _platformMeta =
      const VerificationMeta('platform');
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
      'platform', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ipAddressMeta =
      const VerificationMeta('ipAddress');
  @override
  late final GeneratedColumn<String> ipAddress = GeneratedColumn<String>(
      'ip_address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _portMeta = const VerificationMeta('port');
  @override
  late final GeneratedColumn<int> port = GeneratedColumn<int>(
      'port', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(53317));
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<int> lastSyncedAt = GeneratedColumn<int>(
      'last_synced_at', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _pairingKeyHashMeta =
      const VerificationMeta('pairingKeyHash');
  @override
  late final GeneratedColumn<String> pairingKeyHash = GeneratedColumn<String>(
      'pairing_key_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isTrustedMeta =
      const VerificationMeta('isTrusted');
  @override
  late final GeneratedColumn<bool> isTrusted = GeneratedColumn<bool>(
      'is_trusted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_trusted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        deviceId,
        deviceName,
        platform,
        ipAddress,
        port,
        lastSyncedAt,
        pairingKeyHash,
        isTrusted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_devices';
  @override
  VerificationContext validateIntegrity(Insertable<SyncDevice> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('device_name')) {
      context.handle(
          _deviceNameMeta,
          deviceName.isAcceptableOrUnknown(
              data['device_name']!, _deviceNameMeta));
    } else if (isInserting) {
      context.missing(_deviceNameMeta);
    }
    if (data.containsKey('platform')) {
      context.handle(_platformMeta,
          platform.isAcceptableOrUnknown(data['platform']!, _platformMeta));
    } else if (isInserting) {
      context.missing(_platformMeta);
    }
    if (data.containsKey('ip_address')) {
      context.handle(_ipAddressMeta,
          ipAddress.isAcceptableOrUnknown(data['ip_address']!, _ipAddressMeta));
    } else if (isInserting) {
      context.missing(_ipAddressMeta);
    }
    if (data.containsKey('port')) {
      context.handle(
          _portMeta, port.isAcceptableOrUnknown(data['port']!, _portMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    }
    if (data.containsKey('pairing_key_hash')) {
      context.handle(
          _pairingKeyHashMeta,
          pairingKeyHash.isAcceptableOrUnknown(
              data['pairing_key_hash']!, _pairingKeyHashMeta));
    } else if (isInserting) {
      context.missing(_pairingKeyHashMeta);
    }
    if (data.containsKey('is_trusted')) {
      context.handle(_isTrustedMeta,
          isTrusted.isAcceptableOrUnknown(data['is_trusted']!, _isTrustedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  SyncDevice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncDevice(
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      deviceName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_name'])!,
      platform: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}platform'])!,
      ipAddress: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ip_address'])!,
      port: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}port'])!,
      lastSyncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_synced_at'])!,
      pairingKeyHash: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}pairing_key_hash'])!,
      isTrusted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_trusted'])!,
    );
  }

  @override
  $SyncDevicesTable createAlias(String alias) {
    return $SyncDevicesTable(attachedDatabase, alias);
  }
}

class SyncDevice extends DataClass implements Insertable<SyncDevice> {
  final String deviceId;
  final String deviceName;
  final String platform;
  final String ipAddress;
  final int port;
  final int lastSyncedAt;
  final String pairingKeyHash;
  final bool isTrusted;
  const SyncDevice(
      {required this.deviceId,
      required this.deviceName,
      required this.platform,
      required this.ipAddress,
      required this.port,
      required this.lastSyncedAt,
      required this.pairingKeyHash,
      required this.isTrusted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['device_name'] = Variable<String>(deviceName);
    map['platform'] = Variable<String>(platform);
    map['ip_address'] = Variable<String>(ipAddress);
    map['port'] = Variable<int>(port);
    map['last_synced_at'] = Variable<int>(lastSyncedAt);
    map['pairing_key_hash'] = Variable<String>(pairingKeyHash);
    map['is_trusted'] = Variable<bool>(isTrusted);
    return map;
  }

  SyncDevicesCompanion toCompanion(bool nullToAbsent) {
    return SyncDevicesCompanion(
      deviceId: Value(deviceId),
      deviceName: Value(deviceName),
      platform: Value(platform),
      ipAddress: Value(ipAddress),
      port: Value(port),
      lastSyncedAt: Value(lastSyncedAt),
      pairingKeyHash: Value(pairingKeyHash),
      isTrusted: Value(isTrusted),
    );
  }

  factory SyncDevice.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncDevice(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deviceName: serializer.fromJson<String>(json['deviceName']),
      platform: serializer.fromJson<String>(json['platform']),
      ipAddress: serializer.fromJson<String>(json['ipAddress']),
      port: serializer.fromJson<int>(json['port']),
      lastSyncedAt: serializer.fromJson<int>(json['lastSyncedAt']),
      pairingKeyHash: serializer.fromJson<String>(json['pairingKeyHash']),
      isTrusted: serializer.fromJson<bool>(json['isTrusted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'deviceName': serializer.toJson<String>(deviceName),
      'platform': serializer.toJson<String>(platform),
      'ipAddress': serializer.toJson<String>(ipAddress),
      'port': serializer.toJson<int>(port),
      'lastSyncedAt': serializer.toJson<int>(lastSyncedAt),
      'pairingKeyHash': serializer.toJson<String>(pairingKeyHash),
      'isTrusted': serializer.toJson<bool>(isTrusted),
    };
  }

  SyncDevice copyWith(
          {String? deviceId,
          String? deviceName,
          String? platform,
          String? ipAddress,
          int? port,
          int? lastSyncedAt,
          String? pairingKeyHash,
          bool? isTrusted}) =>
      SyncDevice(
        deviceId: deviceId ?? this.deviceId,
        deviceName: deviceName ?? this.deviceName,
        platform: platform ?? this.platform,
        ipAddress: ipAddress ?? this.ipAddress,
        port: port ?? this.port,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        pairingKeyHash: pairingKeyHash ?? this.pairingKeyHash,
        isTrusted: isTrusted ?? this.isTrusted,
      );
  SyncDevice copyWithCompanion(SyncDevicesCompanion data) {
    return SyncDevice(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deviceName:
          data.deviceName.present ? data.deviceName.value : this.deviceName,
      platform: data.platform.present ? data.platform.value : this.platform,
      ipAddress: data.ipAddress.present ? data.ipAddress.value : this.ipAddress,
      port: data.port.present ? data.port.value : this.port,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      pairingKeyHash: data.pairingKeyHash.present
          ? data.pairingKeyHash.value
          : this.pairingKeyHash,
      isTrusted: data.isTrusted.present ? data.isTrusted.value : this.isTrusted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncDevice(')
          ..write('deviceId: $deviceId, ')
          ..write('deviceName: $deviceName, ')
          ..write('platform: $platform, ')
          ..write('ipAddress: $ipAddress, ')
          ..write('port: $port, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('pairingKeyHash: $pairingKeyHash, ')
          ..write('isTrusted: $isTrusted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, deviceName, platform, ipAddress,
      port, lastSyncedAt, pairingKeyHash, isTrusted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncDevice &&
          other.deviceId == this.deviceId &&
          other.deviceName == this.deviceName &&
          other.platform == this.platform &&
          other.ipAddress == this.ipAddress &&
          other.port == this.port &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.pairingKeyHash == this.pairingKeyHash &&
          other.isTrusted == this.isTrusted);
}

class SyncDevicesCompanion extends UpdateCompanion<SyncDevice> {
  final Value<String> deviceId;
  final Value<String> deviceName;
  final Value<String> platform;
  final Value<String> ipAddress;
  final Value<int> port;
  final Value<int> lastSyncedAt;
  final Value<String> pairingKeyHash;
  final Value<bool> isTrusted;
  final Value<int> rowid;
  const SyncDevicesCompanion({
    this.deviceId = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.platform = const Value.absent(),
    this.ipAddress = const Value.absent(),
    this.port = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.pairingKeyHash = const Value.absent(),
    this.isTrusted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncDevicesCompanion.insert({
    required String deviceId,
    required String deviceName,
    required String platform,
    required String ipAddress,
    this.port = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    required String pairingKeyHash,
    this.isTrusted = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : deviceId = Value(deviceId),
        deviceName = Value(deviceName),
        platform = Value(platform),
        ipAddress = Value(ipAddress),
        pairingKeyHash = Value(pairingKeyHash);
  static Insertable<SyncDevice> custom({
    Expression<String>? deviceId,
    Expression<String>? deviceName,
    Expression<String>? platform,
    Expression<String>? ipAddress,
    Expression<int>? port,
    Expression<int>? lastSyncedAt,
    Expression<String>? pairingKeyHash,
    Expression<bool>? isTrusted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (deviceName != null) 'device_name': deviceName,
      if (platform != null) 'platform': platform,
      if (ipAddress != null) 'ip_address': ipAddress,
      if (port != null) 'port': port,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (pairingKeyHash != null) 'pairing_key_hash': pairingKeyHash,
      if (isTrusted != null) 'is_trusted': isTrusted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncDevicesCompanion copyWith(
      {Value<String>? deviceId,
      Value<String>? deviceName,
      Value<String>? platform,
      Value<String>? ipAddress,
      Value<int>? port,
      Value<int>? lastSyncedAt,
      Value<String>? pairingKeyHash,
      Value<bool>? isTrusted,
      Value<int>? rowid}) {
    return SyncDevicesCompanion(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      pairingKeyHash: pairingKeyHash ?? this.pairingKeyHash,
      isTrusted: isTrusted ?? this.isTrusted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deviceName.present) {
      map['device_name'] = Variable<String>(deviceName.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (ipAddress.present) {
      map['ip_address'] = Variable<String>(ipAddress.value);
    }
    if (port.present) {
      map['port'] = Variable<int>(port.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt.value);
    }
    if (pairingKeyHash.present) {
      map['pairing_key_hash'] = Variable<String>(pairingKeyHash.value);
    }
    if (isTrusted.present) {
      map['is_trusted'] = Variable<bool>(isTrusted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncDevicesCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('deviceName: $deviceName, ')
          ..write('platform: $platform, ')
          ..write('ipAddress: $ipAddress, ')
          ..write('port: $port, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('pairingKeyHash: $pairingKeyHash, ')
          ..write('isTrusted: $isTrusted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WidgetLayoutsTable extends WidgetLayouts
    with TableInfo<$WidgetLayoutsTable, WidgetLayout> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WidgetLayoutsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
      'page_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _wMeta = const VerificationMeta('w');
  @override
  late final GeneratedColumn<int> w = GeneratedColumn<int>(
      'w', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _hMeta = const VerificationMeta('h');
  @override
  late final GeneratedColumn<int> h = GeneratedColumn<int>(
      'h', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _configMeta = const VerificationMeta('config');
  @override
  late final GeneratedColumn<String> config = GeneratedColumn<String>(
      'config', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        pageId,
        kind,
        w,
        h,
        sortOrder,
        config,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'widget_layouts';
  @override
  VerificationContext validateIntegrity(Insertable<WidgetLayout> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('page_id')) {
      context.handle(_pageIdMeta,
          pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta));
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('w')) {
      context.handle(_wMeta, w.isAcceptableOrUnknown(data['w']!, _wMeta));
    } else if (isInserting) {
      context.missing(_wMeta);
    }
    if (data.containsKey('h')) {
      context.handle(_hMeta, h.isAcceptableOrUnknown(data['h']!, _hMeta));
    } else if (isInserting) {
      context.missing(_hMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('config')) {
      context.handle(_configMeta,
          config.isAcceptableOrUnknown(data['config']!, _configMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WidgetLayout map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WidgetLayout(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      pageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}page_id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      w: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}w'])!,
      h: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}h'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      config: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}config'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $WidgetLayoutsTable createAlias(String alias) {
    return $WidgetLayoutsTable(attachedDatabase, alias);
  }
}

class WidgetLayout extends DataClass implements Insertable<WidgetLayout> {
  final String id;
  final String pageId;
  final String kind;
  final int w;
  final int h;
  final int sortOrder;
  final String config;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const WidgetLayout(
      {required this.id,
      required this.pageId,
      required this.kind,
      required this.w,
      required this.h,
      required this.sortOrder,
      required this.config,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['page_id'] = Variable<String>(pageId);
    map['kind'] = Variable<String>(kind);
    map['w'] = Variable<int>(w);
    map['h'] = Variable<int>(h);
    map['sort_order'] = Variable<int>(sortOrder);
    map['config'] = Variable<String>(config);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  WidgetLayoutsCompanion toCompanion(bool nullToAbsent) {
    return WidgetLayoutsCompanion(
      id: Value(id),
      pageId: Value(pageId),
      kind: Value(kind),
      w: Value(w),
      h: Value(h),
      sortOrder: Value(sortOrder),
      config: Value(config),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory WidgetLayout.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WidgetLayout(
      id: serializer.fromJson<String>(json['id']),
      pageId: serializer.fromJson<String>(json['pageId']),
      kind: serializer.fromJson<String>(json['kind']),
      w: serializer.fromJson<int>(json['w']),
      h: serializer.fromJson<int>(json['h']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      config: serializer.fromJson<String>(json['config']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pageId': serializer.toJson<String>(pageId),
      'kind': serializer.toJson<String>(kind),
      'w': serializer.toJson<int>(w),
      'h': serializer.toJson<int>(h),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'config': serializer.toJson<String>(config),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  WidgetLayout copyWith(
          {String? id,
          String? pageId,
          String? kind,
          int? w,
          int? h,
          int? sortOrder,
          String? config,
          int? createdAt,
          int? updatedAt,
          Value<int?> deletedAt = const Value.absent()}) =>
      WidgetLayout(
        id: id ?? this.id,
        pageId: pageId ?? this.pageId,
        kind: kind ?? this.kind,
        w: w ?? this.w,
        h: h ?? this.h,
        sortOrder: sortOrder ?? this.sortOrder,
        config: config ?? this.config,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  WidgetLayout copyWithCompanion(WidgetLayoutsCompanion data) {
    return WidgetLayout(
      id: data.id.present ? data.id.value : this.id,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      kind: data.kind.present ? data.kind.value : this.kind,
      w: data.w.present ? data.w.value : this.w,
      h: data.h.present ? data.h.value : this.h,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      config: data.config.present ? data.config.value : this.config,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WidgetLayout(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('kind: $kind, ')
          ..write('w: $w, ')
          ..write('h: $h, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('config: $config, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, pageId, kind, w, h, sortOrder, config,
      createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WidgetLayout &&
          other.id == this.id &&
          other.pageId == this.pageId &&
          other.kind == this.kind &&
          other.w == this.w &&
          other.h == this.h &&
          other.sortOrder == this.sortOrder &&
          other.config == this.config &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class WidgetLayoutsCompanion extends UpdateCompanion<WidgetLayout> {
  final Value<String> id;
  final Value<String> pageId;
  final Value<String> kind;
  final Value<int> w;
  final Value<int> h;
  final Value<int> sortOrder;
  final Value<String> config;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const WidgetLayoutsCompanion({
    this.id = const Value.absent(),
    this.pageId = const Value.absent(),
    this.kind = const Value.absent(),
    this.w = const Value.absent(),
    this.h = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.config = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WidgetLayoutsCompanion.insert({
    required String id,
    required String pageId,
    required String kind,
    required int w,
    required int h,
    this.sortOrder = const Value.absent(),
    this.config = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        pageId = Value(pageId),
        kind = Value(kind),
        w = Value(w),
        h = Value(h),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<WidgetLayout> custom({
    Expression<String>? id,
    Expression<String>? pageId,
    Expression<String>? kind,
    Expression<int>? w,
    Expression<int>? h,
    Expression<int>? sortOrder,
    Expression<String>? config,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pageId != null) 'page_id': pageId,
      if (kind != null) 'kind': kind,
      if (w != null) 'w': w,
      if (h != null) 'h': h,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (config != null) 'config': config,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WidgetLayoutsCompanion copyWith(
      {Value<String>? id,
      Value<String>? pageId,
      Value<String>? kind,
      Value<int>? w,
      Value<int>? h,
      Value<int>? sortOrder,
      Value<String>? config,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return WidgetLayoutsCompanion(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      kind: kind ?? this.kind,
      w: w ?? this.w,
      h: h ?? this.h,
      sortOrder: sortOrder ?? this.sortOrder,
      config: config ?? this.config,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (w.present) {
      map['w'] = Variable<int>(w.value);
    }
    if (h.present) {
      map['h'] = Variable<int>(h.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (config.present) {
      map['config'] = Variable<String>(config.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WidgetLayoutsCompanion(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('kind: $kind, ')
          ..write('w: $w, ')
          ..write('h: $h, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('config: $config, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TodosTable todos = $TodosTable(this);
  late final $SubtasksTable subtasks = $SubtasksTable(this);
  late final $SchedulesTable schedules = $SchedulesTable(this);
  late final $MemosTable memos = $MemosTable(this);
  late final $PomodoroLogsTable pomodoroLogs = $PomodoroLogsTable(this);
  late final $HabitsTable habits = $HabitsTable(this);
  late final $HabitRecordsTable habitRecords = $HabitRecordsTable(this);
  late final $SyncDevicesTable syncDevices = $SyncDevicesTable(this);
  late final $WidgetLayoutsTable widgetLayouts = $WidgetLayoutsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        todos,
        subtasks,
        schedules,
        memos,
        pomodoroLogs,
        habits,
        habitRecords,
        syncDevices,
        widgetLayouts
      ];
}

typedef $$TodosTableCreateCompanionBuilder = TodosCompanion Function({
  required String id,
  required String title,
  Value<String?> description,
  Value<int> priority,
  Value<String> status,
  Value<String?> dueDate,
  Value<String?> dueTime,
  Value<String?> categoryId,
  Value<bool> isTop,
  Value<int> estimatedPomodoros,
  Value<int> actualPomodoros,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$TodosTableUpdateCompanionBuilder = TodosCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String?> description,
  Value<int> priority,
  Value<String> status,
  Value<String?> dueDate,
  Value<String?> dueTime,
  Value<String?> categoryId,
  Value<bool> isTop,
  Value<int> estimatedPomodoros,
  Value<int> actualPomodoros,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});

class $$TodosTableFilterComposer extends Composer<_$AppDatabase, $TodosTable> {
  $$TodosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dueTime => $composableBuilder(
      column: $table.dueTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isTop => $composableBuilder(
      column: $table.isTop, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get estimatedPomodoros => $composableBuilder(
      column: $table.estimatedPomodoros,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get actualPomodoros => $composableBuilder(
      column: $table.actualPomodoros,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$TodosTableOrderingComposer
    extends Composer<_$AppDatabase, $TodosTable> {
  $$TodosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dueTime => $composableBuilder(
      column: $table.dueTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isTop => $composableBuilder(
      column: $table.isTop, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get estimatedPomodoros => $composableBuilder(
      column: $table.estimatedPomodoros,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get actualPomodoros => $composableBuilder(
      column: $table.actualPomodoros,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$TodosTableAnnotationComposer
    extends Composer<_$AppDatabase, $TodosTable> {
  $$TodosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get dueTime =>
      $composableBuilder(column: $table.dueTime, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<bool> get isTop =>
      $composableBuilder(column: $table.isTop, builder: (column) => column);

  GeneratedColumn<int> get estimatedPomodoros => $composableBuilder(
      column: $table.estimatedPomodoros, builder: (column) => column);

  GeneratedColumn<int> get actualPomodoros => $composableBuilder(
      column: $table.actualPomodoros, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$TodosTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TodosTable,
    Todo,
    $$TodosTableFilterComposer,
    $$TodosTableOrderingComposer,
    $$TodosTableAnnotationComposer,
    $$TodosTableCreateCompanionBuilder,
    $$TodosTableUpdateCompanionBuilder,
    (Todo, BaseReferences<_$AppDatabase, $TodosTable, Todo>),
    Todo,
    PrefetchHooks Function()> {
  $$TodosTableTableManager(_$AppDatabase db, $TodosTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TodosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TodosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TodosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> dueDate = const Value.absent(),
            Value<String?> dueTime = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<bool> isTop = const Value.absent(),
            Value<int> estimatedPomodoros = const Value.absent(),
            Value<int> actualPomodoros = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TodosCompanion(
            id: id,
            title: title,
            description: description,
            priority: priority,
            status: status,
            dueDate: dueDate,
            dueTime: dueTime,
            categoryId: categoryId,
            isTop: isTop,
            estimatedPomodoros: estimatedPomodoros,
            actualPomodoros: actualPomodoros,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String?> description = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> dueDate = const Value.absent(),
            Value<String?> dueTime = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<bool> isTop = const Value.absent(),
            Value<int> estimatedPomodoros = const Value.absent(),
            Value<int> actualPomodoros = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TodosCompanion.insert(
            id: id,
            title: title,
            description: description,
            priority: priority,
            status: status,
            dueDate: dueDate,
            dueTime: dueTime,
            categoryId: categoryId,
            isTop: isTop,
            estimatedPomodoros: estimatedPomodoros,
            actualPomodoros: actualPomodoros,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TodosTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TodosTable,
    Todo,
    $$TodosTableFilterComposer,
    $$TodosTableOrderingComposer,
    $$TodosTableAnnotationComposer,
    $$TodosTableCreateCompanionBuilder,
    $$TodosTableUpdateCompanionBuilder,
    (Todo, BaseReferences<_$AppDatabase, $TodosTable, Todo>),
    Todo,
    PrefetchHooks Function()>;
typedef $$SubtasksTableCreateCompanionBuilder = SubtasksCompanion Function({
  required String id,
  required String todoId,
  required String title,
  Value<bool> isCompleted,
  Value<int> sortOrder,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$SubtasksTableUpdateCompanionBuilder = SubtasksCompanion Function({
  Value<String> id,
  Value<String> todoId,
  Value<String> title,
  Value<bool> isCompleted,
  Value<int> sortOrder,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});

class $$SubtasksTableFilterComposer
    extends Composer<_$AppDatabase, $SubtasksTable> {
  $$SubtasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get todoId => $composableBuilder(
      column: $table.todoId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$SubtasksTableOrderingComposer
    extends Composer<_$AppDatabase, $SubtasksTable> {
  $$SubtasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get todoId => $composableBuilder(
      column: $table.todoId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$SubtasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubtasksTable> {
  $$SubtasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get todoId =>
      $composableBuilder(column: $table.todoId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$SubtasksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SubtasksTable,
    Subtask,
    $$SubtasksTableFilterComposer,
    $$SubtasksTableOrderingComposer,
    $$SubtasksTableAnnotationComposer,
    $$SubtasksTableCreateCompanionBuilder,
    $$SubtasksTableUpdateCompanionBuilder,
    (Subtask, BaseReferences<_$AppDatabase, $SubtasksTable, Subtask>),
    Subtask,
    PrefetchHooks Function()> {
  $$SubtasksTableTableManager(_$AppDatabase db, $SubtasksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubtasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubtasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubtasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> todoId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SubtasksCompanion(
            id: id,
            todoId: todoId,
            title: title,
            isCompleted: isCompleted,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String todoId,
            required String title,
            Value<bool> isCompleted = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SubtasksCompanion.insert(
            id: id,
            todoId: todoId,
            title: title,
            isCompleted: isCompleted,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SubtasksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SubtasksTable,
    Subtask,
    $$SubtasksTableFilterComposer,
    $$SubtasksTableOrderingComposer,
    $$SubtasksTableAnnotationComposer,
    $$SubtasksTableCreateCompanionBuilder,
    $$SubtasksTableUpdateCompanionBuilder,
    (Subtask, BaseReferences<_$AppDatabase, $SubtasksTable, Subtask>),
    Subtask,
    PrefetchHooks Function()>;
typedef $$SchedulesTableCreateCompanionBuilder = SchedulesCompanion Function({
  required String id,
  Value<String?> todoId,
  required String title,
  required int startTime,
  required int endTime,
  Value<bool> allDay,
  Value<String> colorHex,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$SchedulesTableUpdateCompanionBuilder = SchedulesCompanion Function({
  Value<String> id,
  Value<String?> todoId,
  Value<String> title,
  Value<int> startTime,
  Value<int> endTime,
  Value<bool> allDay,
  Value<String> colorHex,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});

class $$SchedulesTableFilterComposer
    extends Composer<_$AppDatabase, $SchedulesTable> {
  $$SchedulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get todoId => $composableBuilder(
      column: $table.todoId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get allDay => $composableBuilder(
      column: $table.allDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$SchedulesTableOrderingComposer
    extends Composer<_$AppDatabase, $SchedulesTable> {
  $$SchedulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get todoId => $composableBuilder(
      column: $table.todoId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get allDay => $composableBuilder(
      column: $table.allDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$SchedulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SchedulesTable> {
  $$SchedulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get todoId =>
      $composableBuilder(column: $table.todoId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<int> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<bool> get allDay =>
      $composableBuilder(column: $table.allDay, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$SchedulesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SchedulesTable,
    Schedule,
    $$SchedulesTableFilterComposer,
    $$SchedulesTableOrderingComposer,
    $$SchedulesTableAnnotationComposer,
    $$SchedulesTableCreateCompanionBuilder,
    $$SchedulesTableUpdateCompanionBuilder,
    (Schedule, BaseReferences<_$AppDatabase, $SchedulesTable, Schedule>),
    Schedule,
    PrefetchHooks Function()> {
  $$SchedulesTableTableManager(_$AppDatabase db, $SchedulesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SchedulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SchedulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SchedulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> todoId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<int> startTime = const Value.absent(),
            Value<int> endTime = const Value.absent(),
            Value<bool> allDay = const Value.absent(),
            Value<String> colorHex = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SchedulesCompanion(
            id: id,
            todoId: todoId,
            title: title,
            startTime: startTime,
            endTime: endTime,
            allDay: allDay,
            colorHex: colorHex,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> todoId = const Value.absent(),
            required String title,
            required int startTime,
            required int endTime,
            Value<bool> allDay = const Value.absent(),
            Value<String> colorHex = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SchedulesCompanion.insert(
            id: id,
            todoId: todoId,
            title: title,
            startTime: startTime,
            endTime: endTime,
            allDay: allDay,
            colorHex: colorHex,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SchedulesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SchedulesTable,
    Schedule,
    $$SchedulesTableFilterComposer,
    $$SchedulesTableOrderingComposer,
    $$SchedulesTableAnnotationComposer,
    $$SchedulesTableCreateCompanionBuilder,
    $$SchedulesTableUpdateCompanionBuilder,
    (Schedule, BaseReferences<_$AppDatabase, $SchedulesTable, Schedule>),
    Schedule,
    PrefetchHooks Function()>;
typedef $$MemosTableCreateCompanionBuilder = MemosCompanion Function({
  required String id,
  required String content,
  Value<String> colorHex,
  Value<String?> tag,
  Value<bool> isPinned,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$MemosTableUpdateCompanionBuilder = MemosCompanion Function({
  Value<String> id,
  Value<String> content,
  Value<String> colorHex,
  Value<String?> tag,
  Value<bool> isPinned,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});

class $$MemosTableFilterComposer extends Composer<_$AppDatabase, $MemosTable> {
  $$MemosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tag => $composableBuilder(
      column: $table.tag, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPinned => $composableBuilder(
      column: $table.isPinned, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$MemosTableOrderingComposer
    extends Composer<_$AppDatabase, $MemosTable> {
  $$MemosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tag => $composableBuilder(
      column: $table.tag, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPinned => $composableBuilder(
      column: $table.isPinned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$MemosTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemosTable> {
  $$MemosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$MemosTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MemosTable,
    Memo,
    $$MemosTableFilterComposer,
    $$MemosTableOrderingComposer,
    $$MemosTableAnnotationComposer,
    $$MemosTableCreateCompanionBuilder,
    $$MemosTableUpdateCompanionBuilder,
    (Memo, BaseReferences<_$AppDatabase, $MemosTable, Memo>),
    Memo,
    PrefetchHooks Function()> {
  $$MemosTableTableManager(_$AppDatabase db, $MemosTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String> colorHex = const Value.absent(),
            Value<String?> tag = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MemosCompanion(
            id: id,
            content: content,
            colorHex: colorHex,
            tag: tag,
            isPinned: isPinned,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String content,
            Value<String> colorHex = const Value.absent(),
            Value<String?> tag = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MemosCompanion.insert(
            id: id,
            content: content,
            colorHex: colorHex,
            tag: tag,
            isPinned: isPinned,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MemosTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MemosTable,
    Memo,
    $$MemosTableFilterComposer,
    $$MemosTableOrderingComposer,
    $$MemosTableAnnotationComposer,
    $$MemosTableCreateCompanionBuilder,
    $$MemosTableUpdateCompanionBuilder,
    (Memo, BaseReferences<_$AppDatabase, $MemosTable, Memo>),
    Memo,
    PrefetchHooks Function()>;
typedef $$PomodoroLogsTableCreateCompanionBuilder = PomodoroLogsCompanion
    Function({
  required String id,
  Value<String?> todoId,
  required int durationMinutes,
  Value<String> mode,
  Value<int> cycleRound,
  required int startedAt,
  required int endedAt,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$PomodoroLogsTableUpdateCompanionBuilder = PomodoroLogsCompanion
    Function({
  Value<String> id,
  Value<String?> todoId,
  Value<int> durationMinutes,
  Value<String> mode,
  Value<int> cycleRound,
  Value<int> startedAt,
  Value<int> endedAt,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});

class $$PomodoroLogsTableFilterComposer
    extends Composer<_$AppDatabase, $PomodoroLogsTable> {
  $$PomodoroLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get todoId => $composableBuilder(
      column: $table.todoId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cycleRound => $composableBuilder(
      column: $table.cycleRound, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$PomodoroLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $PomodoroLogsTable> {
  $$PomodoroLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get todoId => $composableBuilder(
      column: $table.todoId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cycleRound => $composableBuilder(
      column: $table.cycleRound, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$PomodoroLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PomodoroLogsTable> {
  $$PomodoroLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get todoId =>
      $composableBuilder(column: $table.todoId, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<int> get cycleRound => $composableBuilder(
      column: $table.cycleRound, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$PomodoroLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PomodoroLogsTable,
    PomodoroLog,
    $$PomodoroLogsTableFilterComposer,
    $$PomodoroLogsTableOrderingComposer,
    $$PomodoroLogsTableAnnotationComposer,
    $$PomodoroLogsTableCreateCompanionBuilder,
    $$PomodoroLogsTableUpdateCompanionBuilder,
    (
      PomodoroLog,
      BaseReferences<_$AppDatabase, $PomodoroLogsTable, PomodoroLog>
    ),
    PomodoroLog,
    PrefetchHooks Function()> {
  $$PomodoroLogsTableTableManager(_$AppDatabase db, $PomodoroLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PomodoroLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PomodoroLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PomodoroLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> todoId = const Value.absent(),
            Value<int> durationMinutes = const Value.absent(),
            Value<String> mode = const Value.absent(),
            Value<int> cycleRound = const Value.absent(),
            Value<int> startedAt = const Value.absent(),
            Value<int> endedAt = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PomodoroLogsCompanion(
            id: id,
            todoId: todoId,
            durationMinutes: durationMinutes,
            mode: mode,
            cycleRound: cycleRound,
            startedAt: startedAt,
            endedAt: endedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> todoId = const Value.absent(),
            required int durationMinutes,
            Value<String> mode = const Value.absent(),
            Value<int> cycleRound = const Value.absent(),
            required int startedAt,
            required int endedAt,
            required int createdAt,
            required int updatedAt,
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PomodoroLogsCompanion.insert(
            id: id,
            todoId: todoId,
            durationMinutes: durationMinutes,
            mode: mode,
            cycleRound: cycleRound,
            startedAt: startedAt,
            endedAt: endedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PomodoroLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PomodoroLogsTable,
    PomodoroLog,
    $$PomodoroLogsTableFilterComposer,
    $$PomodoroLogsTableOrderingComposer,
    $$PomodoroLogsTableAnnotationComposer,
    $$PomodoroLogsTableCreateCompanionBuilder,
    $$PomodoroLogsTableUpdateCompanionBuilder,
    (
      PomodoroLog,
      BaseReferences<_$AppDatabase, $PomodoroLogsTable, PomodoroLog>
    ),
    PomodoroLog,
    PrefetchHooks Function()>;
typedef $$HabitsTableCreateCompanionBuilder = HabitsCompanion Function({
  required String id,
  required String name,
  required String frequencyType,
  Value<int?> targetDaysPerWeek,
  Value<String> iconName,
  Value<String> colorHex,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$HabitsTableUpdateCompanionBuilder = HabitsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> frequencyType,
  Value<int?> targetDaysPerWeek,
  Value<String> iconName,
  Value<String> colorHex,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});

class $$HabitsTableFilterComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get frequencyType => $composableBuilder(
      column: $table.frequencyType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetDaysPerWeek => $composableBuilder(
      column: $table.targetDaysPerWeek,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconName => $composableBuilder(
      column: $table.iconName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$HabitsTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get frequencyType => $composableBuilder(
      column: $table.frequencyType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetDaysPerWeek => $composableBuilder(
      column: $table.targetDaysPerWeek,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconName => $composableBuilder(
      column: $table.iconName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$HabitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get frequencyType => $composableBuilder(
      column: $table.frequencyType, builder: (column) => column);

  GeneratedColumn<int> get targetDaysPerWeek => $composableBuilder(
      column: $table.targetDaysPerWeek, builder: (column) => column);

  GeneratedColumn<String> get iconName =>
      $composableBuilder(column: $table.iconName, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$HabitsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HabitsTable,
    Habit,
    $$HabitsTableFilterComposer,
    $$HabitsTableOrderingComposer,
    $$HabitsTableAnnotationComposer,
    $$HabitsTableCreateCompanionBuilder,
    $$HabitsTableUpdateCompanionBuilder,
    (Habit, BaseReferences<_$AppDatabase, $HabitsTable, Habit>),
    Habit,
    PrefetchHooks Function()> {
  $$HabitsTableTableManager(_$AppDatabase db, $HabitsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> frequencyType = const Value.absent(),
            Value<int?> targetDaysPerWeek = const Value.absent(),
            Value<String> iconName = const Value.absent(),
            Value<String> colorHex = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HabitsCompanion(
            id: id,
            name: name,
            frequencyType: frequencyType,
            targetDaysPerWeek: targetDaysPerWeek,
            iconName: iconName,
            colorHex: colorHex,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String frequencyType,
            Value<int?> targetDaysPerWeek = const Value.absent(),
            Value<String> iconName = const Value.absent(),
            Value<String> colorHex = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HabitsCompanion.insert(
            id: id,
            name: name,
            frequencyType: frequencyType,
            targetDaysPerWeek: targetDaysPerWeek,
            iconName: iconName,
            colorHex: colorHex,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$HabitsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HabitsTable,
    Habit,
    $$HabitsTableFilterComposer,
    $$HabitsTableOrderingComposer,
    $$HabitsTableAnnotationComposer,
    $$HabitsTableCreateCompanionBuilder,
    $$HabitsTableUpdateCompanionBuilder,
    (Habit, BaseReferences<_$AppDatabase, $HabitsTable, Habit>),
    Habit,
    PrefetchHooks Function()>;
typedef $$HabitRecordsTableCreateCompanionBuilder = HabitRecordsCompanion
    Function({
  required String id,
  required String habitId,
  required String recordDate,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$HabitRecordsTableUpdateCompanionBuilder = HabitRecordsCompanion
    Function({
  Value<String> id,
  Value<String> habitId,
  Value<String> recordDate,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});

class $$HabitRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $HabitRecordsTable> {
  $$HabitRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get habitId => $composableBuilder(
      column: $table.habitId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recordDate => $composableBuilder(
      column: $table.recordDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$HabitRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitRecordsTable> {
  $$HabitRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get habitId => $composableBuilder(
      column: $table.habitId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recordDate => $composableBuilder(
      column: $table.recordDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$HabitRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitRecordsTable> {
  $$HabitRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get habitId =>
      $composableBuilder(column: $table.habitId, builder: (column) => column);

  GeneratedColumn<String> get recordDate => $composableBuilder(
      column: $table.recordDate, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$HabitRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HabitRecordsTable,
    HabitRecord,
    $$HabitRecordsTableFilterComposer,
    $$HabitRecordsTableOrderingComposer,
    $$HabitRecordsTableAnnotationComposer,
    $$HabitRecordsTableCreateCompanionBuilder,
    $$HabitRecordsTableUpdateCompanionBuilder,
    (
      HabitRecord,
      BaseReferences<_$AppDatabase, $HabitRecordsTable, HabitRecord>
    ),
    HabitRecord,
    PrefetchHooks Function()> {
  $$HabitRecordsTableTableManager(_$AppDatabase db, $HabitRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> habitId = const Value.absent(),
            Value<String> recordDate = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HabitRecordsCompanion(
            id: id,
            habitId: habitId,
            recordDate: recordDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String habitId,
            required String recordDate,
            required int createdAt,
            required int updatedAt,
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HabitRecordsCompanion.insert(
            id: id,
            habitId: habitId,
            recordDate: recordDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$HabitRecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HabitRecordsTable,
    HabitRecord,
    $$HabitRecordsTableFilterComposer,
    $$HabitRecordsTableOrderingComposer,
    $$HabitRecordsTableAnnotationComposer,
    $$HabitRecordsTableCreateCompanionBuilder,
    $$HabitRecordsTableUpdateCompanionBuilder,
    (
      HabitRecord,
      BaseReferences<_$AppDatabase, $HabitRecordsTable, HabitRecord>
    ),
    HabitRecord,
    PrefetchHooks Function()>;
typedef $$SyncDevicesTableCreateCompanionBuilder = SyncDevicesCompanion
    Function({
  required String deviceId,
  required String deviceName,
  required String platform,
  required String ipAddress,
  Value<int> port,
  Value<int> lastSyncedAt,
  required String pairingKeyHash,
  Value<bool> isTrusted,
  Value<int> rowid,
});
typedef $$SyncDevicesTableUpdateCompanionBuilder = SyncDevicesCompanion
    Function({
  Value<String> deviceId,
  Value<String> deviceName,
  Value<String> platform,
  Value<String> ipAddress,
  Value<int> port,
  Value<int> lastSyncedAt,
  Value<String> pairingKeyHash,
  Value<bool> isTrusted,
  Value<int> rowid,
});

class $$SyncDevicesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncDevicesTable> {
  $$SyncDevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceName => $composableBuilder(
      column: $table.deviceName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get platform => $composableBuilder(
      column: $table.platform, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ipAddress => $composableBuilder(
      column: $table.ipAddress, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get port => $composableBuilder(
      column: $table.port, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pairingKeyHash => $composableBuilder(
      column: $table.pairingKeyHash,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isTrusted => $composableBuilder(
      column: $table.isTrusted, builder: (column) => ColumnFilters(column));
}

class $$SyncDevicesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncDevicesTable> {
  $$SyncDevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceName => $composableBuilder(
      column: $table.deviceName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get platform => $composableBuilder(
      column: $table.platform, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ipAddress => $composableBuilder(
      column: $table.ipAddress, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get port => $composableBuilder(
      column: $table.port, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pairingKeyHash => $composableBuilder(
      column: $table.pairingKeyHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isTrusted => $composableBuilder(
      column: $table.isTrusted, builder: (column) => ColumnOrderings(column));
}

class $$SyncDevicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncDevicesTable> {
  $$SyncDevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get deviceName => $composableBuilder(
      column: $table.deviceName, builder: (column) => column);

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get ipAddress =>
      $composableBuilder(column: $table.ipAddress, builder: (column) => column);

  GeneratedColumn<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => column);

  GeneratedColumn<int> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => column);

  GeneratedColumn<String> get pairingKeyHash => $composableBuilder(
      column: $table.pairingKeyHash, builder: (column) => column);

  GeneratedColumn<bool> get isTrusted =>
      $composableBuilder(column: $table.isTrusted, builder: (column) => column);
}

class $$SyncDevicesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncDevicesTable,
    SyncDevice,
    $$SyncDevicesTableFilterComposer,
    $$SyncDevicesTableOrderingComposer,
    $$SyncDevicesTableAnnotationComposer,
    $$SyncDevicesTableCreateCompanionBuilder,
    $$SyncDevicesTableUpdateCompanionBuilder,
    (SyncDevice, BaseReferences<_$AppDatabase, $SyncDevicesTable, SyncDevice>),
    SyncDevice,
    PrefetchHooks Function()> {
  $$SyncDevicesTableTableManager(_$AppDatabase db, $SyncDevicesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncDevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncDevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncDevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> deviceId = const Value.absent(),
            Value<String> deviceName = const Value.absent(),
            Value<String> platform = const Value.absent(),
            Value<String> ipAddress = const Value.absent(),
            Value<int> port = const Value.absent(),
            Value<int> lastSyncedAt = const Value.absent(),
            Value<String> pairingKeyHash = const Value.absent(),
            Value<bool> isTrusted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncDevicesCompanion(
            deviceId: deviceId,
            deviceName: deviceName,
            platform: platform,
            ipAddress: ipAddress,
            port: port,
            lastSyncedAt: lastSyncedAt,
            pairingKeyHash: pairingKeyHash,
            isTrusted: isTrusted,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String deviceId,
            required String deviceName,
            required String platform,
            required String ipAddress,
            Value<int> port = const Value.absent(),
            Value<int> lastSyncedAt = const Value.absent(),
            required String pairingKeyHash,
            Value<bool> isTrusted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncDevicesCompanion.insert(
            deviceId: deviceId,
            deviceName: deviceName,
            platform: platform,
            ipAddress: ipAddress,
            port: port,
            lastSyncedAt: lastSyncedAt,
            pairingKeyHash: pairingKeyHash,
            isTrusted: isTrusted,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncDevicesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncDevicesTable,
    SyncDevice,
    $$SyncDevicesTableFilterComposer,
    $$SyncDevicesTableOrderingComposer,
    $$SyncDevicesTableAnnotationComposer,
    $$SyncDevicesTableCreateCompanionBuilder,
    $$SyncDevicesTableUpdateCompanionBuilder,
    (SyncDevice, BaseReferences<_$AppDatabase, $SyncDevicesTable, SyncDevice>),
    SyncDevice,
    PrefetchHooks Function()>;
typedef $$WidgetLayoutsTableCreateCompanionBuilder = WidgetLayoutsCompanion
    Function({
  required String id,
  required String pageId,
  required String kind,
  required int w,
  required int h,
  Value<int> sortOrder,
  Value<String> config,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$WidgetLayoutsTableUpdateCompanionBuilder = WidgetLayoutsCompanion
    Function({
  Value<String> id,
  Value<String> pageId,
  Value<String> kind,
  Value<int> w,
  Value<int> h,
  Value<int> sortOrder,
  Value<String> config,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});

class $$WidgetLayoutsTableFilterComposer
    extends Composer<_$AppDatabase, $WidgetLayoutsTable> {
  $$WidgetLayoutsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pageId => $composableBuilder(
      column: $table.pageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get w => $composableBuilder(
      column: $table.w, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get h => $composableBuilder(
      column: $table.h, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get config => $composableBuilder(
      column: $table.config, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$WidgetLayoutsTableOrderingComposer
    extends Composer<_$AppDatabase, $WidgetLayoutsTable> {
  $$WidgetLayoutsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pageId => $composableBuilder(
      column: $table.pageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get w => $composableBuilder(
      column: $table.w, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get h => $composableBuilder(
      column: $table.h, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get config => $composableBuilder(
      column: $table.config, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$WidgetLayoutsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WidgetLayoutsTable> {
  $$WidgetLayoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pageId =>
      $composableBuilder(column: $table.pageId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get w =>
      $composableBuilder(column: $table.w, builder: (column) => column);

  GeneratedColumn<int> get h =>
      $composableBuilder(column: $table.h, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get config =>
      $composableBuilder(column: $table.config, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$WidgetLayoutsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WidgetLayoutsTable,
    WidgetLayout,
    $$WidgetLayoutsTableFilterComposer,
    $$WidgetLayoutsTableOrderingComposer,
    $$WidgetLayoutsTableAnnotationComposer,
    $$WidgetLayoutsTableCreateCompanionBuilder,
    $$WidgetLayoutsTableUpdateCompanionBuilder,
    (
      WidgetLayout,
      BaseReferences<_$AppDatabase, $WidgetLayoutsTable, WidgetLayout>
    ),
    WidgetLayout,
    PrefetchHooks Function()> {
  $$WidgetLayoutsTableTableManager(_$AppDatabase db, $WidgetLayoutsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WidgetLayoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WidgetLayoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WidgetLayoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> pageId = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<int> w = const Value.absent(),
            Value<int> h = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<String> config = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WidgetLayoutsCompanion(
            id: id,
            pageId: pageId,
            kind: kind,
            w: w,
            h: h,
            sortOrder: sortOrder,
            config: config,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String pageId,
            required String kind,
            required int w,
            required int h,
            Value<int> sortOrder = const Value.absent(),
            Value<String> config = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WidgetLayoutsCompanion.insert(
            id: id,
            pageId: pageId,
            kind: kind,
            w: w,
            h: h,
            sortOrder: sortOrder,
            config: config,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WidgetLayoutsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WidgetLayoutsTable,
    WidgetLayout,
    $$WidgetLayoutsTableFilterComposer,
    $$WidgetLayoutsTableOrderingComposer,
    $$WidgetLayoutsTableAnnotationComposer,
    $$WidgetLayoutsTableCreateCompanionBuilder,
    $$WidgetLayoutsTableUpdateCompanionBuilder,
    (
      WidgetLayout,
      BaseReferences<_$AppDatabase, $WidgetLayoutsTable, WidgetLayout>
    ),
    WidgetLayout,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TodosTableTableManager get todos =>
      $$TodosTableTableManager(_db, _db.todos);
  $$SubtasksTableTableManager get subtasks =>
      $$SubtasksTableTableManager(_db, _db.subtasks);
  $$SchedulesTableTableManager get schedules =>
      $$SchedulesTableTableManager(_db, _db.schedules);
  $$MemosTableTableManager get memos =>
      $$MemosTableTableManager(_db, _db.memos);
  $$PomodoroLogsTableTableManager get pomodoroLogs =>
      $$PomodoroLogsTableTableManager(_db, _db.pomodoroLogs);
  $$HabitsTableTableManager get habits =>
      $$HabitsTableTableManager(_db, _db.habits);
  $$HabitRecordsTableTableManager get habitRecords =>
      $$HabitRecordsTableTableManager(_db, _db.habitRecords);
  $$SyncDevicesTableTableManager get syncDevices =>
      $$SyncDevicesTableTableManager(_db, _db.syncDevices);
  $$WidgetLayoutsTableTableManager get widgetLayouts =>
      $$WidgetLayoutsTableTableManager(_db, _db.widgetLayouts);
}
