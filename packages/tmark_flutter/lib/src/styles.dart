part of tmark_flutter;

TextStyle? _headerStyle(TmarkStyle style, int size) => switch (size) {
  1 => style.displaySmall,
  2 => style.headlineMedium,
  3 => style.headlineSmall,
  4 => style.titleLarge,
  5 => style.titleMedium,
  _ => style.titleSmall,
};

TextStyle _monospaceStyle(BuildContext _) => TextStyle(
  fontFamily: switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.macOS => 'Menlo',
    TargetPlatform.windows => 'Consolas',
    TargetPlatform.linux => 'Liberation Mono',
    TargetPlatform.android || TargetPlatform.fuchsia => 'monospace',
  },
  fontFamilyFallback: const [
    'SF Mono',
    'Monaco',
    'Roboto Mono',
    'Noto Sans Mono',
    'Courier New',
    'monospace',
  ],
);
