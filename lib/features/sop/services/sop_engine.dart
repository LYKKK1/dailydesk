class SopSlot {
  SopSlot({
    required this.title,
    required this.time,
    required this.checkpoints,
    this.done = false,
  });

  final String title;
  final String time;
  final List<String> checkpoints;
  bool done;

  Map<String, dynamic> toJson() => {
        'title': title,
        'time': time,
        'checkpoints': checkpoints,
        'done': done,
      };

  factory SopSlot.fromJson(Map<String, dynamic> json) => SopSlot(
        title: '${json['title'] ?? ''}',
        time: '${json['time'] ?? '00:00'}',
        checkpoints: (json['checkpoints'] as List? ?? const [])
            .whereType<String>()
            .toList(),
        done: json['done'] == true,
      );
}

class SopEngine {
  const SopEngine._();

  /// 进度三元组：完成数 / 总数 / 百分比。
  static (int, int, double) progress(List<SopSlot> slots) {
    if (slots.isEmpty) return (0, 0, 0);
    final done = slots.where((slot) => slot.done).length;
    return (done, slots.length, done / slots.length);
  }

  /// 当前活跃时间槽：最后一个 time <= now 的槽。
  static int activeSlotIndex(List<SopSlot> slots, DateTime now) {
    final current = now.hour * 60 + now.minute;
    var active = -1;
    for (var i = 0; i < slots.length; i++) {
      if (_minutes(slots[i].time) <= current) active = i;
    }
    return active;
  }

  /// 距下一节点倒计时；最后一节点之后返回到明日首节点。
  static Duration untilNext(List<SopSlot> slots, DateTime now) {
    if (slots.isEmpty) return Duration.zero;

    final current = now.hour * 60 + now.minute;
    final sortedMinutes = slots.map((slot) => _minutes(slot.time)).toList()
      ..sort();
    for (final next in sortedMinutes) {
      if (next > current) return Duration(minutes: next - current);
    }
    return Duration(minutes: 24 * 60 - current + sortedMinutes.first);
  }

  /// 一键次日循环与重置：状态清空，模板（含细项）保留。
  static List<SopSlot> dailyReset(List<SopSlot> template) => template
      .map(
        (slot) => SopSlot(
          title: slot.title,
          time: slot.time,
          checkpoints: List.of(slot.checkpoints),
          done: false,
        ),
      )
      .toList();

  /// 动态增补专属步骤：按时间序插入，并列节点排在已有节点后。
  static List<SopSlot> insertAdHoc(List<SopSlot> slots, SopSlot adHoc) {
    final merged = List<SopSlot>.of(slots);
    final adHocMinutes = _minutes(adHoc.time);
    var index = 0;
    while (
        index < merged.length && _minutes(merged[index].time) <= adHocMinutes) {
      index++;
    }
    merged.insert(index, adHoc);
    return merged;
  }

  static int _minutes(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid SOP time "$value"; expected HH:mm');
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      throw FormatException('Invalid SOP time "$value"; expected HH:mm');
    }
    return hour * 60 + minute;
  }
}
