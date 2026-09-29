part of tmark_flutter;

class _RichTextView extends StatefulWidget {
  const _RichTextView({required this.children, this.textAlign});

  final tm.RichText children;
  final TextAlign? textAlign;

  @override
  State<_RichTextView> createState() => _RichTextViewState();
}

class _RichTextViewState extends State<_RichTextView> {
  final List<GestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();

    return Text.rich(
      TextSpan(children: _spans(context, widget.children)),
      textAlign: widget.textAlign ?? TextAlign.start,
    );
  }

  InlineSpan _span(
    BuildContext context,
    tm.RichNode node, {
    GestureRecognizer? recognizer,
  }) {
    if (recognizer == null) {
      final defaults = const TmarkRenderDefaults._();
      for (final renderer in _TmarkScope.of(context).renderers.inline) {
        final span = renderer.tryRender(context, node, defaults);
        if (span != null) return span;
      }
    }

    final style = DefaultTextStyle.of(context).style;
    return switch (node) {
      tm.TText(:final text) => TextSpan(text: text, recognizer: recognizer),
      tm.Link(:final href, :final children) => _styledSpan(
        context,
        children,
        style: style.copyWith(color: _styleOf(context).linkColor),
        recognizer: _linkRecognizer(href),
      ),
      tm.AnchorLink(:final children) ||
      tm.ReferenceLink(:final children) => _styledSpan(
        context,
        children,
        style: style.copyWith(color: _styleOf(context).linkColor),
        recognizer: recognizer,
      ),
      tm.Reference(:final children) => _styledSpan(
        context,
        children,
        recognizer: recognizer,
      ),
      tm.Bold(:final children) => _styledSpan(
        context,
        children,
        style: const TextStyle(fontWeight: FontWeight.w700),
        recognizer: recognizer,
      ),
      tm.Italic(:final children) => _styledSpan(
        context,
        children,
        style: const TextStyle(fontStyle: FontStyle.italic),
        recognizer: recognizer,
      ),
      tm.Marked(:final children) => _styledSpan(
        context,
        children,
        style: TextStyle(
          backgroundColor: _styleOf(context).markBackgroundColor,
        ),
        recognizer: recognizer,
      ),
      tm.Underline(:final children) => _styledSpan(
        context,
        children,
        style: const TextStyle(decoration: TextDecoration.underline),
        recognizer: recognizer,
      ),
      tm.Strikethrough(:final children) => _styledSpan(
        context,
        children,
        style: const TextStyle(decoration: TextDecoration.lineThrough),
        recognizer: recognizer,
      ),
      tm.Spoiler(:final children) => WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: _SpoilerText(children: children, style: style),
      ),
      tm.Subscript(:final children) => _scriptSpan(
        context,
        children,
        recognizer: recognizer,
        superscript: false,
      ),
      tm.Superscript(:final children) => _scriptSpan(
        context,
        children,
        recognizer: recognizer,
        superscript: true,
      ),
      tm.DateTimeNode(:final unix, :final timezone) => WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: _DateTimeText(unix: unix, timezone: timezone, style: style),
      ),
      tm.Code(:final text) => TextSpan(
        text: text,
        style: _monospaceStyle(context),
        recognizer: recognizer ?? _copyRecognizer(context, text),
        mouseCursor: _actionsOf(context).onCopy == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
      ),
      tm.Math(:final expression) => TextSpan(
        text: expression,
        style: _monospaceStyle(context),
        recognizer: recognizer,
      ),
      tm.Icon(:final src, :final alternativeText) => WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: _InlineImage(
          src: src,
          alternativeText: alternativeText,
          style: style,
        ),
      ),
      tm.Unknown(:final raw) => TextSpan(text: raw, recognizer: recognizer),
      _ => TextSpan(text: _wireFallback(context, node), recognizer: recognizer),
    };
  }

  GestureRecognizer? _linkRecognizer(String href) {
    final uri = Uri.tryParse(href);
    if (uri == null || !uri.hasScheme) {
      return null;
    }

    final recognizer = TapGestureRecognizer()
      ..onTap = () async {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      };
    _recognizers.add(recognizer);
    return recognizer;
  }

  GestureRecognizer? _copyRecognizer(BuildContext context, String text) {
    final onCopy = _actionsOf(context).onCopy;
    if (onCopy == null) return null;

    final recognizer = TapGestureRecognizer()
      ..onTap = () => onCopy(context, text);
    _recognizers.add(recognizer);
    return recognizer;
  }

  InlineSpan _scriptSpan(
    BuildContext context,
    tm.RichText children, {
    required bool superscript,
    GestureRecognizer? recognizer,
  }) {
    final parentStyle = DefaultTextStyle.of(context).style;
    final fontSize = parentStyle.fontSize ?? 14;
    final scriptStyle = parentStyle.copyWith(fontSize: fontSize * 0.75);
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Transform.translate(
        offset: Offset(0, superscript ? -fontSize * 0.35 : fontSize * 0.12),
        child: DefaultTextStyle.merge(
          style: scriptStyle,
          child: Text.rich(
            TextSpan(
              children: _spans(context, children, recognizer: recognizer),
            ),
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _spans(
    BuildContext context,
    tm.RichText children, {
    GestureRecognizer? recognizer,
  }) => [
    for (final child in children) _span(context, child, recognizer: recognizer),
  ];

  TextSpan _styledSpan(
    BuildContext context,
    tm.RichText children, {
    TextStyle? style,
    GestureRecognizer? recognizer,
  }) => TextSpan(
    style: style,
    children: _spans(context, children, recognizer: recognizer),
  );
}

class _InlineImage extends StatefulWidget {
  const _InlineImage({
    required this.src,
    required this.alternativeText,
    required this.style,
  });

  final String src;
  final String? alternativeText;
  final TextStyle style;

  @override
  State<_InlineImage> createState() => _InlineImageState();
}

class _InlineImageState extends State<_InlineImage> {
  Future<Uint8List>? _image;
  TmarkContentLoader? _loader;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateImage();
  }

  @override
  void didUpdateWidget(covariant _InlineImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateImage();
  }

  void _updateImage() {
    final loader = _contentLoaderOf(context);
    if (_image != null && _loader == loader && _src == widget.src) return;
    _loader = loader;
    _src = widget.src;
    _image = _loadTmarkImage(widget.src, loader);
  }

  String? _src;

  @override
  Widget build(BuildContext context) {
    final height =
        widget.style.fontSize ??
        DefaultTextStyle.of(context).style.fontSize ??
        14;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final image = FutureBuilder<Uint8List>(
          future: _image,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return snapshot.hasError
                  ? _InlineImageFallback(
                      text: widget.alternativeText,
                      style: widget.style,
                    )
                    : SizedBox(height: height);
            }
            if (tm.detectTmarkImageFormat(snapshot.data!) ==
                tm.TmarkImageFormat.lottie) {
              return SizedBox(
                height: height,
                child: Lottie.memory(
                  snapshot.data!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      _InlineImageFallback(
                        text: widget.alternativeText,
                        style: widget.style,
                      ),
                ),
              );
            }
            return Image.memory(
              snapshot.data!,
              height: height,
              fit: BoxFit.contain,
              semanticLabel: widget.alternativeText,
              errorBuilder: (context, error, stackTrace) =>
                  _InlineImageFallback(
                    text: widget.alternativeText,
                    style: widget.style,
                  ),
            );
          },
        );
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ClipRect(child: image),
        );
      },
    );
  }
}

