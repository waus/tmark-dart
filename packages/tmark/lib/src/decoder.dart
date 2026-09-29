part of tmark;

final class _Decoder {
  _Decoder(this.registry, {required this.soft});
  final TmarkRegistry registry;
  final bool soft;

  T concrete<T extends TmarkValue>(_ParsedNode node, NodeType<TmarkValue> schema) {
    final body = _Parser(node.raw.substring(1, node.raw.length - 1)).parse();
    final value = schema._read(body, this, schema.layout != TmarkLayout.compact);
    if (value is! T) throw FormatException('tmark: expected $T');
    _validateNode(value);
    return value;
  }

  TmarkValue single(List<_Part> parts) {
    final clean = _dropNl(parts);
    if (clean.length == 1 && clean.first is _TextPart)
      return TText((clean.first as _TextPart).text);
    final node = _singleNode(clean);
    if (node == null)
      throw const FormatException('tmark: expected single value');
    final schema = registry._byTag[node.tag];
    if (schema == null) {
      if (soft && node.tag.isNotEmpty) return Unknown(node.raw);
      throw FormatException('tmark: unknown tag "${node.tag}"');
    }
    final value = schema._read(node.body, this, schema.layout != TmarkLayout.compact);
    _validateNode(value);
    return value;
  }
}

final class _Body {
  _Body(List<_Part> raw, {required this.expanded}) {
    final parts = expanded ? _trimNl(raw) : raw;
    for (final part in parts) {
      if (expanded && _isNl(part)) continue;
      if (part is _FieldPart) {
        if (_fields.containsKey(part.field.name)) {
          throw FormatException('tmark: duplicate field "${part.field.name}"');
        }
        _fields[part.field.name] = part.field.value;
      } else {
        unnamed.add(part);
      }
    }
  }

  final bool expanded;
  final unnamed = <_Part>[];
  final _fields = <String, List<_Part>>{};

  List<_Part>? field(String name) => _fields.remove(name);

  void done() {
    if (_fields.isNotEmpty) {
      throw FormatException('tmark: unknown field "${_fields.keys.first}"');
    }
  }
}

String _text(List<_Part> parts, {bool expanded = false}) {
  final out = StringBuffer();
  for (final part in parts) {
    if (part is! _TextPart) throw const FormatException('tmark: expected text');
    out.write(part.text);
  }
  var text = out.toString();
  if (expanded) {
    if (text.startsWith('\n')) text = text.substring(1);
    if (text.endsWith('\n')) text = text.substring(0, text.length - 1);
  }
  return text;
}

_ParsedNode? _singleNode(List<_Part> parts) {
  final clean = _dropNl(parts);
  return clean.length == 1 && clean.first is _NodePart
      ? (clean.first as _NodePart).node
      : null;
}

bool _isNl(_Part part) =>
    part is _TextPart && part.text.trim().isEmpty && part.text.contains('\n');
List<_Part> _dropNl(List<_Part> parts) =>
    parts.where((p) => !_isNl(p)).toList();
List<_Part> _trimNl(List<_Part> parts) {
  var start = 0;
  var end = parts.length;
  while (start < end && _isNl(parts[start])) start++;
  while (end > start && _isNl(parts[end - 1])) end--;
  return parts.sublist(start, end);
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
