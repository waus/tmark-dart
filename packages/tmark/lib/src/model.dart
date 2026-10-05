part of tmark;

const int maxDepth = 16;

abstract class TmarkValue {
  const TmarkValue();
}

abstract interface class RichNode implements TmarkValue {}

abstract interface class BlockNode implements TmarkValue {}

abstract interface class GalleryNode implements TmarkValue {}

typedef Text = String;
typedef RichText = List<RichNode>;
typedef RichBlocks = List<BlockNode>;

final class TText extends TmarkValue implements RichNode {
  const TText(this.text);
  final String text;
}

final class Unknown extends TmarkValue implements RichNode, BlockNode {
  const Unknown(this.raw);
  final String raw;
}

@TmarkNode('caption')
final class Caption extends TmarkValue {
  const Caption({this.credit = const [], this.text = const []});
  final RichText credit;
  @TmarkBody()
  final RichText text;

  static final schema = $CaptionSchema;
}

@TmarkNode('a')
final class Link extends TmarkValue implements RichNode {
  const Link({this.href = '', this.children = const []});
  final String href;
  @TmarkBody()
  final RichText children;

  static final schema = $LinkSchema;
}

@TmarkNode('anchor-link')
final class AnchorLink extends TmarkValue implements RichNode {
  const AnchorLink({this.anchorName = '', this.children = const []});
  @TmarkName('name')
  final String anchorName;
  @TmarkBody()
  final RichText children;

  static final schema = $AnchorLinkSchema;
}

@TmarkNode('ref')
final class Reference extends TmarkValue implements RichNode {
  const Reference({this.name = '', this.children = const []});
  final String name;
  @TmarkBody()
  final RichText children;

  static final schema = $ReferenceSchema;
}

@TmarkNode('ref-link')
final class ReferenceLink extends TmarkValue implements RichNode {
  const ReferenceLink({this.referenceName = '', this.children = const []});
  @TmarkName('name')
  final String referenceName;
  @TmarkBody()
  final RichText children;

  static final schema = $ReferenceLinkSchema;
}

@TmarkNode('b')
final class Bold extends TmarkValue implements RichNode {
  const Bold(this.children);
  @TmarkBody()
  final RichText children;

  static final schema = $BoldSchema;
}

@TmarkNode('i')
final class Italic extends TmarkValue implements RichNode {
  const Italic(this.children);
  @TmarkBody()
  final RichText children;

  static final schema = $ItalicSchema;
}

@TmarkNode('m')
final class Marked extends TmarkValue implements RichNode {
  const Marked(this.children);
  @TmarkBody()
  final RichText children;

  static final schema = $MarkedSchema;
}

@TmarkNode('u')
final class Underline extends TmarkValue implements RichNode {
  const Underline(this.children);
  @TmarkBody()
  final RichText children;

  static final schema = $UnderlineSchema;
}

@TmarkNode('s')
final class Strikethrough extends TmarkValue implements RichNode {
  const Strikethrough(this.children);
  @TmarkBody()
  final RichText children;

  static final schema = $StrikethroughSchema;
}

@TmarkNode('spoiler')
final class Spoiler extends TmarkValue implements RichNode {
  const Spoiler(this.children);
  @TmarkBody()
  final RichText children;

  static final schema = $SpoilerSchema;
}

@TmarkNode('sub')
final class Subscript extends TmarkValue implements RichNode {
  const Subscript(this.children);
  @TmarkBody()
  final RichText children;

  static final schema = $SubscriptSchema;
}

@TmarkNode('sup')
final class Superscript extends TmarkValue implements RichNode {
  const Superscript(this.children);
  @TmarkBody()
  final RichText children;

  static final schema = $SuperscriptSchema;
}

@TmarkNode('datetime')
final class DateTimeNode extends TmarkValue implements RichNode {
  const DateTimeNode({required this.unix, this.timezone = ''});
  @TmarkBody()
  final int unix;
  final String timezone;

