import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/memos/data/memo_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../test_database.dart';

void main() {
  late AppDatabase db;
  late MemoRepository repo;

  setUp(() {
    db = createTestDatabase();
    repo = MemoRepository(db);
  });

  tearDown(() => db.close());

  test('便签转待办：首行标题 + 剩余描述 + 原便签归档', () async {
    await repo.insertMemo(content: '调研 Riverpod\n注意 autoDispose\n看官方示例');
    final memo = (await db.select(db.memos).get()).single;

    final todoId = await repo.convertToTodo(memo.id);

    final todo = await (db.select(db.todos)..where((t) => t.id.equals(todoId)))
        .getSingle();
    expect(todo.title, '调研 Riverpod');
    expect(todo.description, '注意 autoDispose\n看官方示例');

    final archived = await (db.select(db.memos)
          ..where((m) => m.id.equals(memo.id)))
        .getSingle();
    expect(archived.deletedAt, isNotNull);
  });

  test('tag 过滤 + 置顶优先排序', () async {
    await repo.insertMemo(content: '架构笔记', tag: '架构');
    await repo.insertMemo(content: '普通', tag: '闪念');
    await repo.insertMemo(content: '置顶闪念', tag: '闪念', isPinned: true);

    final filtered = await repo.watchMemos(tag: '闪念').first;

    expect(filtered.first.content, '置顶闪念');
    expect(filtered.length, 2);
  });
}
