export 'package:dailydesk/widgets_infra/widget_context.dart';

import 'package:dailydesk/widgets_infra/widget_context.dart';
import 'package:flutter/material.dart';

class WidgetInstance {
  WidgetInstance({
    required this.id,
    required this.kind,
    required this.w,
    required this.h,
    Map<String, dynamic>? config,
  }) : config = config ?? {};

  final String id;
  final String kind;
  int w;
  int h;
  Map<String, dynamic> config;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'w': w,
        'h': h,
        'config': config,
      };
}

abstract class DailyWidgetDefinition<C> {
  String get kind;
  String get name;
  IconData get icon;
  ({int w, int h}) get defaultSize;
  C defaultConfig();
  C normalizeConfig(Map<String, dynamic> raw);
  Widget render(BuildContext context, WidgetContext<C> ctx);
  Widget renderSettings(BuildContext context, WidgetSettingsContext<C> ctx);
  bool get liveRefresh => true;
}
