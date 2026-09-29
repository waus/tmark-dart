# tmark_flutter

Flutter widgets for rendering [tmark](https://tmark.waus.app/) documents.
Uses the pure Dart `tmark` package for models and serialization.

## Installation

```sh
flutter pub add tmark tmark_flutter
```

## Render a document

```dart
import 'package:flutter/widgets.dart';
import 'package:tmark/tmark.dart' as tm;
import 'package:tmark_flutter/tmark_flutter.dart';

final document = tm.Document(
  title: 'Hello',
  content: [tm.Paragraph([tm.TText('Hello world')])],
);

Widget buildDocument() => SingleChildScrollView(
  child: TmarkView(value: document),
);
```

`TmarkView` accepts a document or an individual node. It lays out document blocks
in a column; provide scrolling in the surrounding application.

Media bytes are loaded by `TmarkView`. Pass `loadContent` to handle another scheme, add authentication, or
use a cache:

```dart
TmarkView(
  value: document,
  loadContent: (src) async {
    if (src.startsWith('app:')) return appStorage.readBytes(src);
    return defaultTmarkContentLoader(src);
  },
)
```

The loader returns `Future<Uint8List>`. The view checks image and audio bytes
against the format allowlists in `tmark` before rendering them. Unsupported
content appears as a media error. Inline images and gallery images use the same
loader. Audio playback and video rendering require a `TmarkActions.getContent`
callback; it receives `(tag, src, bytes)` after loading. Audio bytes are checked
before this callback runs. Video has no format allowlist.

## Customize rendering

- `style`: override typography, colors, and decorations with `TmarkStyle`.
- `spacing`: set spacing between document blocks.
- `actions`: provide copying, date formatting, and audio/video presentation
  through `TmarkActions`.
- `renderers`: supply block and inline renderers through `TmarkRenderers`.
- `codec`: use a registry containing your application types.

Custom renderer callbacks receive `TmarkRenderDefaults` to render nested blocks
with the existing configuration. For a custom `Mention` type registered in your
codec:

```dart
TmarkView(
  value: document,
  codec: codec,
  renderers: TmarkRenderers(
    inline: [
      TmarkInlineRenderer<Mention>((context, node, defaults) {
        return TextSpan(text: '@${node.user}');
      }),
    ],
  ),
)
```

See [tmark](https://github.com/waus/tmark-dart/tree/main/packages/tmark) for custom
model registration. Nodes without matching renderers fall back to raw tmark;
`Unknown` displays its original source.


## Example

The example app is in the [source repository](https://github.com/waus/tmark-dart/tree/main/packages/tmark_flutter/example).
From that directory, run:

```sh
cd example
flutter pub get
flutter run
```

## Development

```sh
flutter pub get
flutter analyze
flutter test
```
