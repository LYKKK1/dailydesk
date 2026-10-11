import 'dart:convert';

import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/utils/ulid.dart';
import 'package:dailydesk/features/dashboard/dashboard_controller.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:dailydesk/widgets_infra/sanitize_layout.dart';
import 'package:drift/drift.dart';

/// Persists multi-page dashboard layouts inside the [WidgetLayouts] table
/// without requiring a schema change, keeping each widget row individually
/// addressable for LWW P2P sync.
class LayoutRepository {
  LayoutRepository(this._db, {int Function()? clock}) : _clock = clock ?? nowMs;

  static const _pageMetaKind = '__page_meta__';

  final AppDatabase _db;
  final int Function() _clock;

  int get _now => _clock();

  Future<SanitizedLayout?> loadLayout() async {
    final rows = await (_db.select(_db.widgetLayouts)
          ..where((row) => row.deletedAt.isNull())
          ..orderBy([
            (row) => OrderingTerm(expression: row.sortOrder),
            (row) => OrderingTerm(expression: row.createdAt),
          ]))
        .get();
    if (rows.isEmpty) {
      return null;
    }

    final pageNames = <String, String>{};
    final pageOrders = <String, int>{};
    final widgetsByPage = <String, List<WidgetInstance>>{};
    String? activePageId;

    for (final row in rows) {
      final config = _decodeConfig(row.config);
      if (row.kind == _pageMetaKind) {
        final rawName = config['name'];
        if (rawName is String && rawName.trim().isNotEmpty) {
          pageNames[row.pageId] = rawName.trim();
        }
        pageOrders[row.pageId] = row.sortOrder;
        if (config['isActive'] == true) {
          activePageId = row.pageId;
        }
        widgetsByPage.putIfAbsent(row.pageId, () => <WidgetInstance>[]);
        continue;
      }

      final rawPageName = config['__pageName'];
      if (rawPageName is String &&
          rawPageName.trim().isNotEmpty &&
          !pageNames.containsKey(row.pageId)) {
        pageNames[row.pageId] = rawPageName.trim();
      }
      pageOrders.putIfAbsent(
          row.pageId, () => config['__pageOrder'] as int? ?? 0);
      if (config['__isActivePage'] == true && activePageId == null) {
        activePageId = row.pageId;
      }

      final cleanConfig = Map<String, dynamic>.from(config)
        ..remove('__pageName')
        ..remove('__pageOrder')
        ..remove('__isActivePage');
      cleanConfig['sortOrder'] = row.sortOrder;

      widgetsByPage.putIfAbsent(row.pageId, () => <WidgetInstance>[]).add(
            WidgetInstance(
              id: row.id,
              kind: row.kind,
              w: row.w,
              h: row.h,
              config: cleanConfig,
            ),
          );
    }

    final pageIds = widgetsByPage.keys.toList()
      ..sort((left, right) {
        final leftOrder = pageOrders[left] ?? 0;
        final rightOrder = pageOrders[right] ?? 0;
        return leftOrder.compareTo(rightOrder);
      });

    final pages = <Map<String, dynamic>>[];
    for (var i = 0; i < pageIds.length; i++) {
      final pageId = pageIds[i];
      final widgets = widgetsByPage[pageId] ?? const <WidgetInstance>[];
      pages.add({
        'id': pageId,
        'name': pageNames[pageId] ?? '工作台 ${i + 1}',
        'widgets': widgets.map((w) => w.toJson()).toList(),
      });
    }

    return sanitizeLayout({
      'activePageId': activePageId,
      'pages': pages,
    });
  }

  Future<void> saveController(DashboardController controller) async {
    final timestamp = _now;
    final pages = controller.pages;
    final activePageId = controller.activePageId;

    await _db.transaction(() async {
      final existing = await _db.select(_db.widgetLayouts).get();
      final existingById = {for (final row in existing) row.id: row};
      final retainedIds = <String>{};

      for (var pageIndex = 0; pageIndex < pages.length; pageIndex++) {
        final page = pages[pageIndex];
        final metaId = 'page_meta_${page.id}';
        retainedIds.add(metaId);
        final prevMeta = existingById[metaId];
        final metaConfig = jsonEncode({
          'name': page.name,
          'isActive': page.id == activePageId,
        });
        await _db.into(_db.widgetLayouts).insertOnConflictUpdate(
              WidgetLayoutsCompanion.insert(
                id: metaId,
                pageId: page.id,
                kind: _pageMetaKind,
                w: 12,
                h: 1,
                sortOrder: Value(pageIndex),
                config: Value(metaConfig),
                createdAt: prevMeta?.createdAt ?? timestamp,
                updatedAt: timestamp,
                deletedAt: const Value(null),
              ),
            );

        for (var widgetIndex = 0;
            widgetIndex < page.widgets.length;
            widgetIndex++) {
          final widget = page.widgets[widgetIndex];
          retainedIds.add(widget.id);
          final prev = existingById[widget.id];
          final persistedConfig = {
            ...widget.config,
            'sortOrder': widgetIndex,
            '__pageName': page.name,
            '__pageOrder': pageIndex,
            '__isActivePage': page.id == activePageId,
          };
          await _db.into(_db.widgetLayouts).insertOnConflictUpdate(
                WidgetLayoutsCompanion.insert(
                  id: widget.id,
                  pageId: page.id,
                  kind: widget.kind,
                  w: widget.w.clamp(1, 12),
                  h: widget.h.clamp(1, 20),
                  sortOrder: Value(widgetIndex),
                  config: Value(jsonEncode(persistedConfig)),
                  createdAt: prev?.createdAt ?? timestamp,
                  updatedAt: timestamp,
                  deletedAt: const Value(null),
                ),
              );
        }
      }

      for (final row in existing) {
        if (!retainedIds.contains(row.id) && row.deletedAt == null) {
          await (_db.update(_db.widgetLayouts)
                ..where((item) => item.id.equals(row.id)))
              .write(
            WidgetLayoutsCompanion(
              deletedAt: Value(timestamp),
              updatedAt: Value(timestamp),
            ),
          );
        }
      }
    });
  }

  static Map<String, dynamic> _decodeConfig(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Ignore malformed JSON and fall back to empty map.
    }
    return <String, dynamic>{};
  }
}
