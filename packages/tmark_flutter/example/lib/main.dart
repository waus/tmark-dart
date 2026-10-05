import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:tmark/tmark.dart' as tm;
import 'package:tmark_flutter/tmark_flutter.dart';
import 'package:tmark_flutter_extra/tmark_flutter_extra.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const ExampleApp());
}

final _renderers = TmarkRenderers(
  blocks: [
    TmarkBlockRenderer<tm.Preformatted>(
      (context, node, defaults) =>
          TmarkCodeBlock(text: node.text, language: node.language),
    ),
    TmarkBlockRenderer<tm.MathBlock>(
      (context, node, defaults) =>
          TmarkMath(expression: node.expression, display: true),
    ),
    TmarkBlockRenderer<tm.AudioNode>(
      (context, node, defaults) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TmarkAudioPlayer(
            key: ValueKey(node.src),
            src: node.src,
            audioSource: (src) => AudioSource.uri(Uri.parse(src)),
          ),
          if (node.caption != null) defaults.block(context, node.caption!),
        ],
      ),
    ),
    TmarkBlockRenderer<tm.VideoNode>(
      (context, node, defaults) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TmarkVideoPlayer(
            key: ValueKey(node.src),
            node: node,
            getContent: defaults.contentLoader(context),
            videoController: (src) =>
                VideoPlayerController.networkUrl(Uri.parse(src)),
          ),
          if (node.caption != null) defaults.block(context, node.caption!),
        ],
      ),
    ),
  ],
  inline: [
    TmarkInlineRenderer<tm.Math>(
      (context, node, defaults) => WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: TmarkMath(expression: node.expression),
      ),
    ),
  ],
);

Future<void> _copyToClipboard(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('Copied')));
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'tmark examples',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      home: const ExampleHome(),
    );
  }
}

class ExampleHome extends StatefulWidget {
  const ExampleHome({super.key});

  @override
  State<ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<ExampleHome> {
  late final Future<List<tm.Document>> _examples = loadExamples();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<tm.Document>>(
      future: _examples,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('tmark examples')),
            body: const Center(child: Text('Could not load examples')),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final examples = snapshot.data!;
        return DefaultTabController(
          length: examples.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('tmark examples'),
              bottom: TabBar(
                isScrollable: true,
                tabs: [
                  for (final document in examples) Tab(text: document.title),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                for (final document in examples)
                  ExampleDocumentView(document: document),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ExampleDocumentView extends StatelessWidget {
  const ExampleDocumentView({super.key, required this.document});

  final tm.Document document;

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TmarkView(
            value: document,
            style: TmarkStyle(
              linkColor: Theme.of(context).colorScheme.primary,
              surfaceColor: Theme.of(context).colorScheme.surface,
              surfaceVariantColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              onSurfaceColor: Theme.of(context).colorScheme.onSurface,
              onSurfaceVariantColor: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant,
            ),
            actions: const TmarkActions(onCopy: _copyToClipboard),
            renderers: _renderers,
            getContent: defaultTmarkContentLoader,
          ),
        ],
      ),
    );
  }
}

const exampleBaseUrl = 'https://tmark.waus.app/examples/';

const exampleFiles = [
  'all_widgets.tmark',
  'edge_cases.tmark',
  'edge_empties.tmark',
  'inline_formatting.tmark',
  'lists_and_tasks.tmark',
  'maps_and_events.tmark',
  'math_and_code.tmark',
  'media_formats.tmark',
  'media_gallery.tmark',
  'quotes_and_details.tmark',
  'references_and_anchors.tmark',
  'tables.tmark',
];

Future<List<tm.Document>> loadExamples({http.Client? client}) async {
  final resolvedClient = client ?? http.Client();
  try {
    return await Future.wait([
      for (final name in exampleFiles) loadExample(name, resolvedClient),
    ]);
  } finally {
    if (client == null) resolvedClient.close();
  }
}

Future<tm.Document> loadExample(String name, http.Client client) async {
  final url = Uri.parse(exampleBaseUrl).resolve(name);
  final response = await client.get(url).timeout(const Duration(seconds: 30));
  if (response.statusCode != 200) {
    throw StateError('HTTP ${response.statusCode}: $url');
  }
  return tm.unmarshalDocument(utf8.decode(response.bodyBytes), soft: true);
}
