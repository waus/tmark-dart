// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tmark.dart';

// **************************************************************************
// TmarkGenerator
// **************************************************************************

final $CaptionSchema = () {
  final f0 = TmarkField<Caption, List<RichNode>>(
    "credit",
    FieldTypes.richText,
    (v) => v.credit,
    defaultValue: () => const [],
  );
  final f1 = TmarkField<Caption, List<RichNode>>(
    null,
    FieldTypes.richText,
    (v) => v.text,
    defaultValue: () => const [],
  );
  return NodeType<Caption>(
    "caption",
    layout: TmarkLayout.compact,
    fields: [f0, f1],
    create: (v) => Caption(credit: v.get(f0), text: v.get(f1)),
  );
}();

final $LinkSchema = () {
  final f0 = TmarkField<Link, String>(
    "href",
    FieldTypes.string,
    (v) => v.href,
    defaultValue: () => '',
  );
  final f1 = TmarkField<Link, List<RichNode>>(
    null,
    FieldTypes.richText,
    (v) => v.children,
    defaultValue: () => const [],
  );
  return NodeType<Link>(
    "a",
    layout: TmarkLayout.compact,
    fields: [f0, f1],
    create: (v) => Link(href: v.get(f0), children: v.get(f1)),
  );
}();

final $AnchorLinkSchema = () {
  final f0 = TmarkField<AnchorLink, String>(
    "name",
    FieldTypes.string,
    (v) => v.anchorName,
    defaultValue: () => '',
  );
  final f1 = TmarkField<AnchorLink, List<RichNode>>(
    null,
    FieldTypes.richText,
    (v) => v.children,
    defaultValue: () => const [],
  );
  return NodeType<AnchorLink>(
    "anchor-link",
    layout: TmarkLayout.compact,
    fields: [f0, f1],
    create: (v) => AnchorLink(anchorName: v.get(f0), children: v.get(f1)),
  );
}();

final $ReferenceSchema = () {
  final f0 = TmarkField<Reference, String>(
    "name",
    FieldTypes.string,
    (v) => v.name,
    defaultValue: () => '',
  );
  final f1 = TmarkField<Reference, List<RichNode>>(
    null,
    FieldTypes.richText,
    (v) => v.children,
    defaultValue: () => const [],
  );
  return NodeType<Reference>(
    "ref",
    layout: TmarkLayout.compact,
    fields: [f0, f1],
    create: (v) => Reference(name: v.get(f0), children: v.get(f1)),
  );
}();

final $ReferenceLinkSchema = () {
  final f0 = TmarkField<ReferenceLink, String>(
    "name",
    FieldTypes.string,
    (v) => v.referenceName,
    defaultValue: () => '',
  );
  final f1 = TmarkField<ReferenceLink, List<RichNode>>(
    null,
    FieldTypes.richText,
    (v) => v.children,
    defaultValue: () => const [],
  );
  return NodeType<ReferenceLink>(
    "ref-link",
    layout: TmarkLayout.compact,
    fields: [f0, f1],
    create: (v) => ReferenceLink(referenceName: v.get(f0), children: v.get(f1)),
  );
}();

final $BoldSchema = () {
  final f0 = TmarkField<Bold, List<RichNode>>(
    null,
    FieldTypes.richText,
    (v) => v.children,
  );
  return NodeType<Bold>(
    "b",
    layout: TmarkLayout.compact,
    fields: [f0],
    create: (v) => Bold(v.get(f0)),
  );
}();

final $ItalicSchema = () {
  final f0 = TmarkField<Italic, List<RichNode>>(
    null,
    FieldTypes.richText,
    (v) => v.children,
  );
  return NodeType<Italic>(
    "i",
    layout: TmarkLayout.compact,
    fields: [f0],
    create: (v) => Italic(v.get(f0)),
  );
}();

