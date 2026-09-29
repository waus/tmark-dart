part of tmark;

final class TmarkCodec {
  const TmarkCodec({TmarkRegistry? registry}) : _registry = registry;
  final TmarkRegistry? _registry;
  TmarkRegistry get registry => _registry ?? TmarkRegistry.standard;

  String marshal(TmarkValue value) {
    final result = _Writer(registry).value(value);
    _Parser(
      result,
    ).parse(); // Also bound aggregate nesting of raw unknown nodes.
    return result;
  }

  TmarkValue unmarshal(String data, {bool soft = false}) =>
      _Decoder(registry, soft: soft).single(_Parser(data).parse());
  Document unmarshalDocument(String data, {bool soft = false}) {
    final value = unmarshal(data, soft: soft);
    if (value is Document) return value;
    throw const FormatException('tmark: expected document node');
  }
}

String marshal(TmarkValue value) => const TmarkCodec().marshal(value);
TmarkValue unmarshal(String data, {bool soft = false}) =>
    const TmarkCodec().unmarshal(data, soft: soft);
Document unmarshalDocument(String data, {bool soft = false}) =>
    const TmarkCodec().unmarshalDocument(data, soft: soft);