  static final schema = $DateTimeNodeSchema;
}

@TmarkNode('code')
final class Code extends TmarkValue implements RichNode {
  const Code(this.text);
  @TmarkBody()
  final String text;

  static final schema = $CodeSchema;
}

@TmarkNode('math')
final class Math extends TmarkValue implements RichNode {
  const Math(this.expression);
  @TmarkBody()
  final String expression;

  static final schema = $MathSchema;
}

@TmarkNode('icon')
final class Icon extends TmarkValue implements RichNode {
  const Icon({this.src = '', this.alternativeText});
  @TmarkBody()
  final String src;
  @TmarkName('alt')
  final String? alternativeText;

  static final schema = $IconSchema;
}

@TmarkNode('p')
final class Paragraph extends TmarkValue implements BlockNode {
  const Paragraph(this.children);
  @TmarkBody()
  final RichText children;

  static final schema = $ParagraphSchema;
}

@TmarkNode('h')
final class Header extends TmarkValue implements BlockNode {
  const Header({required this.size, this.children = const []});
  @TmarkName('s')
  final int size;
  @TmarkBody()
  final RichText children;

  static final schema = $HeaderSchema;
}

@TmarkNode('pre', layout: TmarkLayout.expanded)
final class Preformatted extends TmarkValue implements BlockNode {
  const Preformatted(this.text, {this.language});
  @TmarkBody()
  final String text;
  final String? language;

  static final schema = $PreformattedSchema;
}

@TmarkNode('math-block', layout: TmarkLayout.expanded)
final class MathBlock extends TmarkValue implements BlockNode {
  const MathBlock(this.expression);
  @TmarkBody()
  final String expression;

  static final schema = $MathBlockSchema;
}

@TmarkNode('anchor')
final class Anchor extends TmarkValue implements BlockNode {
  const Anchor(this.name);
  @TmarkBody()
  final String name;

  static final schema = $AnchorSchema;
}

@TmarkNode('hr')
final class Divider extends TmarkValue implements BlockNode {
  const Divider();

  static final schema = $DividerSchema;
}

@TmarkNode('q', layout: TmarkLayout.whenMultiple)
final class Blockquote extends TmarkValue implements BlockNode {
  const Blockquote(this.blocks, {this.credit = const []});
  final RichText credit;
  @TmarkBody()
  final RichBlocks blocks;

  static final schema = $BlockquoteSchema;
}

@TmarkNode('as')
final class PullQuote extends TmarkValue implements BlockNode {
  const PullQuote(this.text, {this.credit = const []});
  final RichText credit;
  @TmarkBody()
  final RichText text;

  static final schema = $PullQuoteSchema;
}

@TmarkNode('collage', layout: TmarkLayout.expanded)
final class Collage extends TmarkValue implements BlockNode {
  const Collage(this.children, {this.caption});
  final Caption? caption;
  @TmarkBody()
  final List<GalleryNode> children;

  static final schema = $CollageSchema;
}

@TmarkNode('list', layout: TmarkLayout.expanded)
final class ListBlock extends TmarkValue implements BlockNode {
  const ListBlock(this.items);
  @TmarkBody()
  final List<ListItem> items;

  static final schema = $ListBlockSchema;
}

@TmarkNode('li', layout: TmarkLayout.whenMultiple)
final class ListItem extends TmarkValue implements BlockNode {
  const ListItem(this.children, {this.type, this.order, this.checked});
  final String? type;
  final int? order;
  final bool? checked;
  @TmarkBody()
  final RichBlocks children;

  static final schema = $ListItemSchema;
}

@TmarkNode('map')
final class MapBlock extends TmarkValue implements BlockNode {
  const MapBlock({this.lat = 0, this.lon = 0, this.zoom, this.caption});
  final double lat;
  final double lon;
  final int? zoom;
  final Caption? caption;

  static final schema = $MapBlockSchema;
}