class _InlineImageFallback extends StatelessWidget {
  const _InlineImageFallback({required this.text, required this.style});

  final String? text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Text(text ?? '', style: style);
}

class _DateTimeText extends StatelessWidget {
  const _DateTimeText({
    required this.unix,
    required this.timezone,
    required this.style,
  });

  final int unix;
  final String timezone;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final instant = DateTime.fromMillisecondsSinceEpoch(
      unix * 1000,
      isUtc: true,
    );
    final local = instant.toLocal();
    final source = _dateTimeInTimezone(instant, timezone);

    final formattedLocal = _formatDateTime(context, local);
    final formattedSource = _formatDateTime(context, source);
    return Semantics(
      label: '$formattedLocal. $formattedSource $timezone',
      child: Text(formattedLocal, style: style),
    );
  }
}

var _timeZonesInitialized = false;

DateTime _dateTimeInTimezone(DateTime instant, String timezone) {
  if (!_timeZonesInitialized) {
    tzdata.initializeTimeZones();
    _timeZonesInitialized = true;
  }

  try {
    return tz.TZDateTime.from(instant, tz.getLocation(timezone));
  } on Object {
    return instant.toUtc();
  }
}

String _formatDateTime(BuildContext context, DateTime value) {
  return _dateTimeFormatterOf(context)?.call(context, value) ??
      _fallbackFormatDateTime(context, value);
}

