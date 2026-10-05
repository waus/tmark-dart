import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_math_fork/flutter_math.dart' as fm;
import 'package:tmark/tmark.dart' as tm;
import 'package:tmark_flutter/tmark_flutter.dart';
import 'package:tmark_flutter_extra/tmark_flutter_extra.dart';

final _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
  'AAAADUlEQVQIHWP4z8DwHwAFgAI/ScL/nwAAAABJRU5ErkJggg==',
);

void main() {
  testWidgets('math and code widgets can be registered separately', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TmarkView(
            value: const tm.Document(
              title: 'Widgets',
              content: [
                tm.Preformatted('void main() {}', language: 'dart'),
                tm.MathBlock('x^2'),
              ],
            ),
            renderers: TmarkRenderers(
              blocks: [
                TmarkBlockRenderer<tm.Preformatted>(
                  (context, node, defaults) =>
                      TmarkCodeBlock(text: node.text, language: node.language),
                ),
                TmarkBlockRenderer<tm.MathBlock>(
                  (context, node, defaults) =>
                      TmarkMath(expression: node.expression, display: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.byType(fm.Math), findsOneWidget);
    expect(find.byTooltip('Copy'), findsOneWidget);
  });

  testWidgets('preview uses app loader and regular video stays deferred', (
    tester,
  ) async {
    final requested = <String>[];
    var controllers = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TmarkVideoPlayer(
            node: const tm.VideoNode(src: 'app:video', preview: 'app:preview'),
            getContent: (src) {
              requested.add(src);
              return Future.value(_pixel);
            },
            videoController: (_) {
              controllers++;
              throw UnimplementedError();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(requested, ['app:preview']);
    expect(controllers, 0);
    expect(find.byTooltip('Play video'), findsOneWidget);
  });

  testWidgets('gallery and video widget share preview bytes', (tester) async {
    var loads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TmarkView(
              value: const tm.Collage([
                tm.VideoNode(src: 'app:video', preview: 'app:preview'),
              ]),
              getContent: (src) {
                loads++;
                return Future.value(_pixel);
              },
              renderers: TmarkRenderers(
                blocks: [
                  TmarkBlockRenderer<tm.VideoNode>(
                    (context, node, defaults) => TmarkVideoPlayer(
                      node: node,
                      getContent: defaults.contentLoader(context),
                      videoController: (_) => throw UnimplementedError(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(loads, 1);
  });

  testWidgets('loop video requests an app controller after preview', (
    tester,
  ) async {
    final requested = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TmarkVideoPlayer(
            node: const tm.VideoNode(
              src: 'app:video',
              preview: 'app:preview',
              loop: true,
            ),
            getContent: (src) {
              requested.add(src);
              return Future.value(_pixel);
            },
            videoController: (src) async {
              requested.add(src);
              throw StateError('App video source');
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(requested, ['app:preview', 'app:video']);
    expect(find.textContaining('App video source'), findsOneWidget);
  });
}
