import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tmark/tmark.dart' as tm;
import 'package:tmark_flutter_example/main.dart';
import 'package:tmark_flutter/tmark_flutter.dart';

void main() {
  test('loads all named examples from the shared URL prefix', () async {
    final requested = <Uri>[];
    final source = tm.marshal(const tm.Document(title: 'Пример', content: []));
    final client = MockClient((request) async {
      requested.add(request.url);
      return http.Response.bytes(
        utf8.encode(source),
        200,
        headers: {'content-type': 'application/octet-stream'},
      );
    });
    addTearDown(client.close);

    final examples = await loadExamples(client: client);

    expect(examples, hasLength(12));
    expect(examples.map((document) => document.title), everyElement('Пример'));
    expect(requested.map((url) => url.toString()), [
      for (final name in exampleFiles) '$exampleBaseUrl$name',
    ]);
    expect(exampleFiles, contains('media_formats.tmark'));
  });

  test('rejects an unsuccessful HTTP response', () async {
    final client = MockClient((request) async => http.Response('Missing', 404));
    addTearDown(client.close);

    await expectLater(loadExample('tables.tmark', client), throwsStateError);
  });

  test('rejects a response that is not a tmark document', () async {
    final client = MockClient(
      (request) async => http.Response('{p;Hello}', 200),
    );
    addTearDown(client.close);

    await expectLater(
      loadExample('tables.tmark', client),
      throwsFormatException,
    );
  });

  testWidgets('renders Lottie bytes through the view loader', (tester) async {
    const animation =
        '{"v":"5.7.4","fr":30,"ip":0,"op":30,'
        '"w":64,"h":64,"layers":[]}';
    final requested = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TmarkView(
            value: const tm.ImageNode(
              src: 'https://example.com/animation.json',
            ),
            getContent: (src) async {
              requested.add(src);
              return utf8.encode(animation);
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(requested, ['https://example.com/animation.json']);
  });

  testWidgets('rejects unsupported image bytes before rendering', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TmarkView(
          value: const tm.ImageNode(src: 'custom:bad'),
          getContent: (_) async => utf8.encode('{"v":"5"}'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Unsupported image format'), findsOneWidget);
  });

  testWidgets('uses the video widget inside a slideshow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExampleDocumentView(
            document: const tm.Document(
              title: 'Video',
              content: [
                tm.Slideshow([
                  tm.VideoNode(src: 'https://example.com/video.mp4'),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.byTooltip('Play video'), findsOneWidget);
    expect(find.byTooltip('Open video'), findsNothing);
  });
}
