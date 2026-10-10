import 'package:dailydesk/core/utils/sanitize.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clampInt 范围钳制 + 解析失败回退', () {
    expect(clampInt('8', 3, 12, 4), 8);
    expect(clampInt(99, 3, 12, 4), 12);
    expect(clampInt('abc', 3, 12, 4), 4);
    expect(clampInt(null, 3, 12, 4), 4);
  });

  test('toStringList 双兼容 + 去重 + 上限', () {
    expect(toStringList('a'), ['a']);
    expect(toStringList(['a', 'a', 'b']), ['a', 'b']);
    expect(toStringList(List.generate(99, (index) => 'k$index')).length, 50);
    expect(toStringList(42), isEmpty);
  });

  test('normalizeWith 数字解析失败回退默认值，多余字段丢弃', () {
    final result = normalizeWith(
      {'limit': 3, 'tag': 'all'},
      {'limit': 'xx', 'extra': 1},
    );

    expect(result['limit'], 3);
    expect(result['tag'], 'all');
    expect(result.containsKey('extra'), isFalse);
  });
}
