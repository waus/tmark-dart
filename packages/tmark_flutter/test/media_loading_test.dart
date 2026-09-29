import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tmark/tmark.dart' as tm;
import 'package:tmark_flutter/tmark_flutter.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: DefaultTextStyle(style: const TextStyle(), child: child),
);

void main() {
  testWidgets('rejects audio before calling the presentation callback', (
    tester,
  ) async {
    var called = false;
    await tester.pumpWidget(
      _host(
        TmarkView(
          value: const tm.AudioNode(src: 'app:audio'),
          loadContent: (_) async => Uint8List.fromList([1, 2, 3]),
          actions: TmarkActions(
            getContent: (tag, src, bytes) {
              called = true;
              return const TmarkContentError('Should not render');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(called, isFalse);
    expect(find.textContaining('Unsupported audio format'), findsOneWidget);
  });

  testWidgets('passes checked audio bytes to the presentation callback', (
    tester,
  ) async {
    final bytes = Uint8List.fromList([0x66, 0x4c, 0x61, 0x43]);
    Uint8List? received;
    await tester.pumpWidget(
      _host(
        TmarkView(
          value: const tm.AudioNode(src: 'app:audio'),
          loadContent: (_) async => bytes,
          actions: TmarkActions(
            getContent: (tag, src, content) {
              expect(tag, 'audio');
              expect(src, 'app:audio');
              received = content;
              return const TmarkContentError('Ready');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(received, same(bytes));
    expect(find.textContaining('Ready'), findsOneWidget);
  });

  testWidgets(
    'inline images use the view loader and reject unsupported bytes',
    (tester) async {
      final requested = <String>[];
      await tester.pumpWidget(
        _host(
          TmarkView(
            value: const tm.Paragraph([
              tm.Icon(src: 'app:icon', alternativeText: 'Icon'),
            ]),
            loadContent: (src) async {
              requested.add(src);
              return Uint8List.fromList([1, 2, 3]);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(requested, ['app:icon']);
      expect(find.text('Icon'), findsOneWidget);
    },
  );

  test('default loader accepts only HTTP URLs', () async {
    await expectLater(
      defaultTmarkContentLoader('app:icon'),
      throwsUnsupportedError,
    );
  });
}
