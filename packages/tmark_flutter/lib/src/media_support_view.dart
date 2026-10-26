part of tmark_flutter;

const _mediaCornerRadius = 0.0;

class _MediaBlock extends StatelessWidget {
  const _MediaBlock({required this.node, this.caption});

  final Object node;
  final tm.Caption? caption;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _mediaNodeView(node),
      if (caption != null) _CaptionView(caption: caption!),
    ],
  );
}

class _MediaGroup extends StatefulWidget {
  const _MediaGroup({required this.children, this.caption});

  final List<tm.GalleryNode> children;
  final tm.Caption? caption;

  @override
  State<_MediaGroup> createState() => _MediaGroupState();
}

class _MediaGroupState extends State<_MediaGroup> {
  final _ratios = <double>[];
  TmarkContentLoader? _loader;

  @override
  void initState() {
    super.initState();
    _resetRatios();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loader = _contentLoaderOf(context);
    if (_loader != loader) {
      _loader = loader;
      _resolveImageSizes();
    }
  }

  @override
  void didUpdateWidget(covariant _MediaGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameMediaList(oldWidget.children, widget.children)) {
      _resetRatios();
      _resolveImageSizes();
    }
  }

  void _resetRatios() {
    _ratios
      ..clear()
      ..addAll(_defaultRatios(widget.children));
  }

  bool _sameMediaList(List<tm.GalleryNode> a, List<tm.GalleryNode> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (_mediaKey(a[i]) != _mediaKey(b[i])) {
        return false;
      }
    }
    return true;
  }

  void _resolveImageSizes() {
    final loader = _loader;
    if (loader == null) return;
    for (var i = 0; i < widget.children.length; i++) {
      final src = _mediaRatioSrc(widget.children[i]);
      if (src == null) continue;
      _resolveImageRatio(i, src, loader);
    }
  }

  Future<void> _resolveImageRatio(
    int index,
    String src,
    TmarkContentLoader loader,
  ) async {
    try {
      final bytes = await _loadTmarkImage(src, loader);
      if (tm.detectTmarkImageFormat(bytes) == tm.TmarkImageFormat.lottie)
        return;
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final ratio = (frame.image.width / frame.image.height)
          .clamp(0.2, 5)
          .toDouble();
      frame.image.dispose();
      codec.dispose();
      if (mounted &&
          _loader == loader &&
          index < widget.children.length &&
          _mediaRatioSrc(widget.children[index]) == src &&
          (_ratios[index] - ratio).abs() >= 0.001) {
        setState(() => _ratios[index] = ratio);
      }
    } catch (_) {
      // Keep the default ratio when loading or decoding fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final spacing = 2.0;
        final layout = _GroupedMediaLayout(
          ratios: _ratios,
          maxWidth: width,
          minWidth: 96,
          spacing: spacing,
        ).layout();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: layout.height,
              child: Stack(
                children: [
                  for (var i = 0; i < widget.children.length; i++)
                    Positioned.fromRect(
                      rect: layout.tiles[i].rect,
                      child: ClipRect(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: _styleOf(context).surfaceVariantColor,
                          ),
                          child: SizedBox.expand(
                            child: _galleryNodeView(
                              context,
                              widget.children[i],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (widget.caption != null) _CaptionView(caption: widget.caption!),
          ],
        );
      },
    );
  }
}

Widget _galleryNodeView(BuildContext context, tm.GalleryNode node) =>
    switch (node) {
      tm.ImageNode() => _mediaNodeView(node),
      tm.VideoNode() => _customBlock(context, node) ?? _mediaNodeView(node),
      _ => _renderBlock(context, node),
    };

Widget _mediaNodeView(Object node) => switch (node) {
  tm.ImageNode(:final src, :final hasSpoiler) => _SpoilerMedia(
    enabled: hasSpoiler,
    imageSrc: src,
    child: _ResolvedImage(src: src),
  ),
  tm.VideoNode(:final src, :final preview, :final hasSpoiler) => _SpoilerMedia(
    enabled: hasSpoiler,
    child: _VideoMediaContent(src: src, preview: preview),
  ),
  tm.AudioNode(:final src) => TmarkMediaPlaceholder(
    kind: 'audio',
    src: src,
    error: 'Audio is not supported',
  ),
  _ => const SizedBox.shrink(),
};

class _ResolvedImage extends StatefulWidget {
  const _ResolvedImage({required this.src});

  final String src;

  @override
  State<_ResolvedImage> createState() => _ResolvedImageState();
}

class _ResolvedImageState extends State<_ResolvedImage> {
  Future<Widget>? _content;
  TmarkContentLoader? _loader;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateContent();
  }

  @override
  void didUpdateWidget(covariant _ResolvedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateContent();
  }

  void _updateContent() {
    final loader = _contentLoaderOf(context);
    if (_content != null && _loader == loader && widget.src == _src) return;
    _loader = loader;
    _src = widget.src;
    _content = _resolve(loader);
  }

  String? _src;

  Future<Widget> _resolve(TmarkContentLoader loader) async {
    final src = widget.src;
    final bytes = await _loadTmarkImage(src, loader);
    if (tm.detectTmarkImageFormat(bytes) == tm.TmarkImageFormat.lottie) {
      return Lottie.memory(
        bytes,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            TmarkMediaPlaceholder(kind: 'image', src: src, error: '$error'),
      );
    }
    return Align(
      heightFactor: 1,
      child: Image.memory(
        bytes,
        fit: BoxFit.scaleDown,
        errorBuilder: (context, error, stackTrace) =>
            TmarkMediaPlaceholder(kind: 'image', src: src, error: '$error'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _content,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return TmarkMediaPlaceholder(
            kind: 'image',
            src: widget.src,
            error: '${snapshot.error}',
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return TmarkMediaPlaceholder(kind: 'image', src: widget.src);
        }

        return snapshot.data!;
      },
    );
  }
}

class _SpoilerMedia extends StatefulWidget {
  const _SpoilerMedia({
    required this.enabled,
    required this.child,
    this.imageSrc,
  });

  final bool enabled;
  final Widget child;
  final String? imageSrc;

  @override
  State<_SpoilerMedia> createState() => _SpoilerMediaState();
}

class _SpoilerMediaState extends State<_SpoilerMedia> {
  var _revealed = false;
  TmarkContentLoader? _loader;
  _TwoColors? _colors;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loader = _contentLoaderOf(context);
    if (_loader != loader) {
      _loader = loader;
      _resolveSpoilerImageColors();
    }
  }

  @override
  void didUpdateWidget(covariant _SpoilerMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      _revealed = false;
      if (widget.enabled) _resolveSpoilerImageColors();
    }
    if (oldWidget.imageSrc != widget.imageSrc) {
      _colors = null;
      _resolveSpoilerImageColors();
    }
  }

  void _resolveSpoilerImageColors() {
    final src = widget.imageSrc;
    final loader = _loader;
    if (!widget.enabled || src == null || loader == null) {
      return;
    }
    _extractColors(src, loader);
  }

  Future<void> _extractColors(String src, TmarkContentLoader loader) async {
    try {
      final bytes = await _loadTmarkImage(src, loader);
      if (tm.detectTmarkImageFormat(bytes) == tm.TmarkImageFormat.lottie)
        return;
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      frame.image.dispose();
      codec.dispose();
      if (data != null &&
          mounted &&
          _loader == loader &&
          widget.imageSrc == src) {
        setState(
          () => _colors = _extractTwoColorsFromRgbaBytes(
            data.buffer.asUint8List(),
          ),
        );
      }
    } catch (_) {
      // Use theme colors if the image cannot be decoded.
    }
  }

  void _reveal() {
    setState(() => _revealed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _revealed) {
      return widget.child;
    }

    final style = _styleOf(context);
    final colors = _colors;
    final foreground = colors == null
        ? style.onSurfaceColor ?? const Color(0xff000000)
        : Color(0xff000000 | colors.b);
    final background = colors == null
        ? style.surfaceColor ?? const Color(0xffffffff)
        : Color(0xff000000 | colors.a);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _reveal,
      child: _SpoilerOverlay(
        foreground: foreground,
        background: background,
        borderRadius: _mediaCornerRadius,
        cellSize: 10,
        child: widget.child,
      ),
    );
  }
}

