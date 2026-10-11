import 'dart:convert';

import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/utils/ulid.dart';

/// Pure Dart iCalendar serialization for schedules.
class IcsExporter {
  const IcsExporter._();

  static String export(List<Schedule> schedules) {
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//DailyDesk//DailyDesk 0.1.0//EN',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
    ];

    for (final schedule in schedules) {
      final start = DateTime.fromMillisecondsSinceEpoch(schedule.startTime);
      var end = DateTime.fromMillisecondsSinceEpoch(schedule.endTime);
      if (!end.isAfter(start)) {
        end = start.add(
          schedule.allDay ? const Duration(days: 1) : const Duration(hours: 1),
        );
      }

      lines
        ..add('BEGIN:VEVENT')
        ..add('UID:${_escapeText(schedule.id)}@dailydesk.local')
        ..add('DTSTAMP:${_formatUtc(DateTime.now().toUtc())}');

      if (schedule.allDay) {
        lines
          ..add('DTSTART;VALUE=DATE:${_formatDate(start)}')
          ..add('DTEND;VALUE=DATE:${_formatDate(end)}');
      } else {
        lines
          ..add('DTSTART:${_formatLocalDateTime(start)}')
          ..add('DTEND:${_formatLocalDateTime(end)}');
      }

      lines
        ..add('SUMMARY:${_escapeText(schedule.title)}')
        ..add('LAST-MODIFIED:${_formatUtc(
          DateTime.fromMillisecondsSinceEpoch(
            schedule.updatedAt,
          ).toUtc(),
        )}');

      if (schedule.colorHex.isNotEmpty) {
        lines.add('X-DAILYDESK-COLOR:${_escapeText(schedule.colorHex)}');
      }

      lines.add('END:VEVENT');
    }

    lines.add('END:VCALENDAR');
    return '${lines.map(_foldLine).join('\r\n')}\r\n';
  }
}

/// Pure Dart parser for single-occurrence VEVENT blocks.
class IcsImporter {
  const IcsImporter._();

  static const String _defaultColor = '#4A90E2';

  static List<Schedule> parse(String ics) {
    final events = <Map<String, _IcsProperty>>[];
    Map<String, _IcsProperty>? current;

    for (final line in _unfoldLines(ics)) {
      final upper = line.toUpperCase();
      if (upper == 'BEGIN:VEVENT') {
        current = <String, _IcsProperty>{};
        continue;
      }
      if (upper == 'END:VEVENT') {
        if (current != null) {
          events.add(current);
        }
        current = null;
        continue;
      }
      if (current == null || line.isEmpty) {
        continue;
      }

      final property = _parseProperty(line);
      if (property != null) {
        current[property.name] = property;
      }
    }

    return events
        .map(_scheduleFromEvent)
        .whereType<Schedule>()
        .toList(growable: false);
  }

  static Schedule? _scheduleFromEvent(Map<String, _IcsProperty> event) {
    final status = event['STATUS']?.value.toUpperCase();
    if (status == 'CANCELLED') {
      return null;
    }

    final startProperty = event['DTSTART'];
    final start = _parseIcsDate(startProperty?.value);
    if (startProperty == null || start == null) {
      return null;
    }

    final allDay = startProperty.parameters['VALUE']?.toUpperCase() == 'DATE' ||
        _looksLikeDateOnly(startProperty.value);

    var end = _parseIcsDate(event['DTEND']?.value);
    end ??= _durationAfter(start, event['DURATION']?.value);
    end ??= start.add(
      allDay ? const Duration(days: 1) : const Duration(hours: 1),
    );
    if (!end.isAfter(start)) {
      end = start.add(
        allDay ? const Duration(days: 1) : const Duration(hours: 1),
      );
    }

    final now = nowMs();
    final created =
        _parseIcsDate(event['CREATED']?.value)?.millisecondsSinceEpoch ?? now;
    final updated =
        _parseIcsDate(event['LAST-MODIFIED']?.value)?.millisecondsSinceEpoch ??
            created;
    final color = event['X-DAILYDESK-COLOR']?.value;

    return Schedule(
      id: _eventId(event),
      todoId: null,
      title: _unescapeText(event['SUMMARY']?.value ?? 'Untitled'),
      startTime: start.millisecondsSinceEpoch,
      endTime: end.millisecondsSinceEpoch,
      allDay: allDay,
      colorHex: _validColor(color) ? color! : _defaultColor,
      createdAt: created,
      updatedAt: updated,
      deletedAt: null,
    );
  }

  static String _eventId(Map<String, _IcsProperty> event) {
    final uid = event['UID']?.value.trim();
    if (uid == null || uid.isEmpty) {
      return newUlid();
    }
    return uid.endsWith('@dailydesk.local')
        ? uid.substring(0, uid.length - '@dailydesk.local'.length)
        : uid;
  }

