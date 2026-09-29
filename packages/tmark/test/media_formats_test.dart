import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:tmark/tmark.dart';

void main() {
  test('image whitelist uses content signatures', () {
    expect(
      detectTmarkImageFormat(_bytes([0xff, 0xd8, 0xff, 0xe0])),
      TmarkImageFormat.jpeg,
    );
    expect(
      detectTmarkImageFormat(_bytes([0x89, 0x50, 0x4e, 0x47, 13, 10, 26, 10])),
      TmarkImageFormat.png,
    );
    expect(
      detectTmarkImageFormat(
        _bytes([...'RIFF'.codeUnits, 0, 0, 0, 0, ...'WEBP'.codeUnits]),
      ),
      TmarkImageFormat.webp,
    );
    expect(
      detectTmarkImageFormat(
        _box('ftyp', [...'avif'.codeUnits, 0, 0, 0, 0, ...'mif1'.codeUnits]),
      ),
      TmarkImageFormat.avif,
    );
    expect(
      detectTmarkImageFormat(_bytes([0xff, 0x0a])),
      TmarkImageFormat.jpegXl,
    );
    expect(
      detectTmarkImageFormat(
        _bytes([0, 0, 0, 12, ...'JXL '.codeUnits, 13, 10, 0x87, 10]),
      ),
      TmarkImageFormat.jpegXl,
    );
    expect(detectTmarkImageFormat(_bytes('GIF89a'.codeUnits)), isNull);
    const lottie =
        '{"v":"5.7.4","fr":30,"ip":0,"op":30,'
        '"w":64,"h":64,"layers":[]}';
    expect(
      detectTmarkImageFormat(_bytes(lottie.codeUnits)),
      TmarkImageFormat.lottie,
    );
    expect(detectTmarkImageFormat(_bytes('{"v":"5"}'.codeUnits)), isNull);
    expect(
      detectTmarkImageFormat(
        _bytes(
          '{"v":"5.7.4","fr":30,"ip":0,"op":30,"w":64,"h":64,'
                  '"layers":[],"assets":[{"p":"remote.png"}]}'
              .codeUnits,
        ),
      ),
      isNull,
    );
    expect(detectTmarkImageFormat(_bytes([])), isNull);
  });

  test('audio whitelist checks codec and container', () {
    expect(detectTmarkAudioFormat(_bytes('ID3'.codeUnits)), isNull);
    expect(
      detectTmarkAudioFormat(
        _bytes([...'ID3'.codeUnits, 4, 0, 0, 0, 0, 0, 0, 0xff, 0xfb, 0x90, 0]),
      ),
      TmarkAudioFormat.mp3,
    );
    expect(
      detectTmarkAudioFormat(_bytes([0xff, 0xfb, 0x90, 0x00])),
      TmarkAudioFormat.mp3,
    );
    expect(
      detectTmarkAudioFormat(_bytes('fLaC'.codeUnits)),
      TmarkAudioFormat.flac,
    );
    expect(
      detectTmarkAudioFormat(
        _bytes([
          ...'OggS'.codeUnits,
          ...List.filled(22, 0),
          1,
          8,
          ...'OpusHead'.codeUnits,
        ]),
      ),
      TmarkAudioFormat.oggOpus,
    );
    expect(
      detectTmarkAudioFormat(_mp4([0x12, 0x10])),
      TmarkAudioFormat.mp4AacLc,
    );
    expect(detectTmarkAudioFormat(_mp4([0x2b, 0x90])), isNull); // HE-AAC
    expect(
      detectTmarkAudioFormat(_mp4([0x12, 0x10, 0x56, 0xe5, 0x80])),
      isNull,
    ); // AAC-LC with implicit SBR
    expect(
      detectTmarkAudioFormat(
        _bytes([
          ...'OggS'.codeUnits,
          ...List.filled(24, 0),
          ...'fLaC'.codeUnits,
        ]),
      ),
      isNull,
    );
    expect(
      detectTmarkAudioFormat(_bytes([0xff, 0xf1, 0x50, 0x80])),
      isNull,
    ); // AAC in ADTS
    expect(detectTmarkAudioFormat(_bytes('RIFF'.codeUnits)), isNull);
  });
}

Uint8List _bytes(List<int> values) => Uint8List.fromList(values);

Uint8List _box(String type, List<int> payload) {
  final size = payload.length + 8;
  return _bytes([
    (size >> 24) & 255,
    (size >> 16) & 255,
    (size >> 8) & 255,
    size & 255,
    ...type.codeUnits,
    ...payload,
  ]);
}

Uint8List _mp4(List<int> audioSpecificConfig) {
  final esds = _box('esds', [
    0,
    0,
    0,
    0,
    5,
    audioSpecificConfig.length,
    ...audioSpecificConfig,
  ]);
  final mp4a = _box('mp4a', [...List.filled(28, 0), ...esds]);
  final stsd = _box('stsd', [...List.filled(4, 0), 0, 0, 0, 1, ...mp4a]);
  return _bytes([
    ..._box('ftyp', [...'isom'.codeUnits, ...List.filled(4, 0)]),
    ..._box('moov', [
      ..._box('trak', [
        ..._box('mdia', [
          ..._box('minf', [
            ..._box('stbl', [...stsd]),
          ]),
        ]),
      ]),
    ]),
  ]);
}
