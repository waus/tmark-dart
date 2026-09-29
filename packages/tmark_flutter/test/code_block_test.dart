import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tmark/tmark.dart' as tm;
import 'package:tmark_flutter/tmark_flutter.dart';

void main() {
  testWidgets('copy button fits inside an empty code block', (tester) async {
    var copied = false;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(fontSize: 14),
          child: TmarkView(
            value: const tm.Preformatted(''),
            actions: TmarkActions(
              onCopy: (context, text) {
                copied = true;
                expect(text, isEmpty);
              },
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final button = find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == 'Copy',
    );
    final stackRect = tester.getRect(find.byType(Stack));
    final buttonRect = tester.getRect(button);
    expect(buttonRect.top, greaterThanOrEqualTo(stackRect.top));
    expect(buttonRect.left, greaterThanOrEqualTo(stackRect.left));
    expect(buttonRect.bottom, lessThanOrEqualTo(stackRect.bottom));
    expect(buttonRect.right, lessThanOrEqualTo(stackRect.right));
    expect(buttonRect.size, const Size(14, 14));
    await tester.tap(button);
    expect(copied, isTrue);
  });
}
