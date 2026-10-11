import 'dart:convert';

import 'package:dailydesk/core/utils/ulid.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:dailydesk/widgets_infra/sanitize_layout.dart';

String exportJson(List<LayoutPage> pages, String activePageId) {
  return const JsonEncoder.withIndent('  ').convert({
    'version': 1,
    'activePageId': activePageId,
    'pages': pages.map((page) => page.toJson()).toList(growable: false),
  });
}

List<LayoutPage> importPages(String raw, List<LayoutPage> existing) {
  dynamic decoded;
  try {
    decoded = jsonDecode(raw);
  } catch (_) {
    return const [];
  }

  final candidates = _pageCandidates(decoded);
  final imported = <LayoutPage>[];
  for (final candidate in candidates) {
    if (!_isPageCandidate(candidate)) continue;

    final sanitized = sanitizeLayout(candidate);
    if (sanitized.pages.isEmpty) continue;

    final page = sanitized.pages.first;
    imported.add(
      LayoutPage(
        id: newUlid(),
        name: page.name,
        widgets: page.widgets
            .map(
              (widget) => WidgetInstance(
                id: newUlid(),
                kind: widget.kind,
                w: widget.w,
                h: widget.h,
                config: _cloneMap(widget.config),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
  return imported;
}

LayoutPage copyPage(LayoutPage src) {
  return LayoutPage(
    id: newUlid(),
    name: '${src.name} 副本',
    widgets: src.widgets
        .map(
          (widget) => WidgetInstance(
            id: newUlid(),
            kind: widget.kind,
            w: widget.w,
            h: widget.h,
            config: _cloneMap(widget.config),
          ),
        )
        .toList(growable: false),
  );
}

List<dynamic> _pageCandidates(dynamic decoded) {
  if (decoded is List) return decoded;
  if (decoded is Map && decoded['pages'] is List) {
    return decoded['pages'] as List;
  }
  if (decoded is Map) return [decoded];
  return const [];
}

bool _isPageCandidate(dynamic raw) {
  if (raw is! Map) return false;
  final name = raw['name'];
  return name is String && name.trim().isNotEmpty;
}

Map<String, dynamic> _cloneMap(Map<String, dynamic> source) => {
      for (final entry in source.entries) entry.key: _cloneValue(entry.value),
    };

dynamic _cloneValue(dynamic value) {
  if (value is Map) {
    return {
      for (final entry in value.entries)
        if (entry.key is String) entry.key as String: _cloneValue(entry.value),
    };
  }
  if (value is List) {
    return value.map(_cloneValue).toList(growable: false);
  }
  return value;
}
