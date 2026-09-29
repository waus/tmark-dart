part of tmark;

/// Media formats required by the tmark content policy.
enum TmarkImageFormat { jpeg, webp, avif, png, jpegXl, lottie }

/// Audio codec and container combinations required by the content policy.
enum TmarkAudioFormat { mp3, flac, oggOpus, mp4AacLc }

/// Identifies supported image bytes. File names and MIME types are not trusted.
TmarkImageFormat? detectTmarkImageFormat(Uint8List bytes) {
  if (_startsWith(bytes, [0xff, 0xd8, 0xff])) return TmarkImageFormat.jpeg;
  if (_startsWith(bytes, [0x89, 0x50, 0x4e, 0x47, 13, 10, 26, 10])) {
    return TmarkImageFormat.png;
  }
  if (_asciiAt(bytes, 0, 'RIFF') && _asciiAt(bytes, 8, 'WEBP')) {
    return TmarkImageFormat.webp;
  }
  if (_isAvif(bytes)) return TmarkImageFormat.avif;
  if (_startsWith(bytes, [0xff, 0x0a]) ||
      _startsWith(bytes, [
        0,
        0,
        0,
        12,
        0x4a,
        0x58,
        0x4c,
        0x20,
        13,
        10,
        0x87,
        10,
      ])) {
    return TmarkImageFormat.jpegXl;
  }
  if (_isSelfContainedLottie(bytes)) return TmarkImageFormat.lottie;
  return null;
}

bool _isSelfContainedLottie(Uint8List bytes) {
  try {
    final value = jsonDecode(utf8.decode(bytes));
    if (value is! Map<String, dynamic> ||
        value['v'] is! String ||
        value['fr'] is! num ||
        value['ip'] is! num ||
        value['op'] is! num ||
        value['w'] is! num ||
        value['h'] is! num ||
        value['layers'] is! List) {
      return false;
    }
    final assets = value['assets'];
    if (assets != null && assets is! List) return false;
    if (assets is List) {
      for (final asset in assets) {
        if (asset is! Map) return false;
        final image = asset['p'];
        if (image is String &&
            image.isNotEmpty &&
            !image.startsWith('data:image/')) {
          return false;
        }
      }
    }
    return true;
  } on FormatException {
    return false;
  }
}

/// Identifies supported audio bytes, including the required container/profile.
TmarkAudioFormat? detectTmarkAudioFormat(Uint8List bytes) {
  if (_asciiAt(bytes, 0, 'fLaC')) return TmarkAudioFormat.flac;
  if (_asciiAt(bytes, 0, 'OggS') &&
      bytes.length >= 36 &&
      bytes[26] > 0 &&
      bytes[27] >= 8 &&
      _asciiAt(bytes, 28, 'OpusHead')) {
    return TmarkAudioFormat.oggOpus;
  }
  if (_isAacLcMp4(bytes)) return TmarkAudioFormat.mp4AacLc;
  if (_isMp3(bytes)) {
    return TmarkAudioFormat.mp3;
  }
  return null;
}

bool _startsWith(Uint8List bytes, List<int> prefix) {
  if (bytes.length < prefix.length) return false;
  for (var i = 0; i < prefix.length; i++) {
    if (bytes[i] != prefix[i]) return false;
  }
  return true;
}

bool _asciiAt(Uint8List bytes, int offset, String text) {
  if (offset < 0 || offset + text.length > bytes.length) return false;
  for (var i = 0; i < text.length; i++) {
    if (bytes[offset + i] != text.codeUnitAt(i)) return false;
  }
  return true;
}

int _u32(Uint8List bytes, int offset) =>
    (bytes[offset] << 24) |
    (bytes[offset + 1] << 16) |
    (bytes[offset + 2] << 8) |
    bytes[offset + 3];

bool _isAvif(Uint8List bytes) {
  if (bytes.length < 16 || !_asciiAt(bytes, 4, 'ftyp')) return false;
  final end = _u32(bytes, 0);
  if (end < 16 || end > bytes.length) return false;
  for (var offset = 8; offset + 4 <= end; offset += 4) {
    if (offset == 12) continue; // Minor version, not a brand.
    if (_asciiAt(bytes, offset, 'avif') || _asciiAt(bytes, offset, 'avis')) {
      return true;
    }
  }
  return false;
}