final $MarkedSchema = () {
  final f0 = TmarkField<Marked, List<RichNode>>(
    null,
    FieldTypes.richText,
    (v) => v.children,
  );
  return NodeType<Marked>(
    "m",
    layout: TmarkLayout.compact,
    fields: [f0],
    create: (v) => Marked(v.get(f0)),
  );
}();

final $UnderlineSchema = () {
  final f0 = TmarkField<Underline, List<RichNode>>(
    null,
    FieldTypes.richText,
    (v) => v.children,
  );
  return NodeType<Underline>(
    "u",
    layout: TmarkLayout.compact,
    fields: [f0],
    create: (v) => Underline(v.get(f0)),
  );
}();

final $StrikethroughSchema = () {
  final f0 = TmarkField<Strikethrough, List<RichNode>>(
    null,
    FieldTypes.richText,
    (v) => v.children,
  );
  return NodeType<Strikethrough>(
    "s",
    layout: TmarkLayout.compact,
    fields: [f0],
    create: (v) => Strikethrough(v.get(f0)),
  );
}();

final $SpoilerSchema = () {
  final f0 = TmarkField<Spoiler, List<RichNode>>(
    null,
    FieldTypes.richText,
    (v) => v.children,
  );
  return NodeType<Spoiler>(
    "spoiler",
    layout: TmarkLayout.compact,
    fields: [f0],
    create: (v) => Spoiler(v.get(f0)),
  );
}();

final $SubscriptSchema = () {
  final f0 = TmarkField<Subscript, List<RichNode>>(
    null,
    FieldTypes.richText,
    (v) => v.children,
  );
  return NodeType<Subscript>(
    "sub",
    layout: TmarkLayout.compact,
    fields: [f0],
    create: (v) => Subscript(v.get(f0)),
  );
}();

final $SuperscriptSchema = () {
  final f0 = TmarkField<Superscript, List<RichNode>>(
    null,
    FieldTypes.richText,
    (v) => v.children,
  );
  return NodeType<Superscript>(
    "sup",
    layout: TmarkLayout.compact,
    fields: [f0],
    create: (v) => Superscript(v.get(f0)),
  );
}();

final $DateTimeNodeSchema = () {
  final f0 = TmarkField<DateTimeNode, int>(
    null,
    FieldTypes.integer,
    (v) => v.unix,
  );
  final f1 = TmarkField<DateTimeNode, String>(
    "timezone",
    FieldTypes.string,
    (v) => v.timezone,
    defaultValue: () => '',
  );
  return NodeType<DateTimeNode>(
    "datetime",
    layout: TmarkLayout.compact,
    fields: [f1, f0],
    create: (v) => DateTimeNode(unix: v.get(f0), timezone: v.get(f1)),
  );
}();

final $CodeSchema = () {
  final f0 = TmarkField<Code, String>(null, FieldTypes.string, (v) => v.text);
  return NodeType<Code>(
    "code",
    layout: TmarkLayout.compact,
    fields: [f0],
    create: (v) => Code(v.get(f0)),
  );
}();

final $MathSchema = () {
  final f0 = TmarkField<Math, String>(
    null,
    FieldTypes.string,
    (v) => v.expression,
  );
  return NodeType<Math>(
    "math",
    layout: TmarkLayout.compact,
    fields: [f0],
    create: (v) => Math(v.get(f0)),
  );
}();

final $IconSchema = () {
  final f0 = TmarkField<Icon, String>(
    null,
    FieldTypes.string,
    (v) => v.src,
    defaultValue: () => '',
  );
  final f1 = TmarkField<Icon, String?>(
    "alt",
    FieldTypes.string.optional(),
    (v) => v.alternativeText,
    defaultValue: () => null,
  );
  return NodeType<Icon>(
    "icon",
    layout: TmarkLayout.compact,
    fields: [f1, f0],
    create: (v) => Icon(src: v.get(f0), alternativeText: v.get(f1)),
  );
}();

final $ParagraphSchema = () {
  final f0 = TmarkField<Paragraph, List<RichNode>>(
    null,
    FieldTypes.richText,
    (v) => v.children,
  );
  return NodeType<Paragraph>(
    "p",
    layout: TmarkLayout.compact,
    fields: [f0],
    create: (v) => Paragraph(v.get(f0)),
  );
}();

