part of tmark;

/// Marks a built-in model for the repository's internal schema generator.
final class TmarkNode {
  const TmarkNode(this.tag, {this.layout = TmarkLayout.compact});
  final String tag;
  final TmarkLayout layout;
}

/// An untagged structured field value used by extension models.
final class TmarkRecord {
  const TmarkRecord();
}

/// Marks the field that contains the node's unnamed body.
final class TmarkBody {
  const TmarkBody();
}

/// Overrides a field's wire name; other named fields use their Dart names.
final class TmarkName {
  const TmarkName(this.name);
  final String name;
}

/// A top-level or static zero-argument factory returning a codec for the annotated field.
final class TmarkUsing {
  const TmarkUsing(this.codec);
  final Function codec;
}
