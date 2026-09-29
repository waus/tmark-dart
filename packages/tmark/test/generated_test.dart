import 'package:test/test.dart';
import 'package:tmark/tmark.dart' as tm;
import 'generated_models.dart';

void main() {
  test('generated empty bodies retain canonical layout', () {
    expect(tm.marshal(const tm.Preformatted('')), '{pre;\n}');
    expect(tm.marshal(const tm.MathBlock('')), '{math-block;\n}');
    expect(tm.marshal(const tm.Blockquote([])), '{q;}');
  });
  final codec = tm.TmarkCodec(
    registry: tm.TmarkRegistry.standard.registering([
      $MentionSchema,
      $CalloutSchema,
      $ChoicesSchema,
      $ChoiceRowSchema,
    ]),
  );
  test(
    'generated external schemas: defaults, enums, records and custom codecs',
    () {
      const document = tm.Document(
        content: [
          Callout(
            [
              tm.Paragraph([
                Mention(
                  user: '42',
                  children: [
                    tm.Bold([tm.TText('name')]),
                  ],
                ),
              ]),
            ],
            appearance: Appearance(color: ColorValue('red'), label: ''),
            title: '',
            enabled: false,
            tone: Tone.loud,
          ),
        ],
      );
      final wire = codec.marshal(document);
      final decoded = codec.unmarshalDocument(wire).content.single as Callout;
      expect(decoded.title, '');
      expect(decoded.enabled, false);
      expect(decoded.tone, Tone.loud);
      expect(decoded.appearance!.label, '');
      expect(decoded.appearance!.color.value, 'red');
      final mention =
          (decoded.children.single as tm.Paragraph).children.single as Mention;
      expect(mention.user, '42');
      expect(codec.marshal(codec.unmarshalDocument(wire)), wire);
      final defaults = codec.unmarshal('{callout;}') as Callout;
      expect(defaults.title, 'default');
      expect(defaults.enabled, true);
      expect(defaults.tone, Tone.quiet);
      expect(defaults.appearance, isNull);
      expect(
        () => codec.unmarshal('{mention;missing user}'),
        throwsFormatException,
      );
      expect(
        () => codec.unmarshal('{callout;#tone{invalid}}'),
        throwsFormatException,
      );
    },
  );
  test('generated single nodes and typed rows', () {
    const value = Choices(Mention(user: 'a'), [
      ChoiceRow([Mention(user: 'b')]),
      ChoiceRow([]),
    ]);
    final wire = codec.marshal(value);
    final decoded = codec.unmarshal(wire) as Choices;
    expect(decoded.selected.user, 'a');
    expect(decoded.rows.first.items.single.user, 'b');
    expect(decoded.rows.last.items, isEmpty);
    expect(codec.marshal(decoded), wire);
    expect(
      () => codec.unmarshal('{choices;#selected{{p;wrong}}}'),
      throwsFormatException,
    );
  });
}
