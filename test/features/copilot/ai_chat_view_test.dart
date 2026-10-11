import 'package:dailydesk/features/copilot/presentation/ai_chat_view.dart';
import 'package:dailydesk/features/copilot/services/ai_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('默认不发起网络请求，点击后才调用注入的模型接口', (tester) async {
    var fetchCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiChatView(
            fetchModels: ({
              required String baseUrl,
              required String apiKey,
              String? proxy,
            }) async {
              fetchCalls++;
              return const ['test-model'];
            },
          ),
        ),
      ),
    );

    expect(fetchCalls, 0);
    expect(find.text('AI 智囊'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('ai-api-key')), 'secret');
    await tester.tap(find.text('获取模型列表'));
    await tester.pumpAndSettle();

    expect(fetchCalls, 1);
    expect(find.text('test-model'), findsWidgets);
  });

  testWidgets('拆解结果可勾选并经批量写入回调输出', (tester) async {
    Deconstruction? applied;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiChatView(
            deconstructIdea: ({
              required String idea,
              required String baseUrl,
              required String apiKey,
              required String model,
              String? proxy,
            }) async =>
                Deconstruction(
              '先完成发版',
              [
                DeconTodo('打包', 0, 2, '14:00'),
                DeconTodo('写日志', 1, 1, '16:00'),
              ],
              [DeconSop('拉伸', '16:30')],
              [DeconMemo('检查广播', 'arch')],
            ),
            onApply: (deconstruction) async {
              applied = deconstruction;
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('ai-api-key')), 'secret');
    await tester.enterText(find.byKey(const Key('ai-model')), 'test-model');
    await tester.enterText(find.byKey(const Key('ai-idea')), '明天发版');
    await tester.tap(find.text('开始拆解'));
    await tester.pumpAndSettle();

    expect(find.text('打包'), findsOneWidget);
    expect(find.text('拉伸'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('select-todo-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('select-todo-1')));
    await tester.ensureVisible(find.text('一键写入工作台'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('一键写入工作台'));
    await tester.pumpAndSettle();

    expect(applied, isNotNull);
    expect(applied!.todos.map((todo) => todo.title), ['打包']);
    expect(applied!.sops.single.title, '拉伸');
  });
}