  static bool _validColor(String? value) =>
      value != null && RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value);

  static bool _looksLikeDateOnly(String value) =>
      RegExp(r'^\d{8}$').hasMatch(value.trim());

  static DateTime? _durationAfter(DateTime start, String? value) {
    if (value == null) {
      return null;
    }

    final match = RegExp(
      r'^([+-])?P(?:(\d+)W)?(?:(\d+)D)?'
      r'(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) {
      return null;
    }

    final sign = match.group(1) == '-' ? -1 : 1;
    final duration = Duration(
      days: (int.tryParse(match.group(2) ?? '') ?? 0) * 7 +
          (int.tryParse(match.group(3) ?? '') ?? 0),
      hours: int.tryParse(match.group(4) ?? '') ?? 0,
      minutes: int.tryParse(match.group(5) ?? '') ?? 0,
      seconds: int.tryParse(match.group(6) ?? '') ?? 0,
    );
    return start.add(sign < 0 ? -duration : duration);
  }

  static DateTime? _parseIcsDate(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return null;
    }

    var value = rawValue.trim().replaceAll(RegExp(r'[-:]'), '');
    final dateOnly = RegExp(r'^(\d{4})(\d{2})(\d{2})$').firstMatch(value);
    if (dateOnly != null) {
      return DateTime(
        int.parse(dateOnly.group(1)!),
        int.parse(dateOnly.group(2)!),
        int.parse(dateOnly.group(3)!),
      );
    }

    final match = RegExp(
      r'^(\d{4})(\d{2})(\d{2})T'
      r'(\d{2})(\d{2})(\d{2})(Z|[+-]\d{4})?$',
      caseSensitive: false,
    ).firstMatch(value);
    if (match == null) {
      return null;
    }

    final utc = DateTime.utc(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      int.parse(match.group(6)!),
    );
    final zone = match.group(7)?.toUpperCase();

    if (zone == 'Z') {
      return utc.toLocal();
    }
    if (zone != null && zone.isNotEmpty) {
      final zoneMatch = RegExp(r'^([+-])(\d{2})(\d{2})$').firstMatch(zone);
      if (zoneMatch == null) {
        return null;
      }
      final sign = zoneMatch.group(1) == '-' ? -1 : 1;
      final offset = Duration(
        hours: sign * int.parse(zoneMatch.group(2)!),
        minutes: sign * int.parse(zoneMatch.group(3)!),
      );
      return utc.subtract(offset).toLocal();
    }

    return DateTime(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
      utc.second,
    );
  }

  static _IcsProperty? _parseProperty(String line) {
    final separator = line.indexOf(':');
    if (separator <= 0) {
      return null;
    }

    final rawName = line.substring(0, separator);
    final value = line.substring(separator + 1);
    final nameParts = rawName.split(';');
    final parameters = <String, String>{};

    for (final part in nameParts.skip(1)) {
      final equals = part.indexOf('=');
      if (equals > 0) {
        parameters[part.substring(0, equals).toUpperCase()] =
            part.substring(equals + 1).replaceAll('"', '');
      }
    }

    return _IcsProperty(
      name: nameParts.first.toUpperCase(),
      parameters: parameters,
      value: value,
    );
  }

  static List<String> _unfoldLines(String ics) {
    final normalized = ics
        .replaceFirst('\uFEFF', '')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');
    final unfolded = <String>[];

    for (final line in normalized) {
      if ((line.startsWith(' ') || line.startsWith('\t')) &&
          unfolded.isNotEmpty) {
        unfolded[unfolded.length - 1] += line.substring(1);
      } else {
        unfolded.add(line);
      }
    }
    return unfolded;
  }

  static String _unescapeText(String value) =>
      value.replaceAllMapped(RegExp(r'\\([nN,;\\])'), (match) {
        switch (match.group(1)) {
          case 'n':
          case 'N':
            return '\n';
          case ',':
            return ',';
          case ';':
            return ';';
          case '\\':
            return '\\';
          default:
            return match.group(0)!;
        }
      });
}

class _IcsProperty {
  const _IcsProperty({
    required this.name,
    required this.parameters,
    required this.value,
  });

  final String name;
  final Map<String, String> parameters;
  final String value;
}

String _formatDate(DateTime date) => '${date.year.toString().padLeft(4, '0')}'
    '${date.month.toString().padLeft(2, '0')}'
    '${date.day.toString().padLeft(2, '0')}';

String _formatLocalDateTime(DateTime date) => '${_formatDate(date)}T'
    '${date.hour.toString().padLeft(2, '0')}'
    '${date.minute.toString().padLeft(2, '0')}'
    '${date.second.toString().padLeft(2, '0')}';

String _formatUtc(DateTime date) => '${_formatLocalDateTime(date)}Z';

String _escapeText(String value) => value
    .replaceAll('\\', '\\\\')
    .replaceAll('\r\n', '\n')
    .replaceAll('\r', '\n')
    .replaceAll('\n', '\\n')
    .replaceAll(';', '\\;')
    .replaceAll(',', '\\,');

String _foldLine(String line) {
  final chunks = <String>[];
  var current = '';
  var currentBytes = 0;

  for (final rune in line.runes) {
    final character = String.fromCharCode(rune);
    final characterBytes = utf8.encode(character).length;
    final limit = chunks.isEmpty ? 75 : 74;
    if (current.isNotEmpty && currentBytes + characterBytes > limit) {
      chunks.add(current);
      current = '';
      currentBytes = 0;
    }
    current += character;
    currentBytes += characterBytes;
  }

  if (current.isNotEmpty || chunks.isEmpty) {
    chunks.add(current);
  }
  return chunks.join('\r\n ');
}
