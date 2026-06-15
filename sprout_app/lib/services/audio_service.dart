import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Singleton audio service — preloads all UI sound effects and
/// provides TTS for spoken feedback. No latency on first play.
///
/// Sound design philosophy (child UX checklist §4):
///   tap_ack   : immediate (<50ms) gentle pop — every valid tap
///   correct   : two ascending notes — before celebration animation
///   try_again : soft descending boing — gentle, NOT a buzzer
///   celebrate : 4-note ascending melody — completion moment
///   bud_chirp : occasional idle tone from mascot
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final FlutterTts _tts = FlutterTts();
  final List<AudioPlayer> _pool = [];
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Configure TTS for children — slower rate, higher pitch = friendlier
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(0.8);
    await _tts.setPitch(1.2);

    // Pre-warm 4 audio players so first play has zero latency
    for (int i = 0; i < 4; i++) {
      final player = AudioPlayer();
      await player.setVolume(0.7);
      _pool.add(player);
    }
  }

  AudioPlayer _getFreePlayer() {
    for (final p in _pool) {
      if (p.state != PlayerState.playing) return p;
    }
    final p = AudioPlayer()..setVolume(0.7);
    _pool.add(p);
    return p;
  }

  /// Generate a sine wave WAV as [Uint8List].
  /// 44100 Hz, 16-bit mono — no external asset files needed.
  Uint8List _generateSineWave(double frequency, int durationMs,
      {double volume = 1.0}) {
    const sampleRate = 44100;
    final numSamples = (sampleRate * durationMs / 1000).round();
    final dataSize = numSamples * 2;
    final totalSize = 44 + dataSize;
    final bytes = ByteData(totalSize);

    int offset = 0;

    void writeStr(String s) {
      for (final c in s.codeUnits) {
        bytes.setUint8(offset++, c);
      }
    }

    void writeU32(int v) {
      bytes.setUint32(offset, v, Endian.little);
      offset += 4;
    }

    void writeU16(int v) {
      bytes.setUint16(offset, v, Endian.little);
      offset += 2;
    }

    // WAV header
    writeStr('RIFF');
    writeU32(36 + dataSize);
    writeStr('WAVE');
    writeStr('fmt ');
    writeU32(16);
    writeU16(1); // PCM
    writeU16(1); // Mono
    writeU32(sampleRate);
    writeU32(sampleRate * 2); // ByteRate
    writeU16(2); // BlockAlign
    writeU16(16); // BitsPerSample
    writeStr('data');
    writeU32(dataSize);

    // Audio samples with short attack/release to avoid clicks
    final attackSamples = (sampleRate * 0.01).round();
    final releaseSamples = (sampleRate * 0.01).round();

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      double envelope = 1.0;
      if (i < attackSamples) {
        envelope = i / attackSamples;
      } else if (i > numSamples - releaseSamples) {
        envelope = (numSamples - i) / releaseSamples;
      }
      final raw = math.sin(2 * math.pi * frequency * t) * envelope * volume;
      final sample = (raw * 16000).round().clamp(-32768, 32767);
      bytes.setInt16(offset, sample, Endian.little);
      offset += 2;
    }

    return bytes.buffer.asUint8List();
  }

  Future<void> _playTone(double frequency, int durationMs,
      {double volume = 0.7}) async {
    try {
      final player = _getFreePlayer();
      final wav = _generateSineWave(frequency, durationMs, volume: volume);
      await player.play(BytesSource(wav));
    } catch (_) {
      // Graceful degradation — audio failure never crashes the app
    }
  }

  // ─── Public Sound API ─────────────────────────────────────────

  /// Immediate gentle pop — plays on every valid tap (≤50ms latency target)
  Future<void> playTapAck() => _playTone(660, 80, volume: 0.5);

  /// Two ascending notes — plays before celebration animation
  Future<void> playCorrect() async {
    await _playTone(523, 150);
    await Future.delayed(const Duration(milliseconds: 90));
    await _playTone(659, 200);
  }

  /// Soft descending boing — gentle "try again" (never harsh)
  Future<void> playTryAgain() => _playTone(330, 250, volume: 0.55);

  /// 4-note ascending melody — full completion celebration
  Future<void> playCelebrate() async {
    await _playTone(523, 120);
    await Future.delayed(const Duration(milliseconds: 70));
    await _playTone(587, 120);
    await Future.delayed(const Duration(milliseconds: 70));
    await _playTone(659, 120);
    await Future.delayed(const Duration(milliseconds: 70));
    await _playTone(784, 300);
  }

  /// Bud's idle chirp — played every ~10s by the mascot widget
  Future<void> playBudChirp() => _playTone(880, 55, volume: 0.28);

  /// Parental gate: success sound
  Future<void> playGatePass() async {
    await _playTone(440, 100);
    await Future.delayed(const Duration(milliseconds: 60));
    await _playTone(880, 200);
  }

  // ─── TTS API ─────────────────────────────────────────────────

  /// Speak text with child-friendly TTS settings
  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() => _tts.stop();

  // ─── Lifecycle ───────────────────────────────────────────────

  Future<void> dispose() async {
    await _tts.stop();
    for (final p in _pool) {
      await p.dispose();
    }
    _pool.clear();
    _initialized = false;
  }
}
