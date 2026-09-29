part of tmark;

enum TmarkLayout { compact, expanded, whenMultiple }

/// Typed conversion shared by both directions of the wire codec.
final class FieldType<V> {
  FieldType._(
    this._read,
    this._write, {
    bool Function(V)? isEmpty,
    int Function(V)? count,
    List<String> Function(V, _Writer)? fragments,
  }) : _isEmpty = isEmpty ?? ((_) => false),
       _count = count ?? ((_) => 1),
       _fragments = fragments ?? ((value, writer) => [_write(value, writer)]);

  final V Function(List<_Part>, _Decoder, bool) _read;
  final String Function(V, _Writer) _write;
  final bool Function(V) _isEmpty;
  final int Function(V) _count;
  final List<String> Function(V, _Writer) _fragments;

  FieldType<R> mapped<R>({
    required R Function(V) decode,
    required V Function(R) encode,
  }) => FieldType._(
    (parts, decoder, expanded) => decode(_read(parts, decoder, expanded)),
    (value, writer) => _write(encode(value), writer),
    count: (value) => _count(encode(value)),
    fragments: (value, writer) => _fragments(encode(value), writer),
  );

  FieldType<V?> optional() => FieldType._(
    (parts, decoder, expanded) => _read(parts, decoder, expanded),
    (value, writer) => value == null ? '' : _write(value, writer),
    isEmpty: (value) => value == null,
    count: (value) => value == null ? 0 : _count(value),
    fragments: (value, writer) =>
        value == null ? [] : _fragments(value, writer),
  );
}

abstract final class FieldTypes {
  static final string = FieldType<String>._(
    (parts, _, expanded) => _text(parts, expanded: expanded),
    (value, _) => _escape(value),
    isEmpty: (value) => value.isEmpty,
  );
  static FieldType<V> scalar<V>({
    required V Function(String) parse,
    required String Function(V) format,
  }) => string.mapped(decode: parse, encode: format);
  static final integer = scalar<int>(
    parse: (value) {
      if (!_validInteger(value)) throw const FormatException('tmark: invalid integer');
      return int.parse(value);
    },
    format: (v) => '$v',
  );
  static final doubleValue = scalar<double>(
    parse: (value) {
      if (!_validDecimal(value)) throw const FormatException('tmark: invalid number');
      final result = double.parse(value);
      if (!result.isFinite)
        throw const FormatException('tmark: expected finite double');
      return result;
    },
    format: (value) {
      if (!value.isFinite)
        throw const FormatException('tmark: expected finite double');
      return _formatDecimal(value);
    },
  );
  static final boolean = FieldType<bool>._(
    (parts, _, _) => switch (_text(parts)) {
      't' => true,
      'f' => false,
      _ => throw const FormatException('tmark: expected t or f'),
    },
    (value, _) => value ? 't' : 'f',
    isEmpty: (value) => !value,
  );
  static FieldType<E> enumeration<E extends Enum>(List<E> values) {
    final allowed = List<E>.unmodifiable(values);
    return scalar(
      parse: (text) => allowed.firstWhere(
        (v) => v.name == text,
        orElse: () => throw FormatException('tmark: invalid $E value'),
      ),
      format: (value) => value.name,
    );
  }