final $HeaderSchema = () {
  final f0 = TmarkField<Header, int>("s", FieldTypes.integer, (v) => v.size);
  final f1 = TmarkField<Header, List<RichNode>>(
    null,
    FieldTypes.richText,
    (v) => v.children,
    defaultValue: () => const [],
  );
  return NodeType<Header>(
    "h",
    layout: TmarkLayout.compact,
    fields: [f0, f1],
    create: (v) => Header(size: v.get(f0), children: v.get(f1)),
  );
}();

final $PreformattedSchema = () {
  final f0 = TmarkField<Preformatted, String>(
    null,
    FieldTypes.string,
    (v) => v.text,
  );
  final f1 = TmarkField<Preformatted, String?>(
    "language",
    FieldTypes.string.optional(),
    (v) => v.language,
    defaultValue: () => null,
  );
  return NodeType<Preformatted>(
    "pre",
    layout: TmarkLayout.expanded,
    fields: [f1, f0],
    create: (v) => Preformatted(v.get(f0), language: v.get(f1)),
  );
}();

final $MathBlockSchema = () {
  final f0 = TmarkField<MathBlock, String>(
    null,
    FieldTypes.string,
    (v) => v.expression,
  );
  return NodeType<MathBlock>(
    "math-block",
    layout: TmarkLayout.expanded,
    fields: [f0],
    create: (v) => MathBlock(v.get(f0)),
  );
}();

final $AnchorSchema = () {
  final f0 = TmarkField<Anchor, String>(null, FieldTypes.string, (v) => v.name);
  return NodeType<Anchor>(
    "anchor",
    layout: TmarkLayout.compact,
    fields: [f0],
    create: (v) => Anchor(v.get(f0)),
  );
}();

final $DividerSchema = () {
  return NodeType<Divider>(
    "hr",
    layout: TmarkLayout.compact,
    fields: [],
    create: (v) => Divider(),
  );
}();

final $BlockquoteSchema = () {
  final f0 = TmarkField<Blockquote, List<RichNode>>(
    "credit",
    FieldTypes.richText,
    (v) => v.credit,
    defaultValue: () => const [],
  );
  final f1 = TmarkField<Blockquote, List<BlockNode>>(
    null,
    FieldTypes.nodes<BlockNode>(),
    (v) => v.blocks,
  );
  return NodeType<Blockquote>(
    "q",
    layout: TmarkLayout.whenMultiple,
    fields: [f0, f1],
    create: (v) => Blockquote(v.get(f1), credit: v.get(f0)),
  );
}();

final $PullQuoteSchema = () {
  final f0 = TmarkField<PullQuote, List<RichNode>>(
    "credit",
    FieldTypes.richText,
    (v) => v.credit,
    defaultValue: () => const [],
  );
  final f1 = TmarkField<PullQuote, List<RichNode>>(
    null,
    FieldTypes.richText,
    (v) => v.text,
  );
  return NodeType<PullQuote>(
    "as",
    layout: TmarkLayout.compact,
    fields: [f0, f1],
    create: (v) => PullQuote(v.get(f1), credit: v.get(f0)),
  );
}();

final $CollageSchema = () {
  final f0 = TmarkField<Collage, Caption?>(
    "caption",
    FieldTypes.node<Caption>().optional(),
    (v) => v.caption,
    defaultValue: () => null,
  );
  final f1 = TmarkField<Collage, List<GalleryNode>>(
    null,
    FieldTypes.nodes<GalleryNode>(),
    (v) => v.children,
  );
  return NodeType<Collage>(
    "collage",
    layout: TmarkLayout.expanded,
    fields: [f0, f1],
    create: (v) => Collage(v.get(f1), caption: v.get(f0)),
  );
}();

