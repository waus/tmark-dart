import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tmark/tmark.dart' as tm;
import 'package:tmark_flutter/tmark_flutter.dart';

Widget host(tm.Table table) => Directionality(
  textDirection: TextDirection.ltr,
  child: DefaultTextStyle(
    style: const TextStyle(fontSize: 14),
    child: TmarkView(value: table),
  ),
);

void main() {
  testWidgets('table with only an empty row renders without error', (
    tester,
  ) async {
    await tester.pumpWidget(host(const tm.Table([tm.TableRow([])])));

    expect(tester.takeException(), isNull);
    expect(find.byType(Table), findsNothing);
  });

  testWidgets('empty and short rows render alongside populated rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const tm.Table([
          tm.TableRow([
            tm.Cell([tm.TText('A')]),
            tm.Cell([tm.TText('B')]),
          ]),
          tm.TableRow([]),
          tm.TableRow([
            tm.Cell([tm.TText('C')]),
          ]),
        ]),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('A', findRichText: true), findsOneWidget);
    expect(find.text('B', findRichText: true), findsOneWidget);
    expect(find.text('C', findRichText: true), findsOneWidget);
    final table = tester.widget<Table>(find.byType(Table));
    expect(table.children.map((row) => row.children.length), [2, 2, 2]);
  });
}
