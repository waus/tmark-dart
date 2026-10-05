import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tmark/tmark.dart' as tm;
import 'package:tmark_flutter/tmark_flutter.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

final _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
  'AAAADUlEQVQIHWP4z8DwHwAFgAI/ScL/nwAAAABJRU5ErkJggg==',
);

void main() {
  testWidgets('audio is unsupported without fetching its source', (
    tester,
  ) async {
    var loads = 0;
    await tester.pumpWidget(
      _host(
        TmarkView(
          value: const tm.AudioNode(src: 'app:audio'),
          getContent: (_) {
            loads++;
            return Future.value(_pixel);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(loads, 0);
    expect(find.textContaining('Audio is not supported'), findsOneWidget);
  });

  testWidgets('reuses downloaded bytes for the same image URL', (tester) async {
    var loads = 0;
    await tester.pumpWidget(
      _host(
        TmarkView(
          value: const tm.Document(
            title: 'Images',
            content: [
              tm.ImageNode(src: 'app:image'),
              tm.ImageNode(src: 'app:image'),
            ],
          ),
          getContent: (_) async {
            loads++;
            return _pixel;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(loads, 1);
  });

  testWidgets(
    'video preview loads without fetching the video, including loop',
    (tester) async {
      var loads = 0;
      await tester.pumpWidget(
        _host(
          TmarkView(
            value: const tm.VideoNode(
              src: 'https://example.com/video.mp4',
              preview: 'app:cover',
              loop: true,
            ),
            getContent: (src) {
              loads++;
              expect(src, 'app:cover');
              return Future.value(_pixel);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(loads, 1);
      expect(find.bySemanticsLabel('Open video'), findsOneWidget);
    },
  );

  testWidgets('video in a gallery accepts an application renderer', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        TmarkView(
          value: const tm.Slideshow([
            tm.VideoNode(src: 'https://example.com/video.mp4'),
          ]),
          renderers: TmarkRenderers(
            blocks: [
              TmarkBlockRenderer<tm.VideoNode>(
                (context, node, defaults) => const Text('App video'),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('App video'), findsOneWidget);
  });

  test('default loader accepts only HTTP URLs', () async {
    await expectLater(
      defaultTmarkContentLoader('app:icon'),
      throwsA(isA<UnsupportedError>()),
    );
  });

  test('default HTTP loader returns bytes', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'https://example.com/image.png');
      return http.Response.bytes([1, 2, 3, 4], 200);
    });
    addTearDown(client.close);

    final bytes = await defaultTmarkContentLoader(
      'https://example.com/image.png',
      client: client,
    );

    expect(bytes, [1, 2, 3, 4]);
  });
}
