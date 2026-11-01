library tmark_flutter;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:tmark/tmark.dart' as tm;
import 'package:url_launcher/url_launcher.dart';

part 'src/config.dart';
part 'src/scope.dart';
part 'src/widgets.dart';
part 'src/tmark_widgets.dart';
part 'src/block_view.dart';
part 'src/rich_text_view.dart';
part 'src/spoiler_overlay.dart';
part 'src/list_table_view.dart';
part 'src/map/leaflet_map.dart';
part 'src/map/projection.dart';
part 'src/media_support_view.dart';
part 'src/video_media_view.dart';
part 'src/styles.dart';

class TmarkView extends StatefulWidget {
  const TmarkView({
    super.key,
    required this.value,
    this.style,
    this.actions = const TmarkActions(),
    this.renderers = const TmarkRenderers(),
    this.spacing = 12,
    this.codec = const tm.TmarkCodec(),
    this.getContent = defaultTmarkContentLoader,
  });

  final tm.TmarkValue value;
  final TmarkStyle? style;
  final TmarkActions actions;
  final TmarkRenderers renderers;
  final double spacing;
  final tm.TmarkCodec codec;
  final TmarkContentLoader getContent;

  @override
  State<TmarkView> createState() => _TmarkViewState();
}

class _TmarkViewState extends State<TmarkView> {
  final _loadedContent = <String, Future<Uint8List>>{};
  late TmarkContentLoader _cachedLoader = _loadContent;

  Future<Uint8List> _loadContent(String src) =>
      _loadedContent.putIfAbsent(src, () => widget.getContent(src));

  @override
  void didUpdateWidget(covariant TmarkView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.getContent != widget.getContent ||
        oldWidget.value != widget.value) {
      _loadedContent.clear();
      _cachedLoader = _loadContent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = TmarkStyle.fallback(context).merge(widget.style);
    final value = widget.value;
    final blocks = value is tm.Document ? value.content : [value];
    return _TmarkScope(
      style: resolvedStyle,
      actions: widget.actions,
      renderers: widget.renderers,
      codec: widget.codec,
      loadContent: _cachedLoader,
      child: Builder(
        builder: (context) {
          return DefaultTextStyle.merge(
            style: resolvedStyle.bodyMedium,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < blocks.length; i++) ...[
                  _renderBlock(context, blocks[i]),
                  if (i != blocks.length - 1) SizedBox(height: widget.spacing),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