bool _isMp3(Uint8List bytes) {
  var offset = 0;
  if (_asciiAt(bytes, 0, 'ID3')) {
    if (bytes.length < 10 ||
        bytes[6] > 0x7f ||
        bytes[7] > 0x7f ||
        bytes[8] > 0x7f ||
        bytes[9] > 0x7f)
      return false;
    offset =
        10 + (bytes[6] << 21) + (bytes[7] << 14) + (bytes[8] << 7) + bytes[9];
    if (bytes[5] & 0x10 != 0) offset += 10; // ID3v2 footer.
    while (offset < bytes.length && bytes[offset] == 0) offset++;
  }
  if (offset + 4 > bytes.length ||
      bytes[offset] != 0xff ||
      (bytes[offset + 1] & 0xe0) != 0xe0) {
    return false;
  }
  final version = (bytes[offset + 1] >> 3) & 3;
  final layer = (bytes[offset + 1] >> 1) & 3;
  final bitrate = (bytes[offset + 2] >> 4) & 15;
  final sampleRate = (bytes[offset + 2] >> 2) & 3;
  return version != 1 &&
      layer != 0 &&
      bitrate != 0 &&
      bitrate != 15 &&
      sampleRate != 3;
}

bool _isAacLcMp4(Uint8List bytes) {
  if (bytes.length < 16 || !_asciiAt(bytes, 4, 'ftyp')) return false;
  final ftypSize = _u32(bytes, 0);
  if (ftypSize < 16 || ftypSize > bytes.length) return false;
  return _hasAacLcSampleEntry(bytes, ftypSize, bytes.length);
}

bool _hasAacLcSampleEntry(
  Uint8List bytes,
  int start,
  int end, [
  int depth = 0,
]) {
  if (depth > 16) return false;
  for (var offset = start; offset + 8 <= end;) {
    final size = _u32(bytes, offset);
    if (size < 8 || offset + size > end) return false;
    final payload = offset + 8;
    final boxEnd = offset + size;
    if (_asciiAt(bytes, offset + 4, 'moov') ||
        _asciiAt(bytes, offset + 4, 'trak') ||
        _asciiAt(bytes, offset + 4, 'mdia') ||
        _asciiAt(bytes, offset + 4, 'minf') ||
        _asciiAt(bytes, offset + 4, 'stbl')) {
      if (_hasAacLcSampleEntry(bytes, payload, boxEnd, depth + 1)) return true;
    } else if (_asciiAt(bytes, offset + 4, 'stsd')) {
      if (payload + 8 <= boxEnd &&
          _hasAacLcSampleEntry(bytes, payload + 8, boxEnd, depth + 1))
        return true;
    } else if (_asciiAt(bytes, offset + 4, 'mp4a')) {
      // AudioSampleEntry has 28 bytes before its child boxes.
      if (payload + 28 <= boxEnd &&
          _hasAacLcSampleEntry(bytes, payload + 28, boxEnd, depth + 1))
        return true;
    } else if (_asciiAt(bytes, offset + 4, 'esds')) {
      if (_hasAacLcConfig(bytes, payload + 4, boxEnd)) return true;
    }
    offset = boxEnd;
  }
  return false;
}

bool _hasAacLcConfig(Uint8List bytes, int start, int end) {
  // MPEG-4 descriptor tag 0x05 is DecoderSpecificInfo. Descriptor headers
  // preceding it are nested and may carry variable-length payload lengths.
  for (var i = start; i + 2 < end; i++) {
    if (bytes[i] != 5) continue;
    var length = 0;
    var cursor = i + 1;
    for (var n = 0; n < 4 && cursor < end; n++) {
      final value = bytes[cursor++];
      length = (length << 7) | (value & 0x7f);
      if (value & 0x80 == 0) break;
    }
    if (length < 2 || cursor + length > end) continue;
    final audioObjectType = bytes[cursor] >> 3;
    if (audioObjectType != 2) continue; // AAC-LC only.
    var hasSbr = false;
    for (var bit = 0; bit + 17 <= length * 8; bit++) {
      final sync = _readBits(bytes, cursor, bit, 11);
      if (sync == 0x2b7 &&
          _readBits(bytes, cursor, bit + 11, 5) == 5 &&
          _readBits(bytes, cursor, bit + 16, 1) == 1) {
        hasSbr = true;
        break;
      }
    }
    if (!hasSbr) return true;
  }
  return false;
}

int _readBits(Uint8List bytes, int offset, int bit, int count) {
  var value = 0;
  for (var i = 0; i < count; i++) {
    final position = bit + i;
    value =
        (value << 1) |
        ((bytes[offset + position ~/ 8] >> (7 - position % 8)) & 1);
  }
  return value;
}
