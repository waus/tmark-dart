part of tmark_flutter;

typedef TmarkCopyHandler =
    FutureOr<void> Function(BuildContext context, String text);

typedef TmarkDateTimeFormatter =
    String Function(BuildContext context, DateTime value);

/// Loads content bytes. Custom loaders may support any URI scheme.
typedef TmarkContentLoader = Future<Uint8List> Function(String src);

/// Default HTTP and HTTPS content loader.
Future<Uint8List> defaultTmarkContentLoader(
  String src, {
  http.Client? client,
}) async {
  final uri = Uri.parse(src);
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    throw UnsupportedError('Unsupported media URL scheme: ${uri.scheme}');
  }
  final resolvedClient = client ?? http.Client();
  try {
    final response = await resolvedClient
        .get(uri)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('HTTP ${response.statusCode}: $src');
    }
    return response.bodyBytes;
  } finally {
    if (client == null) resolvedClient.close();
  }
}

typedef TmarkBlockRender<T extends Object> =
    Widget Function(BuildContext context, T node, TmarkRenderDefaults defaults);

typedef TmarkInlineRender<T extends Object> =
    InlineSpan Function(
      BuildContext context,
      T node,
      TmarkRenderDefaults defaults,
    );

class TmarkActions {
  const TmarkActions({this.onCopy, this.formatDateTime});

  final TmarkCopyHandler? onCopy;
  final TmarkDateTimeFormatter? formatDateTime;
}

class TmarkBlockRenderer<T extends Object> {
  const TmarkBlockRenderer(this.render);

  final TmarkBlockRender<T> render;

  Widget? tryRender(
    BuildContext context,
    Object node,
    TmarkRenderDefaults defaults,
  ) {
    if (node is! T) return null;
    return render(context, node, defaults);
  }
}

class TmarkInlineRenderer<T extends Object> {
  const TmarkInlineRenderer(this.render);

  final TmarkInlineRender<T> render;

  InlineSpan? tryRender(
    BuildContext context,
    Object node,
    TmarkRenderDefaults defaults,
  ) {
    if (node is! T) return null;
    return render(context, node, defaults);
  }
}

class TmarkRenderers {
  const TmarkRenderers({this.blocks = const [], this.inline = const []});

  final List<TmarkBlockRenderer> blocks;
  final List<TmarkInlineRenderer> inline;
}

class TmarkRenderDefaults {
  const TmarkRenderDefaults._();

  /// The application's content loader, with TmarkView's per-source cache.
  TmarkContentLoader contentLoader(BuildContext context) =>
      _contentLoaderOf(context);

  Widget block(BuildContext context, Object node) {
    return _BlockView(value: node);
  }

  InlineSpan inline(BuildContext context, Object node) {
    return TextSpan(text: _wireFallback(context, node));
  }
}

class TmarkStyle {
  const TmarkStyle({
    this.bodyMedium,
    this.bodySmall,
    this.labelSmall,
    this.titleSmall,
    this.titleMedium,
    this.titleLarge,
    this.headlineSmall,
    this.headlineMedium,
    this.displaySmall,
    this.linkColor,
    this.markBackgroundColor,
    this.surfaceColor,
    this.surfaceVariantColor,
    this.onSurfaceColor,
    this.onSurfaceVariantColor,
    this.outlineColor,
    this.dividerColor,
    this.errorColor,
    this.scrimColor = const Color(0xff000000),
    this.scaffoldBackgroundColor,
  });

  final TextStyle? bodyMedium;
  final TextStyle? bodySmall;
  final TextStyle? labelSmall;
  final TextStyle? titleSmall;
  final TextStyle? titleMedium;
  final TextStyle? titleLarge;
  final TextStyle? headlineSmall;
  final TextStyle? headlineMedium;
  final TextStyle? displaySmall;
  final Color? linkColor;
  final Color? markBackgroundColor;
  final Color? surfaceColor;
  final Color? surfaceVariantColor;
  final Color? onSurfaceColor;
  final Color? onSurfaceVariantColor;
  final Color? outlineColor;
  final Color? dividerColor;
  final Color? errorColor;
  final Color scrimColor;
  final Color? scaffoldBackgroundColor;

  static TmarkStyle fallback(BuildContext context) {
    final brightness = MediaQuery.maybePlatformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final defaultText = DefaultTextStyle.of(context).style;
    final onSurface =
        defaultText.color ??
        (isDark ? const Color(0xfff4f4f5) : const Color(0xff18181b));
    final muted = isDark ? const Color(0xffa1a1aa) : const Color(0xff71717a);
    return TmarkStyle(
      bodyMedium: defaultText,
      bodySmall: defaultText.copyWith(
        fontSize: (defaultText.fontSize ?? 14) * 0.86,
      ),
      labelSmall: defaultText.copyWith(
        fontSize: (defaultText.fontSize ?? 14) * 0.79,
      ),
      titleSmall: defaultText.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: defaultText.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: defaultText.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: defaultText.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: defaultText.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      displaySmall: defaultText.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w600,
      ),
      linkColor: isDark ? const Color(0xff60a5fa) : const Color(0xff2563eb),
      markBackgroundColor: isDark
          ? const Color(0xff713f12)
          : const Color(0xfffef3c7),
      surfaceColor: isDark ? const Color(0xff18181b) : const Color(0xffffffff),
      surfaceVariantColor: isDark
          ? const Color(0xff27272a)
          : const Color(0xfff4f4f5),
      onSurfaceColor: onSurface,
      onSurfaceVariantColor: muted,
      outlineColor: isDark ? const Color(0xff52525b) : const Color(0xffd4d4d8),
      dividerColor: isDark ? const Color(0xff3f3f46) : const Color(0xffe4e4e7),
      errorColor: isDark ? const Color(0xfff87171) : const Color(0xffdc2626),
      scaffoldBackgroundColor: isDark
          ? const Color(0xff09090b)
          : const Color(0xffffffff),
    );
  }

  TmarkStyle merge(TmarkStyle? other) {
    if (other == null) return this;
    return TmarkStyle(
      bodyMedium: other.bodyMedium ?? bodyMedium,
      bodySmall: other.bodySmall ?? bodySmall,
      labelSmall: other.labelSmall ?? labelSmall,
      titleSmall: other.titleSmall ?? titleSmall,
      titleMedium: other.titleMedium ?? titleMedium,
      titleLarge: other.titleLarge ?? titleLarge,
      headlineSmall: other.headlineSmall ?? headlineSmall,
      headlineMedium: other.headlineMedium ?? headlineMedium,
      displaySmall: other.displaySmall ?? displaySmall,
      linkColor: other.linkColor ?? linkColor,
      markBackgroundColor: other.markBackgroundColor ?? markBackgroundColor,
      surfaceColor: other.surfaceColor ?? surfaceColor,
      surfaceVariantColor: other.surfaceVariantColor ?? surfaceVariantColor,
      onSurfaceColor: other.onSurfaceColor ?? onSurfaceColor,
      onSurfaceVariantColor:
          other.onSurfaceVariantColor ?? onSurfaceVariantColor,
      outlineColor: other.outlineColor ?? outlineColor,
      dividerColor: other.dividerColor ?? dividerColor,
      errorColor: other.errorColor ?? errorColor,
      scrimColor: other.scrimColor,
      scaffoldBackgroundColor:
          other.scaffoldBackgroundColor ?? scaffoldBackgroundColor,
    );
  }
}
