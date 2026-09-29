# Flutter TODO
## Default Widgets

- `math|math-block`: the default renderer does not support this. An extended version exists in the example, and later tmark-extended should be created and this should be moved there.
- `pre.language`: the default renderer does not support highlighting. An extended version exists in the example, and later tmark-extended should be created and this should be moved there.
- `video`: the default renderer does not support this. An extended version exists in the example, and later tmark-extended should be created and this should be moved there.
- `audio`: the default renderer does not support this. An extended version exists in the example, and later tmark-extended should be created and this should be moved there.
- `video` `has_spoiler`: the video spoiler does not extract previews/colors.

## Links, Anchors, References
Need to figure out scrolling in general.

- `a href`: only URIs with a scheme are clickable; relative URLs, `#anchor`, local links, `mailto:`, `tel:`, and internal routes are not normalized or delegated outward.
- `anchor-link`: highlighted as a link, but does not scroll to `anchor`.
- `anchor`: creates a `Key`, but there is no registry/scroll controller API for navigation.
- `ref` / `ref-link`: `Reference.name` and `ReferenceLink.referenceName` are ignored; there is no collection/rendering of footnotes or navigation to them.
