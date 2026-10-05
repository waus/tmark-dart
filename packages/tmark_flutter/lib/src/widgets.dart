part of tmark_flutter;

class _TmarkIconButton extends StatelessWidget {
  const _TmarkIconButton({
    required this.icon,
    required this.onPressed,
    this.size = 32,
    this.iconSize = 18,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
  });

  final _TmarkIcon icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final style = _styleOf(context);
    final enabled = onPressed != null;
    final child = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(size / 2),
          ),
          child: SizedBox.square(
            dimension: size,
            child: Center(
              child: CustomPaint(
                size: Size.square(iconSize),
                painter: _TmarkIconPainter(
                  icon,
                  color:
                      (foregroundColor ??
                              style.onSurfaceColor ??
                              const Color(0xff000000))
                          .withAlpha(enabled ? 255 : 96),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: tooltip,
      child: child,
    );
  }
}

enum _TmarkIcon {
  add,
  remove,
  back,
  forward,
  copy,
  map,
  pin,
  chevronRight,
  play,
}

class _TmarkIconPainter extends CustomPainter {
  const _TmarkIconPainter(this.icon, {required this.color});

  final _TmarkIcon icon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = math.max(1.6, size.shortestSide * 0.11)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);

    switch (icon) {
      case _TmarkIcon.add:
        canvas.drawLine(
          Offset(center.dx, size.height * 0.22),
          Offset(center.dx, size.height * 0.78),
          paint,
        );
        canvas.drawLine(
          Offset(size.width * 0.22, center.dy),
          Offset(size.width * 0.78, center.dy),
          paint,
        );
      case _TmarkIcon.remove:
        canvas.drawLine(
          Offset(size.width * 0.22, center.dy),
          Offset(size.width * 0.78, center.dy),
          paint,
        );
      case _TmarkIcon.back:
        final path = Path()
          ..moveTo(size.width * 0.62, size.height * 0.2)
          ..lineTo(size.width * 0.32, center.dy)
          ..lineTo(size.width * 0.62, size.height * 0.8);
        canvas.drawPath(path, paint);
      case _TmarkIcon.forward:
        final path = Path()
          ..moveTo(size.width * 0.38, size.height * 0.2)
          ..lineTo(size.width * 0.68, center.dy)
          ..lineTo(size.width * 0.38, size.height * 0.8);
        canvas.drawPath(path, paint);
      case _TmarkIcon.chevronRight:
        final path = Path()
          ..moveTo(size.width * 0.35, size.height * 0.25)
          ..lineTo(size.width * 0.62, center.dy)
          ..lineTo(size.width * 0.35, size.height * 0.75);
        canvas.drawPath(path, paint);
      case _TmarkIcon.copy:
        _paintCopy(canvas, size, paint);
      case _TmarkIcon.play:
        final path = Path()
          ..moveTo(size.width * 0.32, size.height * 0.2)
          ..lineTo(size.width * 0.78, center.dy)
          ..lineTo(size.width * 0.32, size.height * 0.8)
          ..close();
        canvas.drawPath(path, paint..style = PaintingStyle.fill);
      case _TmarkIcon.map:
        final path = Path()
          ..moveTo(size.width * 0.16, size.height * 0.25)
          ..lineTo(size.width * 0.36, size.height * 0.15)
          ..lineTo(size.width * 0.64, size.height * 0.25)
          ..lineTo(size.width * 0.84, size.height * 0.15)
          ..lineTo(size.width * 0.84, size.height * 0.75)
          ..lineTo(size.width * 0.64, size.height * 0.85)
          ..lineTo(size.width * 0.36, size.height * 0.75)
          ..lineTo(size.width * 0.16, size.height * 0.85)
          ..close();
        canvas.drawPath(path, paint);
      case _TmarkIcon.pin:
        final fill = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(center.dx, size.height * 0.36),
          size.width * 0.22,
          fill,
        );
        final path = Path()
          ..moveTo(center.dx, size.height * 0.95)
          ..lineTo(size.width * 0.34, size.height * 0.48)
          ..lineTo(size.width * 0.66, size.height * 0.48)
          ..close();
        canvas.drawPath(path, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _TmarkIconPainter oldDelegate) {
    return icon != oldDelegate.icon || color != oldDelegate.color;
  }

  void _paintCopy(Canvas canvas, Size size, Paint paint) {
    final copyPaint = Paint()
      ..color = paint.color
      ..strokeWidth = math.max(1.25, size.shortestSide * 0.075)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final radius = size.shortestSide * 0.09;
    final backLeft = size.width * 0.20;
    final backTop = size.height * 0.16;
    final backRight = size.width * 0.66;
    final backBottom = size.height * 0.66;
    final front = RRect.fromLTRBR(
      size.width * 0.34,
      size.height * 0.28,
      size.width * 0.82,
      size.height * 0.88,
      Radius.circular(radius),
    );

    final backPath = Path()
      ..moveTo(backRight, backTop)
      ..lineTo(backLeft + radius, backTop)
      ..quadraticBezierTo(backLeft, backTop, backLeft, backTop + radius)
      ..lineTo(backLeft, backBottom);

    canvas.drawPath(backPath, copyPaint);
    canvas.drawRRect(front, copyPaint);
  }
}

class _TmarkShadow {
  static List<BoxShadow> small(Color color) => [
    BoxShadow(
      color: color.withAlpha(_alpha(0.20)),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];
}
