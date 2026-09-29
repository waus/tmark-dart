part of tmark_flutter;

typedef TmarkTileUrlBuilder = String Function(TmarkTileCoord tile);

String tmarkOpenStreetMapTileUrl(TmarkTileCoord tile) =>
    'https://tile.openstreetmap.org/${tile.z}/${tile.x}/${tile.y}.png';

const tmarkOpenStreetMapTileHeaders = <String, String>{
  'User-Agent': 'tmark_flutter/0.1.0',
};

class TmarkLeafletMap extends StatefulWidget {
  const TmarkLeafletMap({
    super.key,
    required this.center,
    this.zoom = 13,
    this.minZoom = 1,
    this.maxZoom = 19,
    this.height = 260,
    this.tileUrlBuilder = tmarkOpenStreetMapTileUrl,
    this.tileHeaders = tmarkOpenStreetMapTileHeaders,
    this.marker,
    this.attribution = '(c) OpenStreetMap',
  });

  final TmarkLatLng center;
  final int zoom;
  final int minZoom;
  final int maxZoom;
  final double height;
  final TmarkTileUrlBuilder tileUrlBuilder;
  final Map<String, String>? tileHeaders;
  final Widget? marker;
  final String attribution;

  @override
  State<TmarkLeafletMap> createState() => _TmarkLeafletMapState();
}

class _TmarkLeafletMapState extends State<TmarkLeafletMap> {
  static const _projection = _LeafletProjection();

  late final TransformationController _controller;
  late int _zoom;

  @override
  void initState() {
    super.initState();
    _zoom = widget.zoom.clamp(widget.minZoom, widget.maxZoom);
    _controller = TransformationController();
  }

