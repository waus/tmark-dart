part of tmark_flutter;

class _BlockView extends StatelessWidget {
  const _BlockView({required this.value});

  final Object value;

  @override
  Widget build(BuildContext context) {
    final style = _styleOf(context);
    return switch (value) {
      tm.Caption caption => _CaptionView(caption: caption),
      tm.Paragraph(:final children) => _RichTextView(children: children),
      tm.Header(:final size, :final children) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: DefaultTextStyle.merge(
          style: _headerStyle(style, size),
          child: _RichTextView(children: children),
        ),
      ),
      tm.Preformatted(:final text) => _CodeBlock(text: text),
      tm.MathBlock(:final expression) => _CodeBlock(text: expression),
      tm.Anchor(:final name) => SizedBox(key: ValueKey('tmark-anchor-$name')),
      tm.Divider() => const _TmarkDivider(),
      tm.Blockquote(:final blocks, :final credit) => _IndentedBlock(
        borderColor: style.outlineColor ?? const Color(0xffd4d4d8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final block in blocks) _renderBlock(context, block),
            _MutedCenteredText(children: credit, topPadding: 8),
          ],
        ),
      ),
      tm.PullQuote(:final text, :final credit) => _PullQuoteBlock(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DefaultTextStyle.merge(
              style: style.bodyMedium?.copyWith(
                color: style.onSurfaceVariantColor,
              ),
              child: _RichTextView(children: text, textAlign: TextAlign.center),
            ),
            _MutedCenteredText(children: credit, topPadding: 8),
          ],
        ),
      ),
      tm.Collage(:final children, :final caption) => _MediaGroup(
        children: children,
        caption: caption,
      ),
      tm.ListBlock(:final items) => _listView(items),
      tm.ListItem() => _ListItemView(
        item: value as tm.ListItem,
        index: 0,
        ordered: _isOrderedItem(value as tm.ListItem),
      ),
      tm.MapBlock(:final lat, :final lon, :final zoom, :final caption) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TmarkLeafletMap(center: TmarkLatLng(lat, lon), zoom: zoom ?? 12),
            if (caption != null) _CaptionView(caption: caption),
          ],
        ),
      tm.ImageNode(:final caption) ||
      tm.VideoNode(:final caption) ||
      tm.AudioNode(
        :final caption,
      ) => _MediaBlock(node: value, caption: caption),
      tm.Slideshow(:final children, :final caption) => _SlideshowView(
        children: children,
        caption: caption,
      ),
      tm.Table() => _TableView(table: value as tm.Table),
      tm.Cell() => _CellView(cell: value as tm.Cell),
      tm.Details(:final children, :final summary, :final isOpen) =>
        _DisclosureBlock(
          initiallyExpanded: isOpen,
          summary: summary,
          children: [
            for (final block in children) _renderBlock(context, block),
          ],
        ),
      tm.Unknown(:final raw) => _Panel(child: Text(raw)),
      _ => Text(_wireFallback(context, value)),
    };
  }
}

class _MutedCenteredText extends StatelessWidget {
  const _MutedCenteredText({required this.children, required this.topPadding});

  final tm.RichText children;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    final style = _styleOf(context);
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: DefaultTextStyle.merge(
        style: style.labelSmall?.copyWith(color: style.onSurfaceVariantColor),
        child: _RichTextView(children: children, textAlign: TextAlign.center),
      ),
    );
  }
}

class _DisclosureBlock extends StatefulWidget {
  const _DisclosureBlock({
    required this.initiallyExpanded,
    required this.summary,
    required this.children,
  });

  final bool initiallyExpanded;
  final tm.RichText summary;
  final List<Widget> children;

  @override
  State<_DisclosureBlock> createState() => _DisclosureBlockState();
}

class _DisclosureBlockState extends State<_DisclosureBlock> {
  late bool _expanded = widget.initiallyExpanded;

  void _toggle() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _expanded,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      child: _TmarkIconButton(
                        icon: _TmarkIcon.chevronRight,
                        onPressed: _toggle,
                        size: 24,
                        iconSize: 14,
                        foregroundColor: style.onSurfaceVariantColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: widget.summary.isEmpty
                          ? const SizedBox(height: 24)
                          : _RichTextView(children: widget.summary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ClipRect(
          child: AnimatedAlign(
            alignment: Alignment.topLeft,
            heightFactor: _expanded ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: Container(
              margin: const EdgeInsets.only(left: 11.5),
              padding: const EdgeInsets.only(left: 15.5, top: 4),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: style.outlineColor ?? const Color(0xffd4d4d8),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.children,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