final $ListBlockSchema = () {
  final f0 = TmarkField<ListBlock, List<ListItem>>(
    null,
    FieldTypes.nodes<ListItem>(),
    (v) => v.items,
  );
  return NodeType<ListBlock>(
    "list",
    layout: TmarkLayout.expanded,
    fields: [f0],
    create: (v) => ListBlock(v.get(f0)),
  );
}();

final $ListItemSchema = () {
  final f0 = TmarkField<ListItem, String?>(
    "type",
    FieldTypes.string.optional(),
    (v) => v.type,
    defaultValue: () => null,
  );
  final f1 = TmarkField<ListItem, int?>(
    "order",
    FieldTypes.integer.optional(),
    (v) => v.order,
    defaultValue: () => null,
  );
  final f2 = TmarkField<ListItem, bool?>(
    "checked",
    FieldTypes.boolean.optional(),
    (v) => v.checked,
    defaultValue: () => null,
  );
  final f3 = TmarkField<ListItem, List<BlockNode>>(
    null,
    FieldTypes.nodes<BlockNode>(),
    (v) => v.children,
  );
  return NodeType<ListItem>(
    "li",
    layout: TmarkLayout.whenMultiple,
    fields: [f0, f1, f2, f3],
    create: (v) => ListItem(
      v.get(f3),
      type: v.get(f0),
      order: v.get(f1),
      checked: v.get(f2),
    ),
  );
}();

final $MapBlockSchema = () {
  final f0 = TmarkField<MapBlock, double>(
    "lat",
    FieldTypes.doubleValue,
    (v) => v.lat,
    defaultValue: () => 0,
  );
  final f1 = TmarkField<MapBlock, double>(
    "lon",
    FieldTypes.doubleValue,
    (v) => v.lon,
    defaultValue: () => 0,
  );
  final f2 = TmarkField<MapBlock, int?>(
    "zoom",
    FieldTypes.integer.optional(),
    (v) => v.zoom,
    defaultValue: () => null,
  );
  final f3 = TmarkField<MapBlock, Caption?>(
    "caption",
    FieldTypes.node<Caption>().optional(),
    (v) => v.caption,
    defaultValue: () => null,
  );
  return NodeType<MapBlock>(
    "map",
    layout: TmarkLayout.compact,
    fields: [f0, f1, f2, f3],
    create: (v) => MapBlock(
      lat: v.get(f0),
      lon: v.get(f1),
      zoom: v.get(f2),
      caption: v.get(f3),
    ),
  );
}();

final $ImageNodeSchema = () {
  final f0 = TmarkField<ImageNode, Caption?>(
    "caption",
    FieldTypes.node<Caption>().optional(),
    (v) => v.caption,
    defaultValue: () => null,
  );
  final f1 = TmarkField<ImageNode, bool>(
    "has_spoiler",
    FieldTypes.boolean,
    (v) => v.hasSpoiler,
    defaultValue: () => false,
  );
  final f2 = TmarkField<ImageNode, String>(
    null,
    FieldTypes.string,
    (v) => v.src,
    defaultValue: () => '',
  );
  return NodeType<ImageNode>(
    "img",
    layout: TmarkLayout.compact,
    fields: [f0, f1, f2],
    create: (v) =>
        ImageNode(src: v.get(f2), caption: v.get(f0), hasSpoiler: v.get(f1)),
  );
}();

final $VideoNodeSchema = () {
  final f0 = TmarkField<VideoNode, Caption?>(
    "caption",
    FieldTypes.node<Caption>().optional(),
    (v) => v.caption,
    defaultValue: () => null,
  );
  final f1 = TmarkField<VideoNode, bool>(
    "has_spoiler",
    FieldTypes.boolean,
    (v) => v.hasSpoiler,
    defaultValue: () => false,
  );
  final f2 = TmarkField<VideoNode, String>(
    "preview",
    FieldTypes.string,
    (v) => v.preview,
    defaultValue: () => '',
  );
  final f3 = TmarkField<VideoNode, bool>(
    "loop",
    FieldTypes.boolean,
    (v) => v.loop,
    defaultValue: () => false,
  );
  final f4 = TmarkField<VideoNode, String>(
    null,
    FieldTypes.string,
    (v) => v.src,
    defaultValue: () => '',
  );
  return NodeType<VideoNode>(
    "video",
    layout: TmarkLayout.compact,
    fields: [f0, f1, f2, f3, f4],
    create: (v) => VideoNode(
      src: v.get(f4),
      preview: v.get(f2),
      loop: v.get(f3),
      caption: v.get(f0),
      hasSpoiler: v.get(f1),
    ),
  );
}();

