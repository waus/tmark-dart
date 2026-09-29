// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generated_models.dart';

// **************************************************************************
// TmarkGenerator
// **************************************************************************

final $MentionSchema = () {
  final f0 = tm.TmarkField<Mention, String>(
    "user",
    tm.FieldTypes.string,
    (v) => v.user,
  );
  final f1 = tm.TmarkField<Mention, List<tm.RichNode>>(
    null,
    tm.FieldTypes.richText,
    (v) => v.children,
    defaultValue: () => const [],
  );
  return tm.NodeType<Mention>(
    "mention",
    layout: tm.TmarkLayout.compact,
    fields: [f0, f1],
    create: (v) => Mention(user: v.get(f0), children: v.get(f1)),
  );
}();

final $AppearanceSchema = () {
  final f0 = tm.TmarkField<Appearance, ColorValue>(
    "color",
    colorCodec(),
    (v) => v.color,
  );
  final f1 = tm.TmarkField<Appearance, String?>(
    "label",
    tm.FieldTypes.string.optional(),
    (v) => v.label,
    defaultValue: () => null,
  );
  return tm.RecordType<Appearance>(
    fields: [f0, f1],
    create: (v) => Appearance(color: v.get(f0), label: v.get(f1)),
  );
}();

final $CalloutSchema = () {
  final f0 = tm.TmarkField<Callout, List<tm.BlockNode>>(
    null,
    tm.FieldTypes.nodes<tm.BlockNode>(),
    (v) => v.children,
  );
  final f1 = tm.TmarkField<Callout, Appearance?>(
    "appearance",
    tm.FieldTypes.record($AppearanceSchema).optional(),
    (v) => v.appearance,
    defaultValue: () => null,
  );
  final f2 = tm.TmarkField<Callout, String>(
    "label",
    tm.FieldTypes.string,
    (v) => v.title,
    defaultValue: () => 'default',
  );
  final f3 = tm.TmarkField<Callout, bool>(
    "enabled",
    tm.FieldTypes.boolean,
    (v) => v.enabled,
    defaultValue: () => true,
  );
  final f4 = tm.TmarkField<Callout, Tone>(
    "tone",
    tm.FieldTypes.enumeration(Tone.values),
    (v) => v.tone,
    defaultValue: () => Tone.quiet,
  );
  return tm.NodeType<Callout>(
    "callout",
    layout: tm.TmarkLayout.expanded,
    fields: [f1, f2, f3, f4, f0],
    create: (v) => Callout(
      v.get(f0),
      appearance: v.get(f1),
      title: v.get(f2),
      enabled: v.get(f3),
      tone: v.get(f4),
    ),
  );
}();

final $ChoiceRowSchema = () {
  final f0 = tm.TmarkField<ChoiceRow, List<Mention>>(
    null,
    tm.FieldTypes.nodes<Mention>(),
    (v) => v.items,
  );
  return tm.NodeType<ChoiceRow>(
    "choice-row",
    layout: tm.TmarkLayout.compact,
    fields: [f0],
    create: (v) => ChoiceRow(v.get(f0)),
  );
}();

final $ChoicesSchema = () {
  final f0 = tm.TmarkField<Choices, Mention>(
    "selected",
    tm.FieldTypes.node<Mention>(),
    (v) => v.selected,
  );
  final f1 = tm.TmarkField<Choices, List<ChoiceRow>>(
    null,
    tm.FieldTypes.nodes<ChoiceRow>(),
    (v) => v.rows,
    defaultValue: () => const [],
  );
  return tm.NodeType<Choices>(
    "choices",
    layout: tm.TmarkLayout.expanded,
    fields: [f0, f1],
    create: (v) => Choices(v.get(f0), v.get(f1)),
  );
}();
