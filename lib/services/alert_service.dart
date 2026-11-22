import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

/// Plays the end-of-session sound and vibration. The sound is generated in
/// code (two short beeps), so no audio asset is needed.
class AlertService {
  final AudioPlayer _player = AudioPlayer();
  late final Uint8List _beep = _buildBeep();

  Future<void> playSound(double volume) async {
    try {
      await _player.stop();
      await _player.setVolume(volume.clamp(0.0, 1.0));
      await _player.play(BytesSource(_beep, mimeType: 'audio/wav'));
    } catch (_) {
      // Sound is optional; never crash the timer because of it.
    }
  }

  Future<void> vibrate() async {
    try {
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(pattern: [0, 350, 150, 350]);
      }
    } catch (_) {}
  }

  Future<void> alert({required double volume, required bool vibration}) async {
    if (volume > 0) await playSound(volume);
    if (vibration) await vibrate();
  }

  void dispose() => _player.dispose();

  static Uint8List _buildBeep() {
    const sampleRate = 22050;
    const freq = 880.0;
    // beep 0.25s, gap 0.15s, beep 0.25s
    final segments = <(double, bool)>[(0.25, true), (0.15, false), (0.25, true)];
    final samples = <int>[];
    for (final (dur, on) in segments) {
      final n = (dur * sampleRate).round();
      for (var i = 0; i < n; i++) {
        if (!on) {
          samples.add(0);
          continue;
        }
        // short fade in/out to avoid clicks
        final env = math.min(1.0, math.min(i, n - i) / (sampleRate * 0.01));
        final v = math.sin(2 * math.pi * freq * i / sampleRate) * env * 0.8;
        samples.add((v * 32767).round());
      }
    }
    final dataLen = samples.length * 2;
    final b = ByteData(44 + dataLen);
    void str(int o, String s) {
      for (var i = 0; i < s.length; i++) {
        b.setUint8(o + i, s.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    b.setUint32(4, 36 + dataLen, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    b.setUint32(16, 16, Endian.little);
    b.setUint16(20, 1, Endian.little); // PCM
    b.setUint16(22, 1, Endian.little); // mono
    b.setUint32(24, sampleRate, Endian.little);
    b.setUint32(28, sampleRate * 2, Endian.little);
    b.setUint16(32, 2, Endian.little);
    b.setUint16(34, 16, Endian.little);
    str(36, 'data');
    b.setUint32(40, dataLen, Endian.little);
    for (var i = 0; i < samples.length; i++) {
      b.setInt16(44 + i * 2, samples[i], Endian.little);
    }
    return b.buffer.asUint8List();
  }
}
