import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syntax_highlight/syntax_highlight.dart';

/// A code block with optional syntax highlighting and a copy button.
class TmarkCodeBlock extends StatefulWidget {
  const TmarkCodeBlock({super.key, required this.text, this.language});

  final String text;
  final String? language;

  static (HighlighterTheme, HighlighterTheme)? _themes;
  static Future<(HighlighterTheme, HighlighterTheme)>? _loading;

  /// Preloads highlighting themes; also called automatically by the widget.
  static Future<void> initialize() async {
    if (_themes != null) return;
    try {
      _themes = await (_loading ??= _loadThemes());
    } finally {
      _loading = null;
    }
  }

  static Future<(HighlighterTheme, HighlighterTheme)> _loadThemes() async {
    await Highlighter.initialize(_languages.toList());
    return (
      await HighlighterTheme.loadLightTheme(),
      await HighlighterTheme.loadDarkTheme(),
    );
  }

  @override
  State<TmarkCodeBlock> createState() => _TmarkCodeBlockState();
}

class _TmarkCodeBlockState extends State<TmarkCodeBlock> {
  Future<void>? _initialization;

  @override
  void initState() {
    super.initState();
    if (_canHighlight) _initialization = TmarkCodeBlock.initialize();
  }

  @override
  void didUpdateWidget(TmarkCodeBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_canHighlight && _initialization == null) {
      _initialization = TmarkCodeBlock.initialize();
    }
  }

  bool get _canHighlight => _languages.contains(widget.language);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 40),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DefaultTextStyle.merge(
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.45,
                  ),
                  child: FutureBuilder<void>(
                    future: _initialization,
                    builder: (context, snapshot) {
                      final themes = TmarkCodeBlock._themes;
                      if (!_canHighlight ||
                          themes == null ||
                          snapshot.hasError) {
                        return Text(widget.text, softWrap: false);
                      }
                      final syntaxTheme = theme.brightness == Brightness.dark
                          ? themes.$2
                          : themes.$1;
                      return Text.rich(
                        Highlighter(
                          language: widget.language!,
                          theme: syntaxTheme,
                        ).highlight(widget.text),
                        softWrap: false,
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: -6,
              right: -6,
              child: IconButton(
                icon: const Icon(Icons.copy, size: 18),
                tooltip: 'Copy',
                onPressed: () =>
                    Clipboard.setData(ClipboardData(text: widget.text)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _languages = {
  'css',
  'dart',
  'go',
  'html',
  'java',
  'javascript',
  'json',
  'kotlin',
  'python',
  'rust',
  'serverpod_protocol',
  'sql',
  'swift',
  'typescript',
  'yaml',
};
