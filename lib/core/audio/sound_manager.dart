import 'package:audioplayers/audioplayers.dart';

/// Global manager for short, offline UI sound effects.
class SoundManager {
  SoundManager._();

  static final SoundManager instance = SoundManager._();

  late final AudioPlayer _player = AudioPlayer(playerId: 'sfx');
  bool enabled = true;

  Future<void> playPop() => _play('sfx/pop.mp3', volume: 0.4);

  Future<void> playDing() => _play('sfx/ding.mp3', volume: 0.5);

  Future<void> _play(String assetPath, {required double volume}) async {
    if (!enabled) {
      return;
    }

    try {
      await _player.play(AssetSource(assetPath), volume: volume);
    } on Exception {
      // Audio is optional on platforms where the plugin is unavailable.
    }
  }
}
