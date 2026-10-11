import 'package:dailydesk/features/pomodoro/data/pomodoro_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pomodoroRepoProvider = Provider<PomodoroRepository>(
  (ref) => throw StateError('pomodoroRepoProvider must be overridden'),
);

final closeToTrayProvider = StateProvider<bool>((ref) => true);
