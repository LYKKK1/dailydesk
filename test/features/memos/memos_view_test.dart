import 'package:dailydesk/features/memos/data/memo_repository.dart';
import 'package:dailydesk/features/memos/presentation/memos_view.dart';
import 'package:dailydesk/features/memos/presentation/widgets/contribution_dots.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../test_database.dart';

void main() {
  test('last30DaysCounts returns 30 ordered values and fills missing days', () {
    final today = DateTime(2025, 10, 10, 18, 30);
    final counts = last30DaysCounts(
      {
        '2025-10-09': ['a', 'b']
      },
      today: today,
    );

    expect(counts, hasLength(30));
    expect(counts[28], 2);
    expect(counts.last, 0);
    expect(counts.every((count) => count >= 0), isTrue);
  });

  testWidgets('Ctrl+Enter publishes a memo and tag chips filter the feed',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = createTestDatabase();
    addTearDown(db.close);
    final repository = MemoRepository(db);
    await repository.insertMemo(content: '已有架构笔记', tag: '架构');

    await tester.pumpWidget(
      MaterialApp(home: MemosView(repository: repository)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('已有架构笔记'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('memo-filter-工作')));
    await tester.tap(find.byKey(const ValueKey('memo-composer-tag-工作')));
    await tester.enterText(
      find.byKey(const Key('memo-composer')),
      '新的工作灵感',
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('新的工作灵感'), findsOneWidget);
    expect(find.text('已有架构笔记'), findsNothing);

    final stored = await db.select(db.memos).get();
    expect(
      stored.map((memo) => memo.content),
      contains('新的工作灵感'),
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
