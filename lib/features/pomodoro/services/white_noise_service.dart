import 'package:audioplayers/audioplayers.dart';

/// Four-track ambience mixer. Players are created only when a track starts.
class WhiteNoiseService {
  WhiteNoiseService._();

  static final WhiteNoiseService instance = WhiteNoiseService._();

  static const Map<String, String> tracks = {
    'rain': '🌧️ 暴雨声',
    'forest': '🌲 森林鸟鸣',
    'cafe': '☕ 咖啡馆',
    'wave': '🌊 潮汐海浪',
  };

  final Map<String, AudioPlayer> _players = {};

  Set<String> get activeTracks => Set.unmodifiable(_players.keys);

  bool isPlaying(String key) => _players.containsKey(key);

  Future<void> toggle(String key, {double volume = 0.6}) async {
    if (_players.containsKey(key)) {
      await stop(key);
      return;
    }
    await start(key, volume: volume);
  }

  Future<void> start(String key, {double volume = 0.6}) async {
    if (!tracks.containsKey(key) || _players.containsKey(key)) {
      return;
    }

    final player = AudioPlayer(playerId: 'noise_$key');
    try {
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(volume.clamp(0.0, 1.0).toDouble());
      await player.play(AssetSource('ambient/$key.mp3'));
      _players[key] = player;
    } catch (_) {
      await player.release();
      rethrow;
    }
  }

  Future<void> stop(String key) async {
    final player = _players.remove(key);
    if (player == null) {
      return;
    }
    await player.stop();
    await player.release();
  }

  Future<void> setVolume(String key, double volume) async {
    final player = _players[key];
    if (player != null) {
      await player.setVolume(volume.clamp(0.0, 1.0).toDouble());
    }
  }

  Future<void> stopAll() async {
    final players = _players.values.toList(growable: false);
    _players.clear();
    for (final player in players) {
      await player.stop();
      await player.release();
    }
  }

  Future<void> dispose() => stopAll();
}
