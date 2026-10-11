import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dart-side bridge for the Android foreground Pomodoro service.
///
/// The database remains the source of truth for the session. This bridge only
/// projects the persisted session into Android's notification/service layer.
class PomodoroForegroundService {
  PomodoroForegroundService({
    MethodChannel? channel,
    bool? enabled,
  })  : _channel = channel ?? _defaultChannel,
        _enabled = enabled;

  static const _channelName = 'dailydesk/pomodoro_service';
  static const MethodChannel _defaultChannel = MethodChannel(_channelName);

  final MethodChannel _channel;
  final bool? _enabled;

  bool get isEnabled => _enabled ?? (!kIsWeb && Platform.isAndroid);

  Future<void> start({
    required DateTime startedAt,
    required int plannedMinutes,
    required String mode,
    String? title,
    String? body,
  }) async {
    if (!isEnabled) {
      return;
    }

    final permissionGranted = await _channel.invokeMethod<bool>(
      'requestNotificationPermission',
    );
    if (permissionGranted == false) {
      throw StateError('Android 通知权限未授予，无法显示番茄钟常驻通知');
    }

    final isCountdown = mode != 'flowtime' && plannedMinutes > 0;
    final isShortBreak = mode == 'shortBreak';
    final isLongBreak = mode == 'longBreak';
    final resolvedTitle = title ??
        (isShortBreak || isLongBreak ? 'DailyDesk 休息中' : 'DailyDesk 专注中');
    final resolvedBody = body ??
        (isLongBreak
            ? '长休正在进行'
            : isShortBreak
                ? '短休正在进行'
                : '番茄钟正在运行');
    final startedAtMillis = startedAt.millisecondsSinceEpoch;
    final endAtMillis = isCountdown
        ? startedAtMillis + plannedMinutes * Duration.millisecondsPerMinute
        : null;
    await _channel.invokeMethod<void>('start', {
      'title': resolvedTitle,
      'body': resolvedBody,
      'startedAtMillis': startedAtMillis,
      'endAtMillis': endAtMillis,
      'countDown': isCountdown,
    });
  }

  Future<void> stop() async {
    if (!isEnabled) {
      return;
    }
    await _channel.invokeMethod<void>('stop');
  }
}
