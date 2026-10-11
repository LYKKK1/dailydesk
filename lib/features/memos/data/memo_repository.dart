import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/utils/ulid.dart';
import 'package:drift/drift.dart';

class MemoRepository {
  MemoRepository(this._db);

  final AppDatabase _db;

  Stream<List<Memo>> watchMemos({String? tag}) => (_db.select(_db.memos)
        ..where(
          (m) =>
              m.deletedAt.isNull() &
              (tag == null ? const Constant(true) : m.tag.equals(tag)),
        )
        ..orderBy([
          (m) => OrderingTerm(
                expression: m.isPinned,
                mode: OrderingMode.desc,
              ),
          (m) => OrderingTerm(
                expression: m.createdAt,
                mode: OrderingMode.desc,
              ),
        ]))
      .watch();

  Future<void> insertMemo({
    required String content,
    String? tag,
    String colorHex = '#F9F9FB',
    bool isPinned = false,
  }) =>
      _db.into(_db.memos).insert(
            MemosCompanion.insert(
              id: newUlid(),
              content: content,
              tag: Value(tag),
              colorHex: Value(colorHex),
              isPinned: Value(isPinned),
              createdAt: nowMs(),
              updatedAt: nowMs(),
            ),
          );

  /// Converts a memo in one transaction and archives the original memo.
  Future<String> convertToTodo(String memoId) async {
    final memo = await (_db.select(_db.memos)
          ..where((m) => m.id.equals(memoId)))
        .getSingle();
    final lines = memo.content.split('\n');
    final title = lines.first.trim();
    final description = lines.skip(1).join('\n').trim();

    return _db.transaction(() async {
      final todoId = newUlid();
      await _db.into(_db.todos).insert(
            TodosCompanion.insert(
              id: todoId,
              title: title,
              description: Value(description.isEmpty ? null : description),
              createdAt: nowMs(),
              updatedAt: nowMs(),
            ),
          );
      await (_db.update(_db.memos)..where((m) => m.id.equals(memoId))).write(
        MemosCompanion(
          deletedAt: Value(nowMs()),
          updatedAt: Value(nowMs()),
        ),
      );
      return todoId;
    });
  }
}
