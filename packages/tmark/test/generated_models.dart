import 'package:tmark/tmark.dart' as tm;

part 'generated_models.g.dart';

@tm.TmarkNode('mention')
final class Mention extends tm.TmarkValue implements tm.RichNode {
  const Mention({required this.user, this.children = const []});
  final String user;
  @tm.TmarkBody()
  final tm.RichText children;
}

enum Tone { quiet, loud }

final class ColorValue {
  const ColorValue(this.value);
  final String value;
}

tm.FieldType<ColorValue> colorCodec() => tm.FieldTypes.string.mapped(
  decode: ColorValue.new,
  encode: (value) => value.value,
);

@tm.TmarkRecord()
final class Appearance {
  const Appearance({required this.color, this.label});
  @tm.TmarkUsing(colorCodec)
  final ColorValue color;
  final String? label;
}

@tm.TmarkNode('callout', layout: tm.TmarkLayout.expanded)
final class Callout extends tm.TmarkValue implements tm.BlockNode {
  const Callout(
    this.children, {
    this.appearance,
    this.title = 'default',
    this.enabled = true,
    this.tone = Tone.quiet,
  });
  @tm.TmarkBody()
  final tm.RichBlocks children;
  final Appearance? appearance;
  @tm.TmarkName('label')
  final String title;
  final bool enabled;
  final Tone tone;
}

@tm.TmarkNode('choice-row')
final class ChoiceRow extends tm.TmarkValue implements tm.BlockNode {
  const ChoiceRow(this.items);
  @tm.TmarkBody()
  final List<Mention> items;
}

@tm.TmarkNode('choices', layout: tm.TmarkLayout.expanded)
final class Choices extends tm.TmarkValue implements tm.BlockNode {
  const Choices(this.selected, [this.rows = const []]);
  final Mention selected;
  @tm.TmarkBody()
  final List<ChoiceRow> rows;
}
