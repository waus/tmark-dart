# Tmark for Dart and Flutter

Parse, serialize, and render [tmark](https://tmark.waus.app/) documents.

| Package | Purpose |
| --- | --- |
| [tmark](packages/tmark) | Pure Dart models, parser, serializer, and extensible schemas |
| [tmark_flutter](packages/tmark_flutter) | Flutter widgets, styles, and custom renderers |

## Quick start

```dart
import 'package:tmark/tmark.dart' as tm;

final document = tm.Document(
  title: 'Hello',
  content: [tm.Paragraph([tm.TText('Hello world')])],
);
final source = tm.marshal(document);
```

For Flutter, pass a parsed document to `TmarkView`. See the package READMEs for
installation, rendering, and custom types.

## Run the example

```sh
cd packages/tmark_flutter/example
flutter pub get
flutter run
```