List<double> _defaultRatios(List<tm.GalleryNode> children) {
  return [
    for (var i = 0; i < children.length; i++)
      switch (children.length) {
        1 => 1.0,
        2 => 1.0,
        3 => i == 0 ? 1.6 : 1.0,
        4 => i == 0 ? 1.4 : 1.0,
        _ => children[i] is tm.VideoNode ? 16 / 9 : 1.0,
      },
  ];
}

(String, String, String)? _mediaKey(tm.GalleryNode node) => switch (node) {
  tm.ImageNode(:final src) => ('image', src, ''),
  tm.VideoNode(:final src, :final preview) => ('video', src, preview),
  _ => null,
};

String? _mediaRatioSrc(tm.GalleryNode node) => switch (node) {
  tm.ImageNode(:final src) => src,
  tm.VideoNode(:final preview) when preview.isNotEmpty => preview,
  _ => null,
};

class _GroupedMediaLayout {
  const _GroupedMediaLayout({
    required this.ratios,
    required this.maxWidth,
    required this.minWidth,
    required this.spacing,
  });

  final List<double> ratios;
  final double maxWidth;
  final double minWidth;
  final double spacing;

  int get count => ratios.length;
  double get maxHeight => maxWidth;
  double get averageRatio =>
      ratios.fold(1.0, (sum, ratio) => sum + ratio) / count;
  String get proportions => ratios
      .map(
        (ratio) => ratio > 1.2
            ? 'w'
            : ratio < 0.8
            ? 'n'
            : 'q',
      )
      .join();