@TmarkNode('img')
final class ImageNode extends TmarkValue implements BlockNode, GalleryNode {
  const ImageNode({this.src = '', this.caption, this.hasSpoiler = false});
  final Caption? caption;
  @TmarkName('has_spoiler')
  final bool hasSpoiler;
  @TmarkBody()
  final String src;

  static final schema = $ImageNodeSchema;
}

@TmarkNode('video')
final class VideoNode extends TmarkValue implements BlockNode, GalleryNode {
  const VideoNode({
    this.src = '',
    this.preview = '',
    this.loop = false,
    this.caption,
    this.hasSpoiler = false,
  });
  final Caption? caption;
  @TmarkName('has_spoiler')
  final bool hasSpoiler;
  final String preview;
  final bool loop;
  @TmarkBody()
  final String src;

  static final schema = $VideoNodeSchema;
}

@TmarkNode('audio')
final class AudioNode extends TmarkValue implements BlockNode {
  const AudioNode({this.src = '', this.caption});
  final Caption? caption;
  @TmarkBody()
  final String src;

  static final schema = $AudioNodeSchema;
}

@TmarkNode('slideshow', layout: TmarkLayout.expanded)
final class Slideshow extends TmarkValue implements BlockNode {
  const Slideshow(this.children, {this.caption});
  final Caption? caption;
  @TmarkBody()
  final List<GalleryNode> children;

  static final schema = $SlideshowSchema;
}

enum TableCellAlign { left, center, right }

enum TableCellValign { top, middle, bottom }

@TmarkNode('table', layout: TmarkLayout.expanded)
final class Table extends TmarkValue implements BlockNode {
  const Table(
    this.rows, {
    this.caption = const [],
    this.bordered = false,
    this.striped = false,
  });
  final RichText caption;
  final bool bordered;
  final bool striped;
  @TmarkBody()
  final List<TableRow> rows;

  static final schema = $TableSchema;
}

@TmarkNode('tr')
final class TableRow extends TmarkValue implements BlockNode {
  const TableRow(this.cells);
  @TmarkBody()
  final List<Cell> cells;

  static final schema = $TableRowSchema;
}

@TmarkNode('td')
final class Cell extends TmarkValue implements BlockNode {
  const Cell(
    this.children, {
    this.isHeader = false,
    this.colspan,
    this.rowspan,
    this.align,
    this.valign,
  });
  @TmarkName('header')
  final bool isHeader;
  final int? colspan;
  final int? rowspan;
  final TableCellAlign? align;
  final TableCellValign? valign;
  @TmarkBody()
  final RichText children;

  static final schema = $CellSchema;
}

@TmarkNode('details', layout: TmarkLayout.whenMultiple)
final class Details extends TmarkValue implements BlockNode {
  const Details(this.children, {this.summary = const [], this.isOpen = false});
  final RichText summary;
  @TmarkName('open')
  final bool isOpen;
  @TmarkBody()
  final RichBlocks children;

  static final schema = $DetailsSchema;
}

@TmarkNode('document', layout: TmarkLayout.expanded)
final class Document extends TmarkValue {
  const Document({
    this.url = '',
    this.title = '',
    required this.content,
    this.description,
    this.authorName,
    this.authorUrl,
    this.imageUrl,
    this.attachedMedia = const [],
  });
  final Text url;
  final Text title;
  final Text? description;
  @TmarkName('author_name')
  final Text? authorName;
  @TmarkName('author_url')
  final Text? authorUrl;
  @TmarkName('image_url')
  final Text? imageUrl;
  @TmarkBody()
  final RichBlocks content;
  @TmarkName('attached_media')
  final List<AttachedMedia> attachedMedia;

  static final schema = $DocumentSchema;
}

@TmarkNode('attached', layout: TmarkLayout.expanded)
final class AttachedMedia extends TmarkValue {
  const AttachedMedia({this.hash = '', required this.content});
  final Text hash;
  @TmarkBody()
  final RichBlocks content;

  static final schema = $AttachedMediaSchema;
}
