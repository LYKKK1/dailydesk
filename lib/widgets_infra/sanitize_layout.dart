import 'dart:convert';

import 'package:dailydesk/core/utils/sanitize.dart';
import 'package:dailydesk/core/utils/ulid.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';

class LayoutPage {
  LayoutPage({
    required this.id,
    required this.name,
    required this.widgets,
  });

  final String id;
  final String name;
  final List<WidgetInstance> widgets;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'widgets': widgets.map((widget) => widget.toJson()).toList(),
      };
}

class SanitizedLayout {
  SanitizedLayout(this.pages, this.activePageId);

  final List<LayoutPage> pages;
  final String activePageId;
}

/// The single entry gate for layout JSON before it reaches in-memory state.
SanitizedLayout sanitizeLayout(dynamic raw) {
  List<dynamic> rawPages;
  String? rawActivePageId;

  if (raw is List) {
    rawPages = raw;
  } else if (raw is Map && raw['pages'] is List) {
    rawPages = raw['pages'] as List;
    rawActivePageId =
        raw['activePageId'] is String ? raw['activePageId'] as String : null;
  } else if (raw is Map) {
    rawPages = [raw];
  } else {
    rawPages = const [];
  }

  final pages = <LayoutPage>[];
  for (final rawPage in rawPages) {
    final page = _sanitizePage(rawPage);
    if (page != null) pages.add(page);
  }

  if (pages.isEmpty) {
    pages.add(
      LayoutPage(id: newUlid(), name: '默认工作台', widgets: []),
    );
  }

  final activePageId =
      rawActivePageId != null && pages.any((page) => page.id == rawActivePageId)
          ? rawActivePageId
          : pages.first.id;

  return SanitizedLayout(pages, activePageId);
}

LayoutPage? _sanitizePage(dynamic raw) {
  if (raw is! Map) return null;

  final rawId = raw['id'];
  final id = rawId is String && rawId.trim().isNotEmpty ? rawId : newUlid();
  final rawName = raw['name'];
  final name = rawName is String ? rawName.trim() : '';
  if (name.isEmpty) return null;

  final widgets = <WidgetInstance>[];
  final rawWidgets = raw['widgets'];
  if (rawWidgets is List) {
    for (final rawWidget in rawWidgets) {
      final widget = _sanitizeWidget(rawWidget);
      if (widget != null) widgets.add(widget);
    }
  }

  return LayoutPage(id: id, name: name, widgets: widgets);
}

WidgetInstance? _sanitizeWidget(dynamic raw) {
  if (raw is! Map) return null;

  final rawKind = raw['kind'];
  final kind = rawKind is String ? rawKind.trim() : '';
  if (kind.isEmpty) return null;

  var config = raw['config'];
  if (config is String) {
    try {
      config = jsonDecode(config);
    } catch (_) {
      config = null;
    }
  }

  Map<String, dynamic>? normalizedConfig;
  if (config is Map) {
    normalizedConfig = {
      for (final entry in config.entries)
        if (entry.key is String) entry.key as String: entry.value,
    };
  }

  final rawId = raw['id'];
  final id = rawId is String && rawId.trim().isNotEmpty ? rawId : newUlid();

  return WidgetInstance(
    id: id,
    kind: kind,
    w: clampInt(raw['w'], 1, 12, 4),
    h: clampInt(raw['h'], 1, 20, 3),
    config: normalizedConfig,
  );
}
