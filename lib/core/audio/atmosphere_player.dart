import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Low-level looping ambience so the TTS / host voice can sit clearly on top.
class AtmospherePlayer {
  AtmospherePlayer() : _player = AudioPlayer();

  final AudioPlayer _player;
  File? _cacheFile;
  var _ready = false;

  static const double defaultVolume = 0.16;

  Future<void> init() async {
    if (_ready) return;
    final temp = await getTemporaryDirectory();
    _cacheFile = File(p.join(temp.path, 'auraradio_atmosphere.wav'));
    if (!await _cacheFile!.exists() || await _cacheFile!.length() < 1000) {
      await _writeSoftNoiseWav(_cacheFile!);
    }
    await _player.setLoopMode(LoopMode.one);
    await _player.setVolume(defaultVolume);
    await _player.setAudioSource(
      AudioSource.file(_cacheFile!.path),
    );
    _ready = true;
  }

  /// Short PCM WAV (mono, 16-bit) of soft noise — no external binary assets required.
  Future<void> _writeSoftNoiseWav(File f) async {
    const sampleRate = 22050;
    const seconds = 2;
    final n = sampleRate * seconds;
    final r = Random();
    final pcm = Int16List(n);
    for (var i = 0; i < n; i++) {
      final v = ((r.nextDouble() * 2 - 1) * 1800).round();
      pcm[i] = v.clamp(-32768, 32767).toInt();
    }
    final dataBytes = ByteData(n * 2);
    for (var i = 0; i < n; i++) {
      dataBytes.setInt16(i * 2, pcm[i], Endian.little);
    }
    final header = _pcm16WavHeader(
      dataByteLength: n * 2,
      sampleRate: sampleRate,
    );
    final out = BytesBuilder()..add(header)..add(dataBytes.buffer.asUint8List());
    await f.writeAsBytes(out.toBytes());
  }

  List<int> _pcm16WavHeader({required int dataByteLength, required int sampleRate}) {
    const numChannels = 1;
    const bitsPerSample = 16;
    final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    final blockAlign = numChannels * (bitsPerSample ~/ 8);
    const chunk1Size = 16;
    final chunk2Size = dataByteLength;
    final riffChunkSize = 36 + chunk2Size;
    return [
      0x52, 0x49, 0x46, 0x46,
      ..._u32le(riffChunkSize),
      0x57, 0x41, 0x56, 0x45,
      0x66, 0x6D, 0x74, 0x20,
      ..._u32le(16),
      ..._u16le(1),
      ..._u16le(numChannels),
      ..._u32le(sampleRate),
      ..._u32le(byteRate),
      ..._u16le(blockAlign),
      ..._u16le(bitsPerSample),
      0x64, 0x61, 0x74, 0x61,
      ..._u32le(chunk2Size),
    ];
  }

  List<int> _u32le(int v) => [v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff];
  List<int> _u16le(int v) => [v & 0xff, (v >> 8) & 0xff];

  Future<void> play() async {
    if (!_ready) await init();
    if (_player.playing) return;
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> setVolume(double v) => _player.setVolume(v.clamp(0, 1));

  Future<void> dispose() => _player.dispose();
}