  static FieldType<T> node<T extends TmarkValue>() =>
      FieldType._((parts, decoder, _) {
        final schema = decoder.registry._byType[T];
        final value = schema == null
            ? decoder.single(parts)
            : schema._read(parts, decoder, schema.layout != TmarkLayout.compact);
        if (value is! T) throw FormatException('tmark: expected $T');
        return value;
      }, (value, writer) {
        final concrete = writer.registry._byType[T] != null;
        final encoded = writer.value(value, omitTag: concrete);
        return concrete ? encoded.substring(1, encoded.length - 1) : encoded;
      });
  static FieldType<List<T>> nodes<T extends TmarkValue>() => FieldType._(
    (parts, decoder, _) => [
      for (final part in _dropNl(parts))
        if (part is _NodePart)
          decoder.registry._byType[T] == null
              ? node<T>()._read([part], decoder, false)
              : decoder.concrete<T>(part.node, decoder.registry._byType[T]!)
        else
          throw FormatException('tmark: expected $T node'),
    ],
    (values, writer) => values.map((value) => writer.value(value, omitTag: writer.registry._byType[T] != null)).join(),
    isEmpty: (values) => values.isEmpty,
    count: (values) => values.length,
    fragments: (values, writer) => values.map((value) => writer.value(value, omitTag: writer.registry._byType[T] != null)).toList(),
  );
  static final richText = FieldType<RichText>._(
    (parts, decoder, _) => [
      for (final part in parts)
        if (part is _TextPart)
          TText(part.text)
        else
          node<RichNode>()._read([part], decoder, false),
    ],
    (values, writer) => values.map(writer.value).join(),
    isEmpty: (values) => values.isEmpty,
    count: (values) => values.length,
  );
  static final blocks = nodes<BlockNode>();
  static FieldType<T> record<T>(RecordType<T> schema) => FieldType._(
    (parts, decoder, expanded) => schema._read(parts, decoder, expanded),
    (value, writer) => schema._write(value, writer, TmarkLayout.compact),
  );
}

bool _validDecimal(String value) =>
    value != '-0' && RegExp(r'^-?(0|[1-9][0-9]*)(\.[0-9]*[1-9])?$').hasMatch(value);
bool _validInteger(String value) =>
    _validDecimal(value) && !value.contains('.');

String _formatDecimal(double value) {
  if (value == 0) return '0';
  final text = value.toString();
  final e = text.indexOf(RegExp('[eE]'));
  if (e < 0) return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  final mantissa = text.substring(0, e);
  final exponent = int.parse(text.substring(e + 1));
  final negative = mantissa.startsWith('-');
  final unsigned = negative ? mantissa.substring(1) : mantissa;
  final dot = unsigned.indexOf('.');
  final point = (dot < 0 ? unsigned.length : dot) + exponent;
  final digits = unsigned.replaceAll('.', '');
  final expanded = point <= 0
      ? '0.${List.filled(-point, '0').join()}$digits'
      : point >= digits.length
          ? '$digits${List.filled(point - digits.length, '0').join()}'
          : '${digits.substring(0, point)}.${digits.substring(point)}';
  return negative ? '-$expanded' : expanded;
}

/// A null name denotes the unnamed body. No default means a required field.
final class TmarkField<O, V> {
  TmarkField(this.name, this.type, this.get, {this.defaultValue});
  final String? name;
  final FieldType<V> type;
  final V Function(O) get;
  final V Function()? defaultValue;
  Type get valueType => V;
  bool get required => defaultValue == null;

  V _read(List<_Part>? parts, _Decoder decoder, bool expanded) {
    if (parts != null) return type._read(parts, decoder, expanded);
    final fallback = defaultValue;
    if (fallback == null) throw FormatException('tmark: missing field "$name"');
    return fallback();
  }

  List<String>? _write(O owner, _Writer writer, bool expanded) {
    final value = get(owner);
    // The unnamed body has no presence marker; empty bodies need no fragment.
    if (name == null && required && type._isEmpty(value)) return null;
    if (!required && type._isEmpty(value)) {
      if (type._write(value, writer) == type._write(defaultValue!(), writer))
        return null;
    }
    if (name != null) return writer.nested(() => [type._write(value, writer)]);
    return expanded
        ? type._fragments(value, writer)
        : [type._write(value, writer)];
  }

  int _size(O owner) => type._count(get(owner));
}