  _GroupedLayoutResult layout() {
    final tiles = switch (count) {
      0 => <_GroupedTile>[],
      1 => _layoutOne(),
      2 => _layoutTwo(),
      3 => _layoutThree(),
      4 => _layoutFour(),
      _ => _layoutComplex(),
    };
    final height = tiles.fold(
      0.0,
      (value, tile) => math.max(value, tile.rect.bottom),
    );
    return _GroupedLayoutResult(tiles: tiles, height: height);
  }

  List<_GroupedTile> _layoutOne() {
    return [_tile(0, 0, maxWidth, maxWidth / ratios[0])];
  }

  List<_GroupedTile> _layoutTwo() {
    final p = proportions;
    if (p == 'ww' &&
        averageRatio > 1.4 &&
        (ratios[1] - ratios[0]).abs() < 0.2) {
      final height = math.min(
        math.min(maxWidth / ratios[0], maxWidth / ratios[1]),
        (maxHeight - spacing) / 2,
      );
      return [
        _tile(0, 0, maxWidth, height),
        _tile(0, height + spacing, maxWidth, height),
      ];
    }

    if (p == 'ww' || p == 'qq') {
      final width = (maxWidth - spacing) / 2;
      final height = math.min(
        math.min(width / ratios[0], width / ratios[1]),
        maxHeight,
      );
      return [
        _tile(0, 0, width, height),
        _tile(width + spacing, 0, width, height),
      ];
    }

    final minimalWidth = minWidth * 1.5;
    final secondWidth = math.min(
      math.max(
        0.4 * (maxWidth - spacing),
        (maxWidth - spacing) / ratios[0] / (1 / ratios[0] + 1 / ratios[1]),
      ),
      maxWidth - spacing - minimalWidth,
    );
    final firstWidth = maxWidth - secondWidth - spacing;
    final height = math.min(
      maxHeight,
      math.min(firstWidth / ratios[0], secondWidth / ratios[1]),
    );
    return [
      _tile(0, 0, firstWidth, height),
      _tile(firstWidth + spacing, 0, secondWidth, height),
    ];
  }

