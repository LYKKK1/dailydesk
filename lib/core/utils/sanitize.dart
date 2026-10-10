/// Clamps a numeric value to a range, rounds it, and falls back on bad input.
int clampInt(dynamic value, int min, int max, int fallback) {
  final number = value is num ? value : int.tryParse('$value');
  if (number == null) return fallback;
  return number.round().clamp(min, max).toInt();
}

/// Accepts a string or list, removes duplicates, and applies a count limit.
List<String> toStringList(dynamic value, {int max = 50}) {
  if (value is String) return [value];
  if (value is! List) return const [];
  return value.whereType<String>().take(max).toSet().toList();
}

/// Corrects raw fields using the type of each default value.
///
/// Null values keep the default, unknown fields are discarded, and failed
/// numeric parsing falls back to the default.
Map<String, dynamic> normalizeWith(
  Map<String, dynamic> defaults,
  Map<String, dynamic> raw,
) {
  final result = Map<String, dynamic>.of(defaults);

  for (final entry in defaults.entries) {
    final value = raw[entry.key];
    if (value == null) continue;

    final defaultValue = entry.value;
    if (defaultValue is int) {
      result[entry.key] = clampInt(value, -1 << 40, 1 << 40, defaultValue);
    } else if (defaultValue is double) {
      result[entry.key] = value is num
          ? value.toDouble()
          : double.tryParse('$value') ?? defaultValue;
    } else if (defaultValue is bool) {
      result[entry.key] = value is bool ? value : value == 'true';
    } else if (defaultValue is String) {
      result[entry.key] = '$value';
    } else if (defaultValue is List) {
      result[entry.key] = value is List ? value : defaultValue;
    } else {
      result[entry.key] = value;
    }
  }

  return result;
}
