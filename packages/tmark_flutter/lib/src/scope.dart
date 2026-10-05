part of tmark_flutter;

class _TmarkScope extends InheritedWidget {
  const _TmarkScope({
    required this.style,
    required this.actions,
    required this.renderers,
    required this.loadContent,
    this.codec = const tm.TmarkCodec(),
    required super.child,
  });

  final TmarkStyle style;
  final TmarkActions actions;
  final TmarkRenderers renderers;
  final TmarkContentLoader loadContent;
  final tm.TmarkCodec codec;

  @override
  bool updateShouldNotify(_TmarkScope oldWidget) {
    return style != oldWidget.style ||
        actions != oldWidget.actions ||
        renderers != oldWidget.renderers ||
        loadContent != oldWidget.loadContent ||
        codec != oldWidget.codec;
  }

  static _TmarkScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_TmarkScope>();
    if (scope != null) return scope;
    return _TmarkScope(
      style: TmarkStyle.fallback(context),
      actions: const TmarkActions(),
      renderers: const TmarkRenderers(),
      loadContent: defaultTmarkContentLoader,
      child: const SizedBox.shrink(),
    );
  }
}

TmarkStyle _styleOf(BuildContext context) => _TmarkScope.of(context).style;

TmarkActions _actionsOf(BuildContext context) =>
    _TmarkScope.of(context).actions;

TmarkDateTimeFormatter? _dateTimeFormatterOf(BuildContext context) =>
    _actionsOf(context).formatDateTime;

TmarkContentLoader _contentLoaderOf(BuildContext context) =>
    _TmarkScope.of(context).loadContent;

Future<Uint8List> _loadTmarkImage(String src, TmarkContentLoader loader) async {
  final bytes = await loader(src);
  if (tm.detectTmarkImageFormat(bytes) == null) {
    throw const FormatException('Unsupported image format');
  }
  return bytes;
}

Widget _renderBlock(BuildContext context, Object node) {
  return _customBlock(context, node) ??
      const TmarkRenderDefaults._().block(context, node);
}

Widget? _customBlock(BuildContext context, Object node) {
  final defaults = const TmarkRenderDefaults._();
  final renderers = _TmarkScope.of(context).renderers;
  for (final renderer in renderers.blocks) {
    final widget = renderer.tryRender(context, node, defaults);
    if (widget != null) return widget;
  }
  return null;
}

String _fallbackFormatDateTime(BuildContext context, DateTime value) {
  final use24Hour = MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false;
  final hour = use24Hour ? value.hour : ((value.hour + 11) % 12) + 1;
  final suffix = use24Hour
      ? ''
      : value.hour < 12
      ? ' AM'
      : ' PM';
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')} '
      '${hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}$suffix';
}

String _wireFallback(BuildContext context, Object node) {
  if (node is tm.Unknown) return node.raw;
  final codec = _TmarkScope.of(context).codec;
  if (node is tm.TmarkValue &&
      codec.registry.types.any((type) => type.valueType == node.runtimeType)) {
    return codec.marshal(node);
  }
  return '$node';
}
