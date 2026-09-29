import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tmark/tmark.dart' as tm;
import 'package:tmark_flutter/tmark_flutter.dart';

final class Badge extends tm.TmarkValue implements tm.RichNode {
  const Badge(this.name);
  final String name;
  static final nameField = tm.TmarkField<Badge, String>(
    null,
    tm.FieldTypes.string,
    (v) => v.name,
  );
  static final schema = tm.NodeType<Badge>(
    'badge',
    fields: [nameField],
    create: (v) => Badge(v.get(nameField)),
  );
}

final class Panel extends tm.TmarkValue implements tm.BlockNode {
  const Panel(this.children);
  final tm.RichBlocks children;
  static final content = tm.TmarkField<Panel, tm.RichBlocks>(
    null,
    tm.FieldTypes.blocks,
    (v) => v.children,
  );
  static final schema = tm.NodeType<Panel>(
    'panel',
    fields: [content],
    create: (v) => Panel(v.get(content)),
  );
}

Widget host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: DefaultTextStyle(style: const TextStyle(fontSize: 14), child: child),
);
void main() {
  final codec = tm.TmarkCodec(
    registry: tm.TmarkRegistry.standard.registering([
      Badge.schema,
      Panel.schema,
    ]),
  );
  testWidgets('application schemas render through existing widget hooks', (
    tester,
  ) async {
    final value = codec.unmarshal('{panel;{p;{badge;name}}}');
    await tester.pumpWidget(
      host(
        TmarkView(
          value: value,
          codec: codec,
          renderers: TmarkRenderers(
            blocks: [
              TmarkBlockRenderer<Panel>(
                (context, panel, defaults) => Column(
                  children: [
                    const Text('custom panel'),
                    for (final block in panel.children)
                      defaults.block(context, block),
                  ],
                ),
              ),
            ],
            inline: [
              TmarkInlineRenderer<Badge>(
                (context, badge, defaults) =>
                    TextSpan(text: 'badge: ${badge.name}'),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('custom panel'), findsOneWidget);
    expect(find.text('badge: name', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('registered types without widget overrides show wire text', (
    tester,
  ) async {
    final value = tm.Document(
      url: '',
      title: '',
      content: [
        codec.unmarshal('{panel;{p;content}}') as Panel,
        tm.Paragraph([codec.unmarshal('{badge;name}') as Badge]),
        const tm.Unknown('{future;raw}'),
      ],
    );
    await tester.pumpWidget(host(TmarkView(value: value, codec: codec)));
    expect(find.text('{panel;{p;content}}'), findsOneWidget);
    expect(find.text('{badge;name}', findRichText: true), findsOneWidget);
    expect(find.text('{future;raw}'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
