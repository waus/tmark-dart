part of tmark;

sealed class _Part {
  const _Part();
}

final class _TextPart extends _Part {
  const _TextPart(this.text);
  final String text;
}

final class _NodePart extends _Part {
  const _NodePart(this.node);
  final _ParsedNode node;
}

final class _FieldPart extends _Part {
  const _FieldPart(this.field);
  final _ParsedField field;
}

final class _ParsedNode {
  const _ParsedNode(this.tag, this.body, this.raw);
  final String tag;
  final List<_Part> body;
  final String raw;
}

final class _ParsedField {
  const _ParsedField(this.name, this.value);
  final String name;
  final List<_Part> value;
}

final class _Parser {
  _Parser(String source) : data = source.replaceAll('\r\n', '\n') {
    if (source.startsWith('\uFEFF') || source.replaceAll('\r\n', '').contains('\r'))
      throw const FormatException('tmark: invalid line ending or BOM');
  }
  final String data;
  int pos = 0;
  int depth = 0;

  List<_Part> parse() {
    final parts = _parts(false);
    if (pos != data.length)
      throw FormatException('tmark: unexpected input at byte $pos');
    return parts;
  }

  _ParsedNode parseSingleNode() {
    final parts = parse();
    final node = _singleNode(parts);
    if (node == null)
      throw const FormatException('tmark: expected single node');
    return node;
  }

  List<_Part> _parts(bool stopOnBrace) {
    final parts = <_Part>[];
    final fields = <String>{};
    var contentSeen = false;
    while (pos < data.length) {
      final c = data[pos];
      if (c == '}') {
        if (!stopOnBrace)
          throw FormatException('tmark: unexpected } at byte $pos');
        pos++;
        return parts;
      }
      if (c == '{') {
        parts.add(_NodePart(_node()));
        contentSeen = true;
      } else if (c == '#') {
        final field = _field();
        if (contentSeen) throw const FormatException('tmark: named field after content');
        if (!fields.add(field.name))
          throw FormatException('tmark: duplicate field "${field.name}"');
        parts.add(_FieldPart(field));
      } else {
        final text = _text();
        if (text.isNotEmpty) {
          parts.add(_TextPart(text));
          if (!(text.trim().isEmpty && text.contains('\n'))) contentSeen = true;
        }
      }
    }
    if (stopOnBrace) throw const FormatException('tmark: missing }');
    return parts;
  }

  _ParsedNode _node() {
    final start = pos;
    if (++depth > maxDepth)
      throw StateError('tmark: max depth $maxDepth exceeded');
    try {
      pos++;
      final tagStart = pos;
      while (pos < data.length && !';{}#\\'.contains(data[pos])) {
        pos++;
      }
      if (pos < data.length && data[pos] == ';') {
        final tag = data.substring(tagStart, pos++);
        if (!_validName(tag)) throw FormatException('tmark: invalid tag "$tag"');
        final body = _parts(true);
        return _ParsedNode(tag, body, data.substring(start, pos));
      }
      pos = tagStart;
      final body = _parts(true);
      return _ParsedNode('', body, data.substring(start, pos));
    } finally {
      depth--;
    }
  }

  _ParsedField _field() {
    depth++;
    try {
      if (depth > maxDepth)
        throw StateError('tmark: max depth $maxDepth exceeded');
      pos++;
      final start = pos;
      while (pos < data.length && _isFieldNameChar(data.codeUnitAt(pos))) {
        pos++;
      }
      if (start == pos || pos >= data.length || data[pos] != '{') {
        throw FormatException('tmark: malformed field at byte ${start - 1}');
      }
      final name = data.substring(start, pos);
      if (!_validName(name)) throw FormatException('tmark: invalid field name "$name"');
      pos++;
      return _ParsedField(name, _parts(true));
    } finally {
      depth--;
    }
  }

  String _text() {
    final out = StringBuffer();
    while (pos < data.length) {
      var c = data[pos];
      if (c == '{' || c == '}' || c == '#') break;
      if (c == r'\') {
        pos++;
        if (pos >= data.length)
          throw const FormatException('tmark: trailing escape');
        c = data[pos];
        if (!'#{}\\'.contains(c))
          throw FormatException('tmark: invalid escape at byte ${pos - 1}');
      }
      out.write(c);
      pos++;
    }
    return out.toString();
  }
}

bool _isFieldNameChar(int code) =>
    code >= 97 && code <= 122 ||
    code >= 48 && code <= 57 ||
    code == 45 ||
    code == 95;

bool _validName(String name) => RegExp(r'^[a-z0-9_-]{1,32}$').hasMatch(name);
