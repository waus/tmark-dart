# tmark

Pure Dart types, parser, and serializer for [tmark](https://tmark.waus.app/).
Works without Flutter, reflection, or runtime code generation.

## Installation

This package is being prepared for its first pub.dev release. For now, use a
local path dependency. After publication:

```sh
dart pub add tmark
```

## Parse and serialize

```dart
import 'package:tmark/tmark.dart';

final paragraph = unmarshal('{p;Hello world}');
final source = marshal(paragraph); // {p;Hello world}

final document = Document(
  title: 'Hello',
  content: [Paragraph([TText('Hello world')])],
);
final wire = marshal(document);
final parsed = unmarshalDocument(wire);
```

`unmarshal` accepts a single value. `unmarshalDocument` additionally requires a
`Document`. Invalid syntax or schema values throw `FormatException`.

Use `soft: true` to preserve unknown tags as `Unknown(raw)` instead of rejecting
them. Known nodes still undergo validation. Serialization preserves unknown raw
nodes and escapes text; it does not preserve every original spelling of known
nodes. Aggregate nesting is limited to `maxDepth` (16).

Built-in models cover all types from tmark __compatibility layer 1__. 

For Flutter rendering, use [tmark_flutter](https://github.com/waus/tmark-dart/tree/main/packages/tmark_flutter).

## Custom types

Applications can register handwritten schemas for their own node types. For
example, an inline mention node:

```dart
import 'package:tmark/tmark.dart';

final class Mention extends TmarkValue implements RichNode {
  const Mention({required this.user, this.children = const []});

  final String user;
  final RichText children;

  static final schema = () {
    final user = TmarkField<Mention, String>(
      'user', FieldTypes.string, (value) => value.user,
    );
    final children = TmarkField<Mention, RichText>(
      null, FieldTypes.richText, (value) => value.children,
      defaultValue: () => const [],
    );
    return NodeType<Mention>(
      'mention',
      fields: [user, children],
      create: (fields) => Mention(
        user: fields.get(user),
        children: fields.get(children),
      ),
    );
  }();
}

final codec = TmarkCodec(
  registry: TmarkRegistry.standard.registering([Mention.schema]),
);
final value = codec.unmarshal('{mention;#user{alice}Alice}');
final source = codec.marshal(value);
```

Registries are immutable and reject duplicate tags or model types.
`TmarkRegistry.empty` starts without built-ins; global functions use the standard
registry. For more complex schemas, use `RecordType`, `FieldTypes.scalar`,
`FieldTypes.record`, and `FieldType.mapped`.

The repository's internal generator only rebuilds the checked-in schemas of
built-in models. 

## Development

```sh
dart pub get
dart run tool/generate.dart
dart analyze
dart test
```

Generated files are included in the package. 

