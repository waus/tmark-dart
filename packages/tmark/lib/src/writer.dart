part of tmark;

String _escape(String s) =>
    s.replaceAllMapped(RegExp(r'[#{}\\]'), (m) => '\\${m[0]}');

final class _Writer {
  _Writer(this.registry);
  final TmarkRegistry registry;
  int depth = 0;

  T nested<T>(T Function() operation) {
    depth++;
    try {
      if (depth > maxDepth)
        throw StateError('tmark: max depth $maxDepth exceeded');
      return operation();
    } finally {
      depth--;
    }
  }

  String value(TmarkValue value, {bool omitTag = false}) {
    if (value is TText) return _escape(value.text);
    _validateNode(value);
    return nested(() {
      if (value is Unknown) {
        _Parser(value.raw).parseSingleNode();
        return value.raw;
      }
      final schema = registry._byType[value.runtimeType];
      if (schema == null)
        throw StateError('tmark: unregistered type ${value.runtimeType}');
      return '{${omitTag ? '' : '${schema.tag};'}${schema._write(value, this, schema.layout)}}';
    });
  }
}

void _validateNode(TmarkValue value) {
  if (value is Header && (value.size < 1 || value.size > 6))
    throw const FormatException('tmark: header size must be 1..6');
  if (value is ListItem && value.type != null &&
      !const ['a', 'A', 'i', 'I', '1', 'checkbox'].contains(value.type))
    throw const FormatException('tmark: invalid list item type');
  if (value is Collage && value.children.any((v) => v is! ImageNode && v is! VideoNode))
    throw const FormatException('tmark: invalid collage child');
  if (value is Slideshow && value.children.any((v) => v is! ImageNode && v is! VideoNode))
    throw const FormatException('tmark: invalid slideshow child');
}
