import 'package:test/test.dart';
import 'package:tmark/tmark.dart';

final class Mention extends TmarkValue implements RichNode {
  const Mention(this.user, [this.children = const []]);
  final String user;
  final RichText children;
  static final userField = TmarkField<Mention, String>(
    'user',
    FieldTypes.string,
    (v) => v.user,
  );
  static final childrenField = TmarkField<Mention, RichText>(
    null,
    FieldTypes.richText,
    (v) => v.children,
    defaultValue: () => const [],
  );
  static final schema = NodeType<Mention>(
    'mention',
    fields: [userField, childrenField],
    create: (v) => Mention(v.get(userField), v.get(childrenField)),
  );
}

final class ColorValue {
  const ColorValue(this.value);
  final String value;
  static final fieldType = FieldTypes.string.mapped<ColorValue>(
    decode: ColorValue.new,
    encode: (v) => v.value,
  );
}

final class Appearance {
  const Appearance(this.color, this.label);
  final ColorValue color;
  final String? label;
  static final colorField = TmarkField<Appearance, ColorValue>(
    'color',
    ColorValue.fieldType,
    (v) => v.color,
  );
  static final labelField = TmarkField<Appearance, String?>(
    'label',
    FieldTypes.string.optional(),
    (v) => v.label,
    defaultValue: () => null,
  );
  static final schema = RecordType<Appearance>(
    fields: [colorField, labelField],
    create: (v) => Appearance(v.get(colorField), v.get(labelField)),
  );
}

final class Callout extends TmarkValue implements BlockNode {
  const Callout(
    this.children, {
    this.appearance,
    this.enabled,
    this.priority = 0,
  });
  final RichBlocks children;
  final Appearance? appearance;
  final bool? enabled;
  final int priority;
  static final schema = () {
    final content = TmarkField<Callout, RichBlocks>(
      null,
      FieldTypes.blocks,
      (v) => v.children,
      defaultValue: () => const [],
    );
    final appearance = TmarkField<Callout, Appearance?>(
      'appearance',
      FieldTypes.record(Appearance.schema).optional(),
      (v) => v.appearance,
      defaultValue: () => null,
    );
    final enabled = TmarkField<Callout, bool?>(
      'enabled',
      FieldTypes.boolean.optional(),
      (v) => v.enabled,
      defaultValue: () => null,
    );
    final priority = TmarkField<Callout, int>(
      'priority',
      FieldTypes.integer,
      (v) => v.priority,
      defaultValue: () => 0,
    );
    return NodeType<Callout>(
      'callout',
      layout: TmarkLayout.expanded,
      fields: [appearance, enabled, priority, content],
      create: (v) => Callout(
        v.get(content),
        appearance: v.get(appearance),
        enabled: v.get(enabled),
        priority: v.get(priority),
      ),
    );
  }();
}

final class ChoiceRow extends TmarkValue implements BlockNode {
  const ChoiceRow(this.items);
  final List<Mention> items;
  static final schema = () {
    final items = TmarkField<ChoiceRow, List<Mention>>(
      null, FieldTypes.nodes<Mention>(), (v) => v.items,
      defaultValue: () => const [],
    );
    return NodeType<ChoiceRow>(
      'choice-row', fields: [items], create: (v) => ChoiceRow(v.get(items)),
    );
  }();
}

final class Choices extends TmarkValue implements BlockNode {
  const Choices(this.selected, this.rows);
  final Mention selected;
  final List<ChoiceRow> rows;
  static final schema = () {
    final selected = TmarkField<Choices, Mention>(
      'selected',
      FieldTypes.node<Mention>(),
      (v) => v.selected,
    );
    final rows = TmarkField<Choices, List<ChoiceRow>>(
      null,
      FieldTypes.nodes<ChoiceRow>(),
      (v) => v.rows,
      defaultValue: () => const [],
    );
    return NodeType<Choices>(
      'choices',
      layout: TmarkLayout.expanded,
      fields: [selected, rows],
      create: (v) => Choices(v.get(selected), v.get(rows)),
    );
  }();
}

final class Notice extends TmarkValue implements BlockNode {
  const Notice(this.title, this.enabled);
  final String title;
  final bool enabled;
  static final schema = () {
    final title = TmarkField<Notice, String>(
      'title',
      FieldTypes.string,
      (v) => v.title,
      defaultValue: () => 'default',
    );
    final enabled = TmarkField<Notice, bool>(
      'enabled',
      FieldTypes.boolean,
      (v) => v.enabled,
      defaultValue: () => true,
    );
    return NodeType<Notice>(
      'notice',
      fields: [title, enabled],
      create: (v) => Notice(v.get(title), v.get(enabled)),
    );
  }();
}

