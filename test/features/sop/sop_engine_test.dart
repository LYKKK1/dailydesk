import 'package:dailydesk/features/sop/services/sop_engine.dart';
import 'package:flutter_test/flutter_test.dart';

final slots = [
  SopSlot(
    title: '晨间唤醒',
    time: '08:30',
    checkpoints: ['温水500ml', '开窗', '看日历'],
    done: true,
  ),
  SopSlot(title: '深度工作 I', time: '09:30', checkpoints: [], done: true),
  SopSlot(title: '午休', time: '12:00', checkpoints: [], done: false),
  SopSlot(title: '晚间复盘', time: '21:00', checkpoints: [], done: false),
];

void main() {
  test('进度：2/4 完成 50%', () {
    final (done, total, pct) = SopEngine.progress(slots);

    expect(done, 2);
    expect(total, 4);
    expect(pct, 0.5);
    expect(SopEngine.progress(const []), (0, 0, 0.0));
  });

  test('10:30 时活跃槽是 09:30，距午休 90 分钟', () {
    final now = DateTime(2025, 10, 13, 10, 30);

    expect(SopEngine.activeSlotIndex(slots, now), 1);
    expect(SopEngine.untilNext(slots, now).inMinutes, 90);
  });

  test('首节点前没有活跃槽，剩余时间按下一节点计算', () {
    final now = DateTime(2025, 10, 13, 7, 30);

    expect(SopEngine.activeSlotIndex(slots, now), -1);
    expect(SopEngine.untilNext(slots, now).inMinutes, 60);
  });

  test('最后节点后倒计时回到明日首节点', () {
    final now = DateTime(2025, 10, 13, 23, 0);

    expect(SopEngine.untilNext(slots, now).inMinutes, 570);
  });

  test('空列表的 active 与倒计时安全返回', () {
    final now = DateTime(2025, 10, 13, 10, 30);

    expect(SopEngine.activeSlotIndex(const [], now), -1);
    expect(SopEngine.untilNext(const [], now), Duration.zero);
  });

  test('每日重置：done 全清，模板与细项保留且可独立修改', () {
    final reset = SopEngine.dailyReset(slots);

    expect(reset.every((s) => !s.done), isTrue);
    expect(reset.first.checkpoints, ['温水500ml', '开窗', '看日历']);

    reset.first.checkpoints.add('修改副本');
    expect(slots.first.checkpoints, isNot(contains('修改副本')));
  });

  test('临时节点按时间序插入，并列时间排在已有节点后', () {
    final adHoc = SopSlot(
      title: '团队跨组沟通',
      time: '16:00',
      checkpoints: [],
    );
    final merged = SopEngine.insertAdHoc(slots, adHoc);
    final tied = SopEngine.insertAdHoc(
      slots,
      SopSlot(title: '午间临时', time: '12:00', checkpoints: []),
    );

    expect(
      merged.map((s) => s.time).toList(),
      ['08:30', '09:30', '12:00', '16:00', '21:00'],
    );
    expect(tied.map((s) => s.title).toList()[3], '午间临时');
    expect(slots, hasLength(4), reason: '原列表不被原地修改');
  });
}
