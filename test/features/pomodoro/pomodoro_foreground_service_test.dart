import 'package:dailydesk/features/pomodoro/services/pomodoro_foreground_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dailydesk/pomodoro_service');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('经典番茄将绝对结束时间传给 Android 服务', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'requestNotificationPermission' ? true : null;
    });
    final bridge = PomodoroForegroundService(
      channel: channel,
      enabled: true,
    );
    final startedAt = DateTime.fromMillisecondsSinceEpoch(1000000);

    await bridge.start(
      startedAt: startedAt,
      plannedMinutes: 25,
      mode: 'pomodoro',
    );

    expect(calls.map((call) => call.method), [
      'requestNotificationPermission',
      'start',
    ]);
    final args = calls.last.arguments as Map<Object?, Object?>;
    expect(args['startedAtMillis'], 1000000);
    expect(args['endAtMillis'], 1000000 + 25 * 60 * 1000);
    expect(args['countDown'], isTrue);
  });

  test('心流模式使用正向计时，停止调用 Android 服务', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'requestNotificationPermission' ? true : null;
    });
    final bridge = PomodoroForegroundService(
      channel: channel,
      enabled: true,
    );

    await bridge.start(
      startedAt: DateTime.fromMillisecondsSinceEpoch(2000000),
      plannedMinutes: 0,
      mode: 'flowtime',
    );
    await bridge.stop();

    expect(calls.map((call) => call.method), [
      'requestNotificationPermission',
      'start',
      'stop',
    ]);
    final args = calls.firstWhere((call) => call.method == 'start').arguments
        as Map<Object?, Object?>;
    expect(args['endAtMillis'], isNull);
    expect(args['countDown'], isFalse);
  });

  test('短休通知使用休息标题和短休文案', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'requestNotificationPermission' ? true : null;
    });
    final bridge = PomodoroForegroundService(
      channel: channel,
      enabled: true,
    );

    await bridge.start(
      startedAt: DateTime.fromMillisecondsSinceEpoch(3000000),
      plannedMinutes: 5,
      mode: 'shortBreak',
    );

    final args = calls.last.arguments as Map<Object?, Object?>;
    expect(args['title'], 'DailyDesk 休息中');
    expect(args['body'], '短休正在进行');
  });

  test('长休通知使用休息标题和长休文案', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'requestNotificationPermission' ? true : null;
    });
    final bridge = PomodoroForegroundService(
      channel: channel,
      enabled: true,
    );

    await bridge.start(
      startedAt: DateTime.fromMillisecondsSinceEpoch(4000000),
      plannedMinutes: 15,
      mode: 'longBreak',
    );

    final args = calls.last.arguments as Map<Object?, Object?>;
    expect(args['title'], 'DailyDesk 休息中');
    expect(args['body'], '长休正在进行');
  });
}
