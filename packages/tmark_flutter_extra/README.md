# tmark_flutter_extra

Optional, independent widgets for [`tmark_flutter`](../tmark_flutter):

- `TmarkCodeBlock(text:, language:)` — code and syntax highlighting.
- `TmarkMath(expression:, display:)` — inline or block TeX.
- `TmarkAudioPlayer(src:, audioSource:)` — audio playback.
- `TmarkVideoPlayer(node:, getContent:, videoController:)` — video preview and playback.

Register only the widgets you need in an ordinary `TmarkView`, alongside your
own renderers:

```dart
TmarkView(
  value: document,
  renderers: TmarkRenderers(
    blocks: [
      TmarkBlockRenderer<VideoNode>(
        (context, node, defaults) => TmarkVideoPlayer(
          key: ValueKey(node.src),
          node: node,
          getContent: defaults.contentLoader(context),
          videoController: (src) => VideoPlayerController.networkUrl(Uri.parse(src)),
        ),
      ),
    ],
  ),
);
```

The application supplies media loading and can use authenticated requests,
local files, or its cache. `audioSource` accepts a synchronous or asynchronous
`AudioSource` factory. `videoController` accepts a synchronous or asynchronous
`VideoPlayerController` factory. `getContent` loads preview image bytes using
`TmarkContentLoader` from `tmark_flutter`. Inside a renderer,
`defaults.contentLoader(context)` reuses the `TmarkView` loader and cache.

Video previews load first. `loop: true` plays silently in place after the
preview; other videos open in a full-screen player when tapped. Code highlighting
loads its themes on first use; call `TmarkCodeBlock.initialize()` before
`runApp` if you prefer to preload them.