void main() {
  final codec = TmarkCodec(
    registry: TmarkRegistry.standard.registering([
      Mention.schema,
      Callout.schema,
      Choices.schema,
      ChoiceRow.schema,
      Notice.schema,
    ]),
  );
  test('external types nest inside standard documents and records', () {
    const original = Document(
      url: '',
      title: '',
      content: [
        Callout(
          [
            Paragraph([
              Mention('42', [
                Bold([TText('name')]),
              ]),
            ]),
          ],
          appearance: Appearance(ColorValue('red'), ''),
          enabled: false,
          priority: 2,
        ),
      ],
    );
    final wire = codec.marshal(original);
    final decoded = codec.unmarshalDocument(wire);
    final block = decoded.content.single as Callout;
    expect(block.appearance!.color.value, 'red');
    expect(block.appearance!.label, '');
    expect(block.enabled, false);
    expect(block.priority, 2);
    expect(
      ((block.children.single as Paragraph).children.single as Mention).user,
      '42',
    );
    expect(codec.marshal(decoded), wire);
  });
  test('registry isolation and soft unknown roundtrip', () {
    const wire = '{mention;#user{42}hello}';
    expect(codec.unmarshal(wire), isA<Mention>());
    expect(() => unmarshal(wire), throwsFormatException);
    expect((unmarshal(wire, soft: true) as Unknown).raw, wire);
    expect(() => marshal(const Mention('42')), throwsStateError);
    expect(
      codec.marshal(codec.unmarshal('{future;#data{x}y}', soft: true)),
      '{future;#data{x}y}',
    );
  });
  test('malformed fields and wrong categories rejected even in soft mode', () {
    for (final wire in [
      '{mention;text}',
      '{mention;#user{x}#user{y}}',
      '{mention;#user{x}#extra{y}}',
      '{mention;#user{x}{p;block}}',
      '{callout;#priority{bad}}',
      '{callout;#enabled{yes}}',
      '{callout;#appearance{#color{{p;invalid}}}}',
      '{choices;#selected{{p;wrong}}}',
      '{choices;#selected{{mention;#user{x}}}{{p;wrong}}}',
    ]) {
      expect(
        () => codec.unmarshal(wire, soft: true),
        throwsFormatException,
        reason: wire,
      );
    }
  });
  test('typed nodes and rows roundtrip', () {
    const value = Choices(Mention('a'), [
      ChoiceRow([Mention('b'), Mention('c')]),
      ChoiceRow([]),
    ]);
    final wire = codec.marshal(value);
    final decoded = codec.unmarshal(wire) as Choices;
    expect(decoded.selected.user, 'a');
    expect(
      decoded.rows.map((row) => row.items.map((v) => v.user).toList()).toList(),
      [
        ['b', 'c'],
        [],
      ],
    );
    expect(codec.marshal(decoded), wire);
  });
  test('conflicts and invalid schemas rejected', () {
    expect(
      () => codec.registry.registering([Mention.schema]),
      throwsArgumentError,
    );
    expect(
      () => codec.registry.registering([
        NodeType<Mention>(
          'other',
          fields: [],
          create: (_) => const Mention(''),
        ),
      ]),
      throwsArgumentError,
    );
    expect(
      () => TmarkRegistry.standard.registering([
        NodeType<Mention>('p', fields: [], create: (_) => const Mention('')),
      ]),
      throwsArgumentError,
    );
    for (final tag in ['', 'bad;tag', 'bad tag']) {
      expect(
        () => NodeType<Mention>(
          tag,
          fields: [],
          create: (_) => const Mention(''),
        ),
        throwsArgumentError,
      );
    }
    expect(
      () => NodeType<Mention>(
        'bad',
        fields: [Mention.userField, Mention.userField],
        create: (_) => const Mention(''),
      ),
      throwsArgumentError,
    );
    expect(
      () => NodeType<Mention>(
        'bad',
        fields: [
          TmarkField<Mention, String>(
            'bad field',
            FieldTypes.string,
            (v) => v.user,
          ),
        ],
        create: (_) => const Mention(''),
      ),
      throwsArgumentError,
    );
    expect(() => Mention.schema.fields.clear(), throwsUnsupportedError);
    expect(() => codec.registry.types.clear(), throwsUnsupportedError);
  });
  test('defaults preserve explicit empty and false values', () {
    final defaultValue = codec.unmarshal('{notice;}') as Notice;
    expect(defaultValue.title, 'default');
    expect(defaultValue.enabled, true);
    final wire = codec.marshal(const Notice('', false));
    expect(wire, '{notice;#title{}#enabled{f}}');
    final decoded = codec.unmarshal(wire) as Notice;
    expect(decoded.title, '');
    expect(decoded.enabled, false);
    expect(() => codec.unmarshal('{notice;unexpected}'), throwsFormatException);
  });
  test('field and raw nesting limits', () {
    final raw = '${'{future;' * 16}${'}' * 16}';
    expect(marshal(Unknown(raw)), raw);
    expect(() => marshal(Paragraph([Unknown(raw)])), throwsStateError);
    final fields = '{future;${'#f{' * 16}${'}' * 17}';
    expect(() => unmarshal(fields, soft: true), throwsStateError);
  });
}
