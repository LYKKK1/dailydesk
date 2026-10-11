import 'package:dailydesk/features/quick_capture/nlp_quick_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('spec 示例：明天下午3点跟进方案 !P0 #工作', () {
    final result = parseCapture('明天下午3点跟进方案 !P0 #工作');
    expect(result.title, '跟进方案');
    expect(result.priority, 0);
    expect(result.tag, '工作');
    expect(result.dueDate, isNotNull);
    expect(result.dueTime, '15:00');
  });

  test('明早10点 → 明日 10:00', () {
    final result = parseCapture('明早10点提交报告');
    expect(result.title, '提交报告');
    expect(result.dueTime, '10:00');
    expect(result.dueDate, isNotNull);
  });

  test('今天 17:00', () {
    final result = parseCapture('今天 17:00 站会');
    expect(result.title, '站会');
    expect(result.dueTime, '17:00');
  });

  test('无任何标记 → 纯标题进收集箱（dueDate 为空）', () {
    final result = parseCapture('读《原则》第3章');
    expect(result.title, '读《原则》第3章');
    expect(result.priority, isNull);
    expect(result.dueDate, isNull);
    expect(result.dueTime, isNull);
  });

  test('英文时间词兼容', () {
    final result = parseCapture('tomorrow 3pm sync !P1');
    expect(result.priority, 1);
    expect(result.dueTime, '15:00');
    expect(result.dueDate, isNotNull);
  });

  test('下周一 9:30', () {
    final result = parseCapture('下周一 9:30 周会');
    expect(result.dueTime, '09:30');
    final due = DateTime.parse(result.dueDate!);
    expect(due.weekday, DateTime.monday);
    expect(due.isAfter(DateTime.now()), isTrue);
  });
}
