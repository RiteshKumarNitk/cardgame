// ignore_for_file: avoid_print

// Run: dart tools/generate_audio.dart
// Generates minimal placeholder WAV files under assets/audio/sfx/ and
// assets/audio/music/ so the AudioService can reference them without
// crashing.

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const _sampleRate = 22050;
const _sfxDir = 'assets/audio/sfx';
const _musicDir = 'assets/audio/music';

void main() {
  Directory(_sfxDir).createSync(recursive: true);
  Directory(_musicDir).createSync(recursive: true);

  _generate('tap', _tap(), dir: _sfxDir);
  _generate('piece_snap', _pieceSnap(), dir: _sfxDir);
  _generate('victory', _victory(), dir: _sfxDir);
  _generate('chapter_complete', _chapterComplete(), dir: _sfxDir);
  _generate('coins', _coins(), dir: _sfxDir);
  _generate('hover', _hover(), dir: _sfxDir);
  _generate('level_start', _levelStart(), dir: _sfxDir);
  _generate('tick', _tick(), dir: _sfxDir);
  _generate('bgm_loop', _bgmLoop(), dir: _musicDir);

  print('✅ Placeholder audio files generated in $_sfxDir and $_musicDir');
  print('📢 Replace them with real .wav files before release.');
}

// ── WAV helpers ──

void _generate(String name, List<double> samples, {required String dir}) {
  final bytes = _wavBytes(samples);
  File('$dir/$name.wav').writeAsBytesSync(bytes);
  print('  wrote $dir/$name.wav (${samples.length} samples, '
      '${(samples.length / _sampleRate * 1000).round()}ms)');
}

List<int> _wavBytes(List<double> samples) {
  final data = Int16List(samples.length);
  for (var i = 0; i < samples.length; i++) {
    data[i] = (samples[i].clamp(-1.0, 1.0) * 32767).round();
  }
  final dataBytes = data.buffer.asUint8List();
  return [
    ..._riffHeader(dataBytes.length),
    ...dataBytes,
  ];
}

List<int> _riffHeader(int dataLen) {
  final header = ByteData(44);
  var offset = 0;

  void writeString(String s) {
    for (var i = 0; i < s.length; i++) {
      header.setUint8(offset++, s.codeUnitAt(i));
    }
  }

  void writeUint16(int v) {
    header.setUint16(offset, v, Endian.little);
    offset += 2;
  }

  void writeUint32(int v) {
    header.setUint32(offset, v, Endian.little);
    offset += 4;
  }

  writeString('RIFF');
  writeUint32(36 + dataLen);
  writeString('WAVE');
  writeString('fmt ');
  writeUint32(16);          // chunk size
  writeUint16(1);           // PCM
  writeUint16(1);           // mono
  writeUint32(_sampleRate);
  writeUint32(_sampleRate * 2); // byte rate
  writeUint16(2);           // block align
  writeUint16(16);          // bits per sample
  writeString('data');
  writeUint32(dataLen);

  return header.buffer.asUint8List();
}

// ── Sound generators ──

/// Short click — quick attack, fast decay.
List<double> _tap() {
  final len = (_sampleRate * 0.04).round();
  return List.generate(len, (i) {
    final t = i / _sampleRate;
    final env = exp(-t * 80);
    return sin(2 * pi * 800 * t) * env * 0.6;
  });
}

/// A satisfying "pop" — frequency sweep up.
List<double> _pieceSnap() {
  final len = (_sampleRate * 0.12).round();
  return List.generate(len, (i) {
    final t = i / _sampleRate;
    final freq = 200 + 400 * (t / 0.12);
    final env = exp(-t * 25);
    return sin(2 * pi * freq * t) * env * 0.7;
  });
}

/// Ascending triumphant chord (C-E-G).
List<double> _victory() {
  final len = (_sampleRate * 0.8).round();
  return List.generate(len, (i) {
    final t = i / _sampleRate;
    final env = 1.0 - exp(-t * 8); // attack
    final decay = exp(-t * 1.5);   // slow decay
    final s = sin(2 * pi * 523.25 * t) +  // C5
              sin(2 * pi * 659.25 * t) +  // E5
              sin(2 * pi * 783.99 * t);   // G5
    return s * env * decay * 0.25;
  });
}

/// Fanfare for chapter completion — brighter, longer.
List<double> _chapterComplete() {
  final len = (_sampleRate * 1.2).round();
  return List.generate(len, (i) {
    final t = i / _sampleRate;
    final env = 1.0 - exp(-t * 6);
    final decay = exp(-t * 0.8);
    final s = sin(2 * pi * 659.25 * t) +  // E5
              sin(2 * pi * 783.99 * t) +  // G5
              sin(2 * pi * 1046.5 * t);   // C6
    return s * env * decay * 0.2;
  });
}

/// Short bright chime for coin rewards.
List<double> _coins() {
  final len = (_sampleRate * 0.35).round();
  return List.generate(len, (i) {
    final t = i / _sampleRate;
    final env = exp(-t * 6);
    final s = sin(2 * pi * 1318.5 * t) +  // E6
              sin(2 * pi * 1760.0 * t);   // A6
    return s * env * 0.3;
  });
}

/// Subtle whoosh for button hover / preview open.
List<double> _hover() {
  final len = (_sampleRate * 0.15).round();
  return List.generate(len, (i) {
    final t = i / _sampleRate;
    final freq = 400 + 600 * (t / 0.15);
    final env = exp(-t * 30);
    return sin(2 * pi * freq * t) * env * 0.3;
  });
}

/// Short ascending sweep for level start.
List<double> _levelStart() {
  final len = (_sampleRate * 0.3).round();
  return List.generate(len, (i) {
    final t = i / _sampleRate;
    final freq = 300 + 200 * (t / 0.3);
    final env = 1.0 - exp(-t * 10);
    return sin(2 * pi * freq * t) * env * 0.4;
  });
}

/// Short high "tick" for countdown warnings — a crisp click a touch
/// brighter than [startup], with a quick decay.
List<double> _tick() {
  final len = (_sampleRate * 0.03).round();
  return List.generate(len, (i) {
    final t = i / _sampleRate;
    final env = exp(-t * 120);
    return sin(2 * pi * 1200 * t) * env * 0.5;
  });
}

/// Minimal looping melody (8 bars, ~3s) for BGM placeholder.
List<double> _bgmLoop() {
  final bpm = 100;
  final beatLen = _sampleRate * 60 ~/ bpm;
  final totalLen = beatLen * 8; // 2 bars of 4/4
  return List.generate(totalLen, (i) {
    final t = i / _sampleRate;
    final beat = (i ~/ beatLen) % 8;
    final noteHz = [262, 294, 330, 349, 330, 294, 262, 330][beat];
    final env = exp(-(i % beatLen) / beatLen * 4);
    return sin(2 * pi * noteHz * t) * env * 0.15;
  });
}
