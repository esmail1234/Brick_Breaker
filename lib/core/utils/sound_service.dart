import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

/// Generates and plays synthesized sound effects using raw PCM WAV bytes.
/// No audio asset files needed – everything is generated in memory.
class SoundService {
  SoundService._();

  static final Map<String, AudioPlayer> _players = {};
  static bool _muted = false;

  static bool get isMuted => _muted;
  static void toggleMute() => _muted = !_muted;

  // ── WAV Generator ─────────────────────────────────────────────────────────

  static Uint8List _buildWav(
    double frequency,
    double duration, {
    double decay = 10.0,
    double volume = 0.35,
    double? frequency2, // optional second harmonic
  }) {
    const sampleRate = 22050;
    final n = (duration * sampleRate).round();
    final dataLen = n * 2;
    final buf = ByteData(44 + dataLen);

    // RIFF header
    void setStr(int off, String s) {
      for (int i = 0; i < s.length; i++) {
        buf.setUint8(off + i, s.codeUnitAt(i));
      }
    }

    setStr(0, 'RIFF');
    buf.setUint32(4, 36 + dataLen, Endian.little);
    setStr(8, 'WAVE');
    setStr(12, 'fmt ');
    buf.setUint32(16, 16, Endian.little);
    buf.setUint16(20, 1, Endian.little);  // PCM
    buf.setUint16(22, 1, Endian.little);  // mono
    buf.setUint32(24, sampleRate, Endian.little);
    buf.setUint32(28, sampleRate * 2, Endian.little);
    buf.setUint16(32, 2, Endian.little);
    buf.setUint16(34, 16, Endian.little);
    setStr(36, 'data');
    buf.setUint32(40, dataLen, Endian.little);

    for (int i = 0; i < n; i++) {
      final t = i / sampleRate;
      final env = math.exp(-t * decay);
      double s = math.sin(2 * math.pi * frequency * t);
      if (frequency2 != null) {
        s = (s + math.sin(2 * math.pi * frequency2 * t)) * 0.5;
      }
      final sample = (env * volume * s * 32767).round().clamp(-32768, 32767);
      buf.setInt16(44 + i * 2, sample, Endian.little);
    }
    return buf.buffer.asUint8List();
  }

  // Pre-generated sound buffers
  static final Uint8List _ballHit  = _buildWav(440, 0.07, decay: 22);
  static final Uint8List _brickBreak = _buildWav(260, 0.14, decay: 14, frequency2: 195);
  static final Uint8List _powerUp  = _buildWav(660, 0.22, decay: 7, frequency2: 880);
  static final Uint8List _combo    = _buildWav(880, 0.18, decay: 10, frequency2: 1100);
  static final Uint8List _gameOver = _buildWav(110, 0.5, decay: 3, volume: 0.5);
  static final Uint8List _bossHit  = _buildWav(150, 0.2, decay: 8, frequency2: 220);

  // ── Playback ──────────────────────────────────────────────────────────────

  static Future<void> _play(String key, Uint8List bytes) async {
    if (_muted) return;
    try {
      final player = _players.putIfAbsent(key, () => AudioPlayer());
      await player.play(BytesSource(bytes));
    } catch (_) {}
  }

  static Future<void> playBallHit()   => _play('hit', _ballHit);
  static Future<void> playBrickBreak()=> _play('break', _brickBreak);
  static Future<void> playPowerUp()   => _play('pu', _powerUp);
  static Future<void> playCombo()     => _play('combo', _combo);
  static Future<void> playGameOver()  => _play('gameover', _gameOver);
  static Future<void> playBossHit()   => _play('boss', _bossHit);

  static void dispose() {
    for (final p in _players.values) {
      p.dispose();
    }
    _players.clear();
  }
}