final $AudioNodeSchema = () {
  final f0 = TmarkField<AudioNode, Caption?>(
    "caption",
    FieldTypes.node<Caption>().optional(),
    (v) => v.caption,
    defaultValue: () => null,
  );
  final f1 = TmarkField<AudioNode, String>(
    null,
    FieldTypes.string,
    (v) => v.src,
    defaultValue: () => '',
  );
  return NodeType<AudioNode>(
    "audio",
    layout: TmarkLayout.compact,
    fields: [f0, f1],
    create: (v) => AudioNode(src: v.get(f1), caption: v.get(f0)),
  );
}();

final $SlideshowSchema = () {
  final f0 = TmarkField<Slideshow, Caption?>(
    "caption",
    FieldTypes.node<Caption>().optional(),
    (v) => v.caption,
    defaultValue: () => null,
  );
  final f1 = TmarkField<Slideshow, List<GalleryNode>>(
    null,
    FieldTypes.nodes<GalleryNode>(),
    (v) => v.children,
  );
  return NodeType<Slideshow>(
    "slideshow",
    layout: TmarkLayout.expanded,
    fields: [f0, f1],
    create: (v) => Slideshow(v.get(f1), caption: v.get(f0)),
  );
}();

final $TableSchema = () {
  final f0 = TmarkField<Table, List<RichNode>>(
    "caption",
    FieldTypes.richText,
    (v) => v.caption,
    defaultValue: () => const [],
  );
  final f1 = TmarkField<Table, bool>(
    "bordered",
    FieldTypes.boolean,
    (v) => v.bordered,
    defaultValue: () => false,
  );
  final f2 = TmarkField<Table, bool>(
    "striped",
    FieldTypes.boolean,
    (v) => v.striped,
    defaultValue: () => false,
  );
  final f3 = TmarkField<Table, List<TableRow>>(
    null,
    FieldTypes.nodes<TableRow>(),
    (v) => v.rows,
  );
  return NodeType<Table>(
    "table",
    layout: TmarkLayout.expanded,
    fields: [f0, f1, f2, f3],
    create: (v) => Table(
      v.get(f3),
      caption: v.get(f0),
      bordered: v.get(f1),
      striped: v.get(f2),
    ),
  );
}();

final $TableRowSchema = () {
  final f0 = TmarkField<TableRow, List<Cell>>(
    null,
    FieldTypes.nodes<Cell>(),
    (v) => v.cells,
  );
  return NodeType<TableRow>(
    "tr",
    layout: TmarkLayout.compact,
    fields: [f0],
    create: (v) => TableRow(v.get(f0)),
  );
}();

final $CellSchema = () {
  final f0 = TmarkField<Cell, bool>(
    "header",
    FieldTypes.boolean,
    (v) => v.isHeader,
    defaultValue: () => false,
  );
  final f1 = TmarkField<Cell, int?>(
    "colspan",
    FieldTypes.integer.optional(),
    (v) => v.colspan,
    defaultValue: () => null,
  );
  final f2 = TmarkField<Cell, int?>(
    "rowspan",
    FieldTypes.integer.optional(),
    (v) => v.rowspan,
    defaultValue: () => null,
  );
  final f3 = TmarkField<Cell, TableCellAlign?>(
    "align",
    FieldTypes.enumeration(TableCellAlign.values).optional(),
    (v) => v.align,
    defaultValue: () => null,
  );
  final f4 = TmarkField<Cell, TableCellValign?>(
    "valign",
    FieldTypes.enumeration(TableCellValign.values).optional(),
    (v) => v.valign,
    defaultValue: () => null,
  );
  final f5 = TmarkField<Cell, List<RichNode>>(
    null,
    FieldTypes.richText,
    (v) => v.children,
  );
  return NodeType<Cell>(
    "td",
    layout: TmarkLayout.compact,
    fields: [f0, f1, f2, f3, f4, f5],
    create: (v) => Cell(
      v.get(f5),
      isHeader: v.get(f0),
      colspan: v.get(f1),
      rowspan: v.get(f2),
      align: v.get(f3),
      valign: v.get(f4),
    ),
  );
}();