  List<_GroupedTile> _layoutThree() {
    if (proportions[0] == 'n') {
      final firstHeight = maxHeight;
      final thirdHeight = math.min(
        (maxHeight - spacing) / 2,
        ratios[1] * (maxWidth - spacing) / (ratios[2] + ratios[1]),
      );
      final secondHeight = firstHeight - thirdHeight - spacing;
      final rightWidth = math.max(
        minWidth,
        math.min(
          (maxWidth - spacing) / 2,
          math.min(thirdHeight * ratios[2], secondHeight * ratios[1]),
        ),
      );
      final leftWidth = math.min(
        firstHeight * ratios[0],
        maxWidth - spacing - rightWidth,
      );
      return [
        _tile(0, 0, leftWidth, firstHeight),
        _tile(leftWidth + spacing, 0, rightWidth, secondHeight),
        _tile(
          leftWidth + spacing,
          secondHeight + spacing,
          rightWidth,
          thirdHeight,
        ),
      ];
    }

    final firstHeight = math.min(
      maxWidth / ratios[0],
      (maxHeight - spacing) * 0.66,
    );
    final secondWidth = (maxWidth - spacing) / 2;
    final secondHeight = math.min(
      maxHeight - firstHeight - spacing,
      math.min(secondWidth / ratios[1], secondWidth / ratios[2]),
    );
    final thirdWidth = maxWidth - secondWidth - spacing;
    return [
      _tile(0, 0, maxWidth, firstHeight),
      _tile(0, firstHeight + spacing, secondWidth, secondHeight),
      _tile(
        secondWidth + spacing,
        firstHeight + spacing,
        thirdWidth,
        secondHeight,
      ),
    ];
  }

  List<_GroupedTile> _layoutFour() {
    if (proportions[0] == 'w') {
      final firstHeight = math.min(
        maxWidth / ratios[0],
        (maxHeight - spacing) * 0.66,
      );
      final height =
          (maxWidth - 2 * spacing) / (ratios[1] + ratios[2] + ratios[3]);
      final firstWidth = math.max(
        minWidth,
        math.min((maxWidth - 2 * spacing) * 0.4, height * ratios[1]),
      );
      final thirdWidth = math.max(
        math.max(minWidth, (maxWidth - 2 * spacing) * 0.33),
        height * ratios[3],
      );
      final secondWidth = maxWidth - firstWidth - thirdWidth - 2 * spacing;
      final rowHeight = math.min(maxHeight - firstHeight - spacing, height);
      return [
        _tile(0, 0, maxWidth, firstHeight),
        _tile(0, firstHeight + spacing, firstWidth, rowHeight),
        _tile(
          firstWidth + spacing,
          firstHeight + spacing,
          secondWidth,
          rowHeight,
        ),
        _tile(
          firstWidth + secondWidth + 2 * spacing,
          firstHeight + spacing,
          thirdWidth,
          rowHeight,
        ),
      ];
    }

    final leftWidth = math.min(
      maxHeight * ratios[0],
      (maxWidth - spacing) * 0.6,
    );
    final width =
        (maxHeight - 2 * spacing) /
        (1 / ratios[1] + 1 / ratios[2] + 1 / ratios[3]);
    final firstHeight = width / ratios[1];
    final secondHeight = width / ratios[2];
    final thirdHeight = maxHeight - firstHeight - secondHeight - 2 * spacing;
    final rightWidth = math.max(
      minWidth,
      math.min(maxWidth - leftWidth - spacing, width),
    );
    return [
      _tile(0, 0, leftWidth, maxHeight),
      _tile(leftWidth + spacing, 0, rightWidth, firstHeight),
      _tile(
        leftWidth + spacing,
        firstHeight + spacing,
        rightWidth,
        secondHeight,
      ),
      _tile(
        leftWidth + spacing,
        firstHeight + secondHeight + 2 * spacing,
        rightWidth,
        thirdHeight,
      ),
    ];
  }

