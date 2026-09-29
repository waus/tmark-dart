part of tmark_flutter;

const _spoilerPaletteLength = 64;
const _spoilerTickDuration = Duration(milliseconds: 100);

class _SpoilerOverlay extends StatefulWidget {
  const _SpoilerOverlay({
    required this.child,
    required this.foreground,
    required this.background,
    required this.borderRadius,
    required this.cellSize,
    this.enabled = true,
  });

  final Widget child;
  final Color foreground;
  final Color background;
  final double borderRadius;
  final double cellSize;
  final bool enabled;

  @override
  State<_SpoilerOverlay> createState() => _SpoilerOverlayState();
}

class _SpoilerOverlayState extends State<_SpoilerOverlay> {
  late final ValueNotifier<int> _tick;
  late _SpoilerGridCache _gridCache;
  late List<Color> _palette;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tick = ValueNotifier<int>(0);
    _gridCache = _SpoilerGridCache(cellSize: widget.cellSize);
    _palette = _buildSpoilerPalette(
      background: widget.background,
      foreground: widget.foreground,
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _SpoilerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cellSize != widget.cellSize) {
      _gridCache = _SpoilerGridCache(cellSize: widget.cellSize);
    }
    if (oldWidget.background != widget.background ||
        oldWidget.foreground != widget.foreground) {
      _palette = _buildSpoilerPalette(
        background: widget.background,
        foreground: widget.foreground,
      );
    }
    if (oldWidget.enabled != widget.enabled) {
      _syncAnimation();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tick.dispose();
    super.dispose();
  }

  void _syncAnimation() {
    if (widget.enabled) {
      _timer ??= Timer.periodic(_spoilerTickDuration, (_) {
        _tick.value += 1;
      });
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            RepaintBoundary(child: widget.child),
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _SpoilerGridPainter(
                    tick: _tick,
                    cache: _gridCache,
                    palette: _palette,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpoilerGridCache {
  _SpoilerGridCache({required this.cellSize});

  final double cellSize;

  Size? _size;
  List<Rect> rects = const [];
  List<int> offsets = const [];

  void update(Size size) {
    if (_size == size) {
      return;
    }

    _size = size;
    final columns = (size.width / cellSize).ceil();
    final rows = (size.height / cellSize).ceil();
    final newRects = <Rect>[];
    final newOffsets = <int>[];

    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < columns; x++) {
        final left = x * cellSize;
        final top = y * cellSize;
        newRects.add(
          Rect.fromLTWH(
            left,
            top,
            math.min(cellSize, size.width - left),
            math.min(cellSize, size.height - top),
          ),
        );
        newOffsets.add(
          (_unitNoise(x * 17 + y * 31, 0) * _spoilerPaletteLength).floor(),
        );
      }
    }

    rects = newRects;
    offsets = newOffsets;
  }
}

class _SpoilerGridPainter extends CustomPainter {
  _SpoilerGridPainter({
    required ValueListenable<int> tick,
    required this.cache,
    required this.palette,
  }) : _tick = tick,
       super(repaint: tick);

  final ValueListenable<int> _tick;
  final _SpoilerGridCache cache;
  final List<Color> palette;

  @override
  void paint(Canvas canvas, Size size) {
    cache.update(size);

    final tick = _tick.value;
    final paint = Paint();
    final rects = cache.rects;
    final offsets = cache.offsets;

    for (var i = 0; i < rects.length; i++) {
      paint.color = palette[(tick + offsets[i]) & 63];
      canvas.drawRect(rects[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpoilerGridPainter oldDelegate) {
    return cache != oldDelegate.cache || palette != oldDelegate.palette;
  }
}

List<Color> _buildSpoilerPalette({
  required Color background,
  required Color foreground,
}) {
  final backgroundRgb = _rgb(background);
  final foregroundRgb = _rgb(foreground);

  return List<Color>.generate(_spoilerPaletteLength, (i) {
    return Color(
      0xff000000 | _lerpRgbPingPong(backgroundRgb, foregroundRgb, i),
    );
  }, growable: false);
}

@pragma('vm:prefer-inline')
int _lerpRgbPingPong(int a, int b, int tick, [int steps = 32]) {
  final period = steps << 1;
  var t = tick % period;
  if (t > steps) t = period - t;
  final ar = (a >> 16) & 255;
  final ag = (a >> 8) & 255;
  final ab = a & 255;
  final r = ar + ((((b >> 16) & 255) - ar) * t ~/ steps);
  final g = ag + ((((b >> 8) & 255) - ag) * t ~/ steps);
  final bl = ab + (((b & 255) - ab) * t ~/ steps);
  return (r << 16) | (g << 8) | bl;
}

int _rgb(Color color) {
  final r = (color.r * 255).round().clamp(0, 255);
  final g = (color.g * 255).round().clamp(0, 255);
  final b = (color.b * 255).round().clamp(0, 255);
  return (r << 16) | (g << 8) | b;
}

double _unitNoise(int x, int y) {
  final value = math.sin(x * 127.1 + y * 311.7) * 43758.5453;
  return value - value.floorToDouble();
}
