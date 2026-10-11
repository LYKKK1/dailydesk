class ParsedCapture {
  ParsedCapture({
    required this.title,
    this.priority,
    this.dueDate,
    this.dueTime,
    this.tag,
  });

  final String title;
  final int? priority;
  final String? dueDate;
  final String? dueTime;
  final String? tag;
}

String _ymd(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

int _hourForPeriod(int hour, String? period) {
  switch (period) {
    case '下午':
    case '傍晚':
    case '晚上':
    case '夜里':
    case '夜晚':
      return hour < 12 ? hour + 12 : hour;
    case '中午':
      return hour < 11 ? hour + 12 : hour;
    case '凌晨':
    case '早上':
    case '早晨':
    case '上午':
      return hour == 12 ? 0 : hour;
    default:
      return hour;
  }
}

/// Lightweight capture syntax:
/// `!P0..!P3`, `#tag`, and common Chinese/English date-time phrases.
ParsedCapture parseCapture(String raw) {
  var text = raw.trim();
  int? priority;
  String? tag;

  final priorityMatch =
      RegExp(r'!P([0-3])\b', caseSensitive: false).firstMatch(text);
  if (priorityMatch != null) {
    priority = int.parse(priorityMatch.group(1)!);
    text = text.replaceAll(
      RegExp(r'!P[0-3]\b', caseSensitive: false),
      '',
    );
  }

  final tagMatch = RegExp(r'#([^\s#，。！!]+)').firstMatch(text);
  if (tagMatch != null) {
    tag = tagMatch.group(1);
    text = text.replaceFirst(tagMatch.group(0)!, '');
  }

  final now = _dateOnly(DateTime.now());
  DateTime? dueDate;
  String? defaultPeriod;

  final nextWeekMatch = RegExp(r'下(?:周|星期)([一二三四五六日天])').firstMatch(text);
  if (nextWeekMatch != null) {
    const weekdays = {
      '一': DateTime.monday,
      '二': DateTime.tuesday,
      '三': DateTime.wednesday,
      '四': DateTime.thursday,
      '五': DateTime.friday,
      '六': DateTime.saturday,
      '日': DateTime.sunday,
      '天': DateTime.sunday,
    };
    final targetWeekday = weekdays[nextWeekMatch.group(1)!]!;
    var target = now.add(const Duration(days: 7));
    target = target.subtract(
      Duration(days: target.weekday - targetWeekday),
    );
    if (!target.isAfter(now)) {
      target = target.add(const Duration(days: 7));
    }
    dueDate = target;
    text = text.replaceFirst(nextWeekMatch.group(0)!, '');
  }

  if (dueDate == null) {
    final dayRules = <RegExp, int>{
      RegExp(r'今天|today', caseSensitive: false): 0,
      RegExp(r'明天|明日|tomorrow', caseSensitive: false): 1,
      RegExp(r'后天'): 2,
    };
    for (final rule in dayRules.entries) {
      final match = rule.key.firstMatch(text);
      if (match != null) {
        dueDate = now.add(Duration(days: rule.value));
        text = text.replaceFirst(match.group(0)!, '');
        break;
      }
    }
  }

  final morningMatch = RegExp(r'明早|明晨|明晚').firstMatch(text);
  if (morningMatch != null) {
    dueDate ??= now.add(const Duration(days: 1));
    if (morningMatch.group(0) == '明晚') {
      defaultPeriod = '晚上';
    }
    text = text.replaceFirst(morningMatch.group(0)!, '');
  }

  final chineseTime = RegExp(
    r'(凌晨|早上|早晨|上午|中午|下午|傍晚|晚上|夜里|夜晚)?\s*'
    r'(\d{1,2})\s*[点时](?:\s*(半|\d{1,2}分))?',
  ).firstMatch(text);
  final englishTime = RegExp(
    r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
    caseSensitive: false,
  ).firstMatch(text);
  final clockTime = RegExp(r'\b(\d{1,2}):(\d{2})\b').firstMatch(text);

  int? hour;
  int minute = 0;
  if (chineseTime != null) {
    hour = _hourForPeriod(
      int.parse(chineseTime.group(2)!),
      chineseTime.group(1) ?? defaultPeriod,
    );
    final minuteText = chineseTime.group(3);
    if (minuteText == '半') {
      minute = 30;
    } else if (minuteText != null && minuteText.endsWith('分')) {
      minute = int.parse(minuteText.substring(0, minuteText.length - 1));
    }
    text = text.replaceFirst(chineseTime.group(0)!, '');
  } else if (englishTime != null) {
    hour = int.parse(englishTime.group(1)!);
    minute =
        englishTime.group(2) == null ? 0 : int.parse(englishTime.group(2)!);
    hour = _hourForPeriod(
      hour,
      englishTime.group(3)!.toLowerCase() == 'pm' ? '下午' : '上午',
    );
    text = text.replaceFirst(englishTime.group(0)!, '');
  } else if (clockTime != null) {
    hour = int.parse(clockTime.group(1)!);
    minute = int.parse(clockTime.group(2)!);
    text = text.replaceFirst(clockTime.group(0)!, '');
  }

  String? dueTime;
  if (hour != null && hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
    dueTime = '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  final title = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return ParsedCapture(
    title: title,
    priority: priority,
    dueDate: dueDate == null ? null : _ymd(dueDate),
    dueTime: dueTime,
    tag: tag,
  );
}
