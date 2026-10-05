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

`getContent` loads bytes for images and video previews. The default
implementation uses HTTP(S). Replace it to handle another scheme:

```dart
TmarkView(
  value: document,
  getContent: (src) {
    if (src.startsWith('app:')) {
      return appStorage.readBytes(src);
    }
    return defaultTmarkContentLoader(src);
  },
)
```

The view caches image bytes and shares downloads when a source appears more
than once. Audio has no built-in player. Video shows its `preview` image and a
Play button that opens the video URL in an external application. Applications
can supply audio and video players through `TmarkBlockRenderer`.
The optional [`tmark_flutter_extra`](../tmark_flutter_extra) package
provides independent audio, video, math, and code widgets. Register whichever
you need with `TmarkBlockRenderer` or `TmarkInlineRenderer`.

## Customize rendering

- `style`: override typography, colors, and decorations with `TmarkStyle`.
- `spacing`: set spacing between document blocks.
- `actions`: provide copying and date formatting through `TmarkActions`.
- `getContent`: configure image and video preview loading.
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