class _SpoilerText extends StatefulWidget {
  const _SpoilerText({required this.children, required this.style});

  final tm.RichText children;
  final TextStyle style;

  @override
  State<_SpoilerText> createState() => _SpoilerTextState();
}

class _SpoilerTextState extends State<_SpoilerText> {
  var _revealed = false;

  void _toggleRevealed() {
    setState(() => _revealed = !_revealed);
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.style.color ?? DefaultTextStyle.of(context).style.color;
    final style = _styleOf(context);
    final foreground =
        textColor ?? style.onSurfaceColor ?? const Color(0xff000000);
    final background =
        widget.style.backgroundColor ??
        style.scaffoldBackgroundColor ??
        const Color(0xffffffff);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleRevealed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: _SpoilerOverlay(
            enabled: !_revealed,
            foreground: foreground,
            background: background,
            borderRadius: 0,
            cellSize: 10,
            child: DefaultTextStyle.merge(
              style: widget.style,
              child: _RichTextView(children: widget.children),
            ),
          ),
        ),
      ),
    );
  }
}

class _TwoColors {
  const _TwoColors(this.a, this.b);

  final int a;
  final int b;
}

_TwoColors _extractTwoColorsFromRgbaBytes(
  List<int> bytes, {
  int pixelStride = 16,
  int alphaThreshold = 32,
}) {
  var n = 0;
  var sumR = 0;
  var sumG = 0;
  var sumB = 0;
  var sumR2 = 0;
  var sumG2 = 0;
  var sumB2 = 0;

  for (var i = 0; i + 3 < bytes.length; i += pixelStride * 4) {
    final a = bytes[i + 3];
    if (a < alphaThreshold) continue;

    final r = bytes[i];
    final g = bytes[i + 1];
    final b = bytes[i + 2];
    sumR += r;
    sumG += g;
    sumB += b;
    sumR2 += r * r;
    sumG2 += g * g;
    sumB2 += b * b;
    n++;
  }

  if (n == 0) return const _TwoColors(0x000000, 0x000000);

  final varR = sumR2 * n - sumR * sumR;
  final varG = sumG2 * n - sumG * sumG;
  final varB = sumB2 * n - sumB * sumB;

  var channel = 0;
  if (varG > varR && varG >= varB) {
    channel = 1;
  } else if (varB > varR && varB > varG) {
    channel = 2;
  }

  final hist = List<int>.filled(256, 0);
  for (var i = 0; i + 3 < bytes.length; i += pixelStride * 4) {
    final a = bytes[i + 3];
    if (a < alphaThreshold) continue;

    final v = channel == 0
        ? bytes[i]
        : channel == 1
        ? bytes[i + 1]
        : bytes[i + 2];
    hist[v]++;
  }

  final half = n >> 1;
  var acc = 0;
  var median = 0;
  for (var i = 0; i < 256; i++) {
    acc += hist[i];
    if (acc >= half) {
      median = i;
      break;
    }
  }

  var n0 = 0;
  var n1 = 0;
  var r0 = 0, g0 = 0, b0 = 0;
  var r1 = 0, g1 = 0, b1 = 0;

  for (var i = 0; i + 3 < bytes.length; i += pixelStride * 4) {
    final a = bytes[i + 3];
    if (a < alphaThreshold) continue;

    final r = bytes[i];
    final g = bytes[i + 1];
    final b = bytes[i + 2];
    final v = channel == 0
        ? r
        : channel == 1
        ? g
        : b;

    if (v <= median) {
      r0 += r;
      g0 += g;
      b0 += b;
      n0++;
    } else {
      r1 += r;
      g1 += g;
      b1 += b;
      n1++;
    }
  }

  if (n0 == 0 || n1 == 0) {
    final r = sumR ~/ n;
    final g = sumG ~/ n;
    final b = sumB ~/ n;
    final avg = (r << 16) | (g << 8) | b;
    return _TwoColors(avg, avg);
  }

  final c0 = ((r0 ~/ n0) << 16) | ((g0 ~/ n0) << 8) | (b0 ~/ n0);
  final c1 = ((r1 ~/ n1) << 16) | ((g1 ~/ n1) << 8) | (b1 ~/ n1);
  return _TwoColors(c0, c1);
}
