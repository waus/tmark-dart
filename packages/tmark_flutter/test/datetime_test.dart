import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tmark/tmark.dart' as tm;
import 'package:tmark_flutter/tmark_flutter.dart';

void main() {
  testWidgets('datetime source defaults to UTC and preserves unsupported zones', (
    tester,
  ) async {
    for (final zone in ['', 'UTC', 'Europe/Moscow', 'Local', 'Unknown/Zone']) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultTextStyle(
            style: const TextStyle(fontSize: 14),
            child: TmarkView(
              value: tm.Paragraph([tm.DateTimeNode(unix: 0, timezone: zone)]),
              actions: TmarkActions(
                formatDateTime: (_, date) => '${date.hour}:${date.minute}',
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final source = switch (zone) {
        '' || 'UTC' => '0:0 UTC',
        'Europe/Moscow' => '3:0 Europe/Moscow',
        _ => '0 ($zone)',
      };
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              (widget.properties.label?.endsWith('. $source') ?? false),
        ),
        findsOneWidget,
        reason:
            'Source timezone: $zone; semantics: ${tester.widgetList<Semantics>(find.byType(Semantics)).map((widget) => widget.properties.label).toList()}',
      );
    }
  });
  testWidgets('fixed offsets and IANA zones preserve their clock and DST', (
    tester,
  ) async {
    final cases = <String, int>{
      '': 0,
      'UTC': 0,
      'GMT': 0,
      'GMT0': 0,
      'Z': 0,
      '-00:00': 0,
      '+02:30': 150,
      '-03:30': -210,
      'UTC+2': 120,
      'UTC-3:30': -210,
      'UTC+02:30': 150,
      '+23:59': 1439,
      '-23:59': -1439,
      'America/New_York': -300,
      'US/Eastern': -300,
      'Etc/GMT+2': -120,
    };
    final invalid = [
      '+2:00',
      '+0200',
      '+24:00',
      '+00:60',
      'UTC+24',
      'UTC+2:3',
      'UTC+002',
      'UTC+2:',
      'UTC+',
      'GMT+2',
      'gmt+2',
      'utc+2',
      'gmt',
      'utc',
      'z',
      'GMT+03:00',
      'utc',
      ' UTC',
      'UTC+2\n',
      '+٠٢:00',
      'Local',
      'localtime',
      'posixrules',
      'posix/UTC',
      'right/UTC',
      '/etc/localtime',
      'EST5EDT,M3.2.0,M11.1.0',
    ];
    String clock(DateTime date) =>
        '${date.year}-${date.month}-${date.day} ${date.hour}:${date.minute}';
    for (final unix in [1705320000, 1721044800]) {
      for (final zone in [...cases.keys, ...invalid]) {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: DefaultTextStyle(
              style: const TextStyle(fontSize: 14),
              child: TmarkView(
                value: tm.Paragraph([
                  tm.DateTimeNode(unix: unix, timezone: zone),
                ]),
                actions: TmarkActions(formatDateTime: (_, date) => clock(date)),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final label = zone.isEmpty ? 'UTC' : zone;
        var minutes = cases[zone];
        if (unix == 1721044800 &&
            (zone == 'America/New_York' || zone == 'US/Eastern'))
          minutes = -240;
        final source = minutes == null
            ? '$unix ($zone)'
            : '${clock(DateTime.fromMillisecondsSinceEpoch(unix * 1000, isUtc: true).add(Duration(minutes: minutes)))} $label';
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                (widget.properties.label?.endsWith('. $source') ?? false),
          ),
          findsOneWidget,
          reason: '$unix $zone',
        );
      }
    }
  });
}