  List<_GroupedTile> _layoutComplex() {
    final cropped = [
      for (final ratio in ratios)
        averageRatio > 1.1
            ? ratio.clamp(1, 2.75).toDouble()
            : ratio.clamp(0.6667, 1).toDouble(),
    ];
    final attempts = <_GroupedAttempt>[];

    void push(List<int> counts) {
      var offset = 0;
      final heights = <double>[];
      for (final count in counts) {
        final sum = cropped.skip(offset).take(count).fold(0.0, (a, b) => a + b);
        heights.add((maxWidth - (count - 1) * spacing) / sum);
        offset += count;
      }
      attempts.add(_GroupedAttempt(counts, heights));
    }

    for (var first = 1; first < count; first++) {
      final second = count - first;
      if (first <= 3 && second <= 3) push([first, second]);
    }
    for (var first = 1; first < count - 1; first++) {
      for (var second = 1; second < count - first; second++) {
        final third = count - first - second;
        if (first <= 3 &&
            second <= (averageRatio < 0.85 ? 4 : 3) &&
            third <= 3) {
          push([first, second, third]);
        }
      }
    }
    for (var first = 1; first < count - 2; first++) {
      for (var second = 1; second < count - first - 1; second++) {
        for (var third = 1; third < count - first - second; third++) {
          final fourth = count - first - second - third;
          if (first <= 3 && second <= 3 && third <= 3 && fourth <= 3) {
            push([first, second, third, fourth]);
          }
        }
      }
    }

    final best = attempts.reduce((best, current) {
      double score(_GroupedAttempt attempt) {
        final lineCount = attempt.counts.length;
        final totalHeight =
            attempt.heights.fold(0.0, (a, b) => a + b) +
            spacing * (lineCount - 1);
        final minLineHeight = attempt.heights.reduce(math.min);
        final badHeight = minLineHeight < minWidth ? 1.5 : 1.0;
        var badOrder = 1.0;
        for (var i = 1; i < lineCount; i++) {
          if (attempt.counts[i - 1] > attempt.counts[i]) {
            badOrder = 1.5;
            break;
          }
        }
        return (totalHeight - maxWidth * 4 / 3).abs() * badHeight * badOrder;
      }

      return score(current) < score(best) ? current : best;
    });

    final result = <_GroupedTile>[];
    var index = 0;
    var y = 0.0;
    for (var row = 0; row < best.counts.length; row++) {
      final columns = best.counts[row];
      final rowHeight = best.heights[row];
      var x = 0.0;
      for (var column = 0; column < columns; column++) {
        final width = column == columns - 1
            ? maxWidth - x
            : cropped[index] * rowHeight;
        result.add(_tile(x, y, width, rowHeight));
        x += width + spacing;
        index += 1;
      }
      y += rowHeight + spacing;
    }
    return result;
  }

  _GroupedTile _tile(double x, double y, double width, double height) {
    return _GroupedTile(
      Rect.fromLTWH(
        x.roundToDouble(),
        y.roundToDouble(),
        width.roundToDouble(),
        height.roundToDouble(),
      ),
    );
  }
}

class _GroupedLayoutResult {
  const _GroupedLayoutResult({required this.tiles, required this.height});

  final List<_GroupedTile> tiles;
  final double height;
}

class _GroupedTile {
  const _GroupedTile(this.rect);

  final Rect rect;
}

class _GroupedAttempt {
  const _GroupedAttempt(this.counts, this.heights);

  final List<int> counts;
  final List<double> heights;
}

class _SlideshowView extends StatefulWidget {
  const _SlideshowView({required this.children, this.caption});

  final List<tm.GalleryNode> children;
  final tm.Caption? caption;

  @override
  State<_SlideshowView> createState() => _SlideshowViewState();
}

class _SlideshowViewState extends State<_SlideshowView> {
  late final PageController _controller;
  late int _page;