final $DetailsSchema = () {
  final f0 = TmarkField<Details, List<RichNode>>(
    "summary",
    FieldTypes.richText,
    (v) => v.summary,
    defaultValue: () => const [],
  );
  final f1 = TmarkField<Details, bool>(
    "open",
    FieldTypes.boolean,
    (v) => v.isOpen,
    defaultValue: () => false,
  );
  final f2 = TmarkField<Details, List<BlockNode>>(
    null,
    FieldTypes.nodes<BlockNode>(),
    (v) => v.children,
  );
  return NodeType<Details>(
    "details",
    layout: TmarkLayout.whenMultiple,
    fields: [f0, f1, f2],
    create: (v) => Details(v.get(f2), summary: v.get(f0), isOpen: v.get(f1)),
  );
}();

final $DocumentSchema = () {
  final f0 = TmarkField<Document, String>(
    "url",
    FieldTypes.string,
    (v) => v.url,
    defaultValue: () => '',
  );
  final f1 = TmarkField<Document, String>(
    "title",
    FieldTypes.string,
    (v) => v.title,
    defaultValue: () => '',
  );
  final f2 = TmarkField<Document, String?>(
    "description",
    FieldTypes.string.optional(),
    (v) => v.description,
    defaultValue: () => null,
  );
  final f3 = TmarkField<Document, String?>(
    "author_name",
    FieldTypes.string.optional(),
    (v) => v.authorName,
    defaultValue: () => null,
  );
  final f4 = TmarkField<Document, String?>(
    "author_url",
    FieldTypes.string.optional(),
    (v) => v.authorUrl,
    defaultValue: () => null,
  );
  final f5 = TmarkField<Document, String?>(
    "image_url",
    FieldTypes.string.optional(),
    (v) => v.imageUrl,
    defaultValue: () => null,
  );
  final f6 = TmarkField<Document, List<BlockNode>>(
    null,
    FieldTypes.nodes<BlockNode>(),
    (v) => v.content,
  );
  final f7 = TmarkField<Document, List<AttachedMedia>>(
    "attached_media",
    FieldTypes.nodes<AttachedMedia>(),
    (v) => v.attachedMedia,
    defaultValue: () => const [],
  );
  return NodeType<Document>(
    "document",
    layout: TmarkLayout.expanded,
    fields: [f0, f1, f2, f3, f4, f5, f7, f6],
    create: (v) => Document(
      url: v.get(f0),
      title: v.get(f1),
      content: v.get(f6),
      description: v.get(f2),
      authorName: v.get(f3),
      authorUrl: v.get(f4),
      imageUrl: v.get(f5),
      attachedMedia: v.get(f7),
    ),
  );
}();

final $AttachedMediaSchema = () {
  final f0 = TmarkField<AttachedMedia, String>(
    "hash",
    FieldTypes.string,
    (v) => v.hash,
    defaultValue: () => '',
  );
  final f1 = TmarkField<AttachedMedia, List<BlockNode>>(
    null,
    FieldTypes.nodes<BlockNode>(),
    (v) => v.content,
  );
  return NodeType<AttachedMedia>(
    "attached",
    layout: TmarkLayout.expanded,
    fields: [f0, f1],
    create: (v) => AttachedMedia(hash: v.get(f0), content: v.get(f1)),
  );
}();