/// Field tokens preserve static types without casts in a model constructor.
final class FieldValues {
  FieldValues._(this._values);
  final Map<Object, Object?> _values;
  V get<O, V>(TmarkField<O, V> field) {
    if (!_values.containsKey(field))
      throw ArgumentError('Field does not belong to this schema');
    return _values[field] as V;
  }
}

class RecordType<T> {
  RecordType({
    required List<TmarkField<T, dynamic>> fields,
    required this.create,
  }) : fields = List.unmodifiable(fields) {
    final names = <String?>{};
    for (final field in this.fields) {
      if (field.name != null &&
          !RegExp(r'^[a-z0-9_-]{1,32}$').hasMatch(field.name!)) {
        throw ArgumentError('Invalid field name: ${field.name}');
      }
      if (!names.add(field.name))
        throw ArgumentError('Duplicate field: ${field.name}');
    }
  }
  final List<TmarkField<T, dynamic>> fields;
  final T Function(FieldValues) create;
  Type get valueType => T;

  T _read(List<_Part> parts, _Decoder decoder, bool expanded) {
    final body = _Body(parts, expanded: expanded);
    final values = <Object, Object?>{};
    for (final field in fields) {
      values[field] = field._read(
        field.name == null ? body.unnamed : body.field(field.name!),
        decoder,
        expanded && field.name == null,
      );
    }
    if (!fields.any((f) => f.name == null) &&
        _dropNl(body.unnamed).isNotEmpty) {
      throw const FormatException('tmark: unexpected unnamed content');
    }
    body.done();
    return create(FieldValues._(values));
  }

  String _write(T value, _Writer writer, TmarkLayout layout) {
    final expanded =
        layout == TmarkLayout.expanded ||
        layout == TmarkLayout.whenMultiple &&
            (fields.where((f) => f.name == null).firstOrNull?._size(value) ??
                    0) >
                1;
    final out = StringBuffer();
    for (final field in fields) {
      final fragments = field._write(value, writer, expanded);
      if (fragments == null) continue;
      if (field.name != null) {
        if (expanded) out.write('\n');
        out.write('#${field.name}{${fragments.join()}}');
      } else {
        for (final fragment in fragments) {
          if (expanded) out.write('\n');
          out.write(fragment);
        }
      }
    }
    if (expanded) out.write('\n');
    return out.toString();
  }
}

final class NodeType<T extends TmarkValue> extends RecordType<T> {
  NodeType(
    this.tag, {
    this.layout = TmarkLayout.compact,
    required super.fields,
    required super.create,
  }) {
    if (!RegExp(r'^[a-z0-9_-]{1,32}$').hasMatch(tag))
      throw ArgumentError('Invalid tag: $tag');
  }
  final String tag;
  final TmarkLayout layout;
}

/// Immutable, codec-local registration. Duplicate tags/types are rejected.
final class TmarkRegistry {
  TmarkRegistry._(
    Map<String, NodeType<TmarkValue>> tags,
    Map<Type, NodeType<TmarkValue>> types,
  ) : _byTag = Map.unmodifiable(tags),
      _byType = Map.unmodifiable(types);
  final Map<String, NodeType<TmarkValue>> _byTag;
  final Map<Type, NodeType<TmarkValue>> _byType;
  static final empty = TmarkRegistry._({}, {});
  static final standard = empty.registering(_builtInTypes());
  List<NodeType<TmarkValue>> get types => List.unmodifiable(_byTag.values);
  TmarkRegistry registering(Iterable<NodeType<TmarkValue>> types) {
    final tags = {..._byTag};
    final classes = {..._byType};
    for (final type in types) {
      if (type.valueType == TText || type.valueType == Unknown)
        throw ArgumentError('Cannot register wire primitives');
      if (tags.containsKey(type.tag) || classes.containsKey(type.valueType))
        throw ArgumentError('Duplicate tag or type: ${type.tag}');
      tags[type.tag] = type;
      classes[type.valueType] = type;
    }
    return TmarkRegistry._(tags, classes);
  }
}
