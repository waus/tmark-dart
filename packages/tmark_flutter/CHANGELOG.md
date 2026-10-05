## 0.3.0

- Rename `TmarkView.loadContent` to `getContent`; image and video preview bytes are cached per source.
- Replace `TmarkActions.getContent` and the `TmarkResolvedContent` types with custom block renderers for audio and video.
- Display video previews with a button that opens the video in an external application. Audio displays a placeholder by default.
- Render standalone `Caption` nodes and allow custom video renderers in galleries and slideshows.
- Update the `tmark` dependency to `^0.3.0`.

## 0.1.0

- Initial release.