  @override
  void initState() {
    super.initState();
    _page = _initialPage(widget.children.length);
    _controller = PageController(initialPage: _page);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _SlideshowView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.children.length != widget.children.length) {
      _page = _initialPage(widget.children.length);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) {
          _controller.jumpToPage(_page);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) {
      return const SizedBox.shrink();
    }

    final style = _styleOf(context);
    final canPage = widget.children.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRect(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: style.surfaceVariantColor,
                border: Border.all(
                  color: style.outlineColor ?? const Color(0xffd4d4d8),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PageView.builder(
                    controller: _controller,
                    physics: canPage
                        ? const PageScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    onPageChanged: (page) => setState(() => _page = page),
                    itemBuilder: (context, page) => SizedBox.expand(
                      child: Center(
                        child: _galleryNodeView(
                          context,
                          widget.children[_logicalIndex(page)],
                        ),
                      ),
                    ),
                  ),
                  if (canPage) ...[
                    Positioned(
                      left: 16,
                      child: _SlideshowButton(
                        icon: _TmarkIcon.back,
                        onPressed: () => _move(-1),
                      ),
                    ),
                    Positioned(
                      right: 16,
                      child: _SlideshowButton(
                        icon: _TmarkIcon.forward,
                        onPressed: () => _move(1),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      child: _SlideshowCounter(
                        index: _logicalIndex(_page),
                        count: widget.children.length,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (widget.caption != null) _CaptionView(caption: widget.caption!),
      ],
    );
  }

  int _logicalIndex(int page) => page % widget.children.length;

  int _initialPage(int count) => math.max(count, 1) * 10000;

  void _move(int delta) {
    _controller.animateToPage(
      _page + delta,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }
}

class _SlideshowButton extends StatelessWidget {
  const _SlideshowButton({required this.icon, required this.onPressed});

  final _TmarkIcon icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style = _styleOf(context);
    return _TmarkIconButton(
      icon: icon,
      size: 48,
      iconSize: 22,
      foregroundColor: const Color(0xffffffff),
      backgroundColor: style.scrimColor.withAlpha(178),
      onPressed: onPressed,
    );
  }
}

class _SlideshowCounter extends StatelessWidget {
  const _SlideshowCounter({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    final style = _styleOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.scrimColor.withAlpha(150),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          '${index + 1} / $count',
          style: style.labelSmall?.copyWith(color: const Color(0xffffffff)),
        ),
      ),
    );
  }
}

class _CaptionView extends StatelessWidget {
  const _CaptionView({required this.caption});

  final tm.Caption caption;

  @override
  Widget build(BuildContext context) {
    final style = _styleOf(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: DefaultTextStyle.merge(
        style: style.bodySmall,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (caption.text.isNotEmpty)
              _RichTextView(
                children: caption.text,
                textAlign: TextAlign.center,
              ),
            _MutedCenteredText(children: caption.credit, topPadding: 2),
          ],
        ),
      ),
    );
  }
}

class _IndentedBlock extends StatelessWidget {
  const _IndentedBlock({required this.child, required this.borderColor});

  final Widget child;
  final Color borderColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(left: 12),
    decoration: BoxDecoration(
      border: Border(left: BorderSide(color: borderColor, width: 3)),
    ),
    child: child,
  );
}

class _PullQuoteBlock extends StatelessWidget {
  const _PullQuoteBlock({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: child,
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(
        color: _styleOf(context).dividerColor ?? const Color(0xffe4e4e7),
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: child,
  );
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final onCopy = _actionsOf(context).onCopy;
    return _Panel(
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(right: onCopy == null ? 0 : 18),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                text,
                softWrap: false,
                style: _monospaceStyle(context),
              ),
            ),
          ),
          if (onCopy != null)
            Positioned(
              top: 0,
              right: 0,
              child: _TmarkIconButton(
                icon: _TmarkIcon.copy,
                size: 14,
                iconSize: 12,
                onPressed: () => onCopy(context, text),
                tooltip: 'Copy',
              ),
            ),
        ],
      ),
    );
  }
}