  @override
  void didUpdateWidget(covariant TmarkLeafletMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zoom != widget.zoom ||
        oldWidget.minZoom != widget.minZoom ||
        oldWidget.maxZoom != widget.maxZoom) {
      _zoom = widget.zoom.clamp(widget.minZoom, widget.maxZoom);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleOf(context);
    final useBrowserImages =
        kIsWeb &&
        (widget.tileHeaders == null ||
            identical(widget.tileHeaders, tmarkOpenStreetMapTileHeaders));
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.surfaceVariantColor,
          border: Border.all(
            color: style.outlineColor ?? const Color(0xffd4d4d8),
          ),
        ),
        child: SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewport = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              final center = _projection.project(widget.center, _zoom);
              final topLeft = Offset(
                center.dx - viewport.width / 2,
                center.dy - viewport.height / 2,
              );
              return Stack(
                children: [
                  InteractiveViewer(
                    transformationController: _controller,
                    constrained: false,
                    minScale: 1,
                    maxScale: 4,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    child: SizedBox(
                      width: viewport.width,
                      height: viewport.height,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (final tile in _visibleTiles(topLeft, viewport))
                            Positioned(
                              left: tile.x * _leafletTileSize - topLeft.dx,
                              top: tile.y * _leafletTileSize - topLeft.dy,
                              width: _leafletTileSize,
                              height: _leafletTileSize,
                              child: Image.network(
                                widget.tileUrlBuilder(tile),
                                headers: useBrowserImages
                                    ? null
                                    : widget.tileHeaders,
                                webHtmlElementStrategy: useBrowserImages
                                    ? WebHtmlElementStrategy.prefer
                                    : WebHtmlElementStrategy.never,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    ColoredBox(
                                      color:
                                          style.surfaceVariantColor ??
                                          const Color(0xfff4f4f5),
                                      child: Center(
                                        child: CustomPaint(
                                          size: const Size.square(28),
                                          painter: _TmarkIconPainter(
                                            _TmarkIcon.map,
                                            color:
                                                style.outlineColor ??
                                                const Color(0xff71717a),
                                          ),
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _TmarkMapGridPainter(
                                topLeft: topLeft,
                                color:
                                    style.outlineColor ??
                                    const Color(0xffd4d4d8),
                              ),
                            ),
                          ),
                          Positioned(
                            left: viewport.width / 2 - 14,
                            top: viewport.height / 2 - 28,
                            width: 28,
                            height: 28,
                            child: widget.marker ?? const _DefaultMapMarker(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _ZoomControls(
                      zoom: _zoom,
                      minZoom: widget.minZoom,
                      maxZoom: widget.maxZoom,
                      onChanged: (zoom) => setState(() {
                        _zoom = zoom;
                        _controller.value = Matrix4.identity();
                      }),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: (style.surfaceColor ?? const Color(0xffffffff))
                            .withAlpha(_alpha(0.86)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        child: Text(
                          widget.attribution,
                          style: style.labelSmall,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Iterable<TmarkTileCoord> _visibleTiles(Offset topLeft, Size viewport) sync* {
    final maxTile = math.pow(2, _zoom).toInt() - 1;
    final minX = (topLeft.dx / _leafletTileSize).floor().clamp(0, maxTile);
    final maxX = ((topLeft.dx + viewport.width) / _leafletTileSize)
        .ceil()
        .clamp(0, maxTile);
    final minY = (topLeft.dy / _leafletTileSize).floor().clamp(0, maxTile);
    final maxY = ((topLeft.dy + viewport.height) / _leafletTileSize)
        .ceil()
        .clamp(0, maxTile);

    for (var y = minY; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        yield TmarkTileCoord(x, y, _zoom);
      }
    }
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({
    required this.zoom,
    required this.minZoom,
    required this.maxZoom,
    required this.onChanged,
  });

  final int zoom;
  final int minZoom;
  final int maxZoom;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final style = _styleOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: (style.surfaceColor ?? const Color(0xffffffff)).withAlpha(
          _alpha(0.9),
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: _TmarkShadow.small(style.scrimColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TmarkIconButton(
            tooltip: 'Zoom in',
            icon: _TmarkIcon.add,
            onPressed: zoom >= maxZoom ? null : () => onChanged(zoom + 1),
          ),
          SizedBox(
            height: 1,
            width: 32,
            child: ColoredBox(
              color: style.dividerColor ?? const Color(0xffe4e4e7),
            ),
          ),
          _TmarkIconButton(
            tooltip: 'Zoom out',
            icon: _TmarkIcon.remove,
            onPressed: zoom <= minZoom ? null : () => onChanged(zoom - 1),
          ),
        ],
      ),
    );
  }
}

class _DefaultMapMarker extends StatelessWidget {
  const _DefaultMapMarker();

  @override
  Widget build(BuildContext context) {
    final color = _styleOf(context).errorColor ?? const Color(0xffdc2626);
    return CustomPaint(
      size: const Size.square(28),
      painter: _TmarkIconPainter(_TmarkIcon.pin, color: color),
    );
  }
}

class _TmarkMapGridPainter extends CustomPainter {
  const _TmarkMapGridPainter({required this.topLeft, required this.color});

  final Offset topLeft;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(_alpha(0.42))
      ..strokeWidth = 0.5;

    final startX = (topLeft.dx / _leafletTileSize).floor() * _leafletTileSize;
    for (var x = startX; x <= topLeft.dx + size.width; x += _leafletTileSize) {
      canvas.drawLine(
        Offset(x - topLeft.dx, 0),
        Offset(x - topLeft.dx, size.height),
        paint,
      );
    }

    final startY = (topLeft.dy / _leafletTileSize).floor() * _leafletTileSize;
    for (var y = startY; y <= topLeft.dy + size.height; y += _leafletTileSize) {
      canvas.drawLine(
        Offset(0, y - topLeft.dy),
        Offset(size.width, y - topLeft.dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TmarkMapGridPainter oldDelegate) {
    return topLeft != oldDelegate.topLeft || color != oldDelegate.color;
  }
}

int _alpha(double opacity) => (opacity * 255).round().clamp(0, 255);
