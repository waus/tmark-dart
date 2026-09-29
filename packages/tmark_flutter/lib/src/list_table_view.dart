part of tmark_flutter;

Widget _listView(List<tm.ListItem> items) {
  final ordered = _hasOrderedItems(items);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < items.length; i++)
        _ListItemView(item: items[i], index: i, ordered: ordered),
    ],
  );
}

class _ListItemView extends StatelessWidget {
  const _ListItemView({
    required this.item,
    required this.index,
    required this.ordered,
  });

  final tm.ListItem item;
  final int index;
  final bool ordered;

  @override
  Widget build(BuildContext context) {
    final marker = _listItemMarker(item, index, ordered);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: item.checked != null
                ? _ChecklistMarker(checked: item.checked!)
                : Text(marker),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final block in item.children) _renderBlock(context, block),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

bool _hasOrderedItems(List<tm.ListItem> items) => items.any(_isOrderedItem);

bool _isOrderedItem(tm.ListItem item) =>
    item.order != null || item.type != null;

String _listItemMarker(tm.ListItem item, int index, bool ordered) {
  final order = item.order ?? (ordered ? index + 1 : null);
  if (order == null) return '•';

  return switch (item.type) {
    'a' => '${_alphabeticOrder(order).toLowerCase()}.',
    'A' => '${_alphabeticOrder(order)}.',
    'i' => '${_romanOrder(order).toLowerCase()}.',
    'I' => '${_romanOrder(order)}.',
    '1' || null => '$order.',
    _ => '$order.',
  };
}

String _alphabeticOrder(int value) {
  if (value <= 0) return value.toString();

  final buffer = StringBuffer();
  var n = value;
  while (n > 0) {
    n--;
    buffer.writeCharCode(65 + n % 26);
    n ~/= 26;
  }
  return buffer.toString().split('').reversed.join();
}

String _romanOrder(int value) {
  if (value <= 0 || value > 3999) return value.toString();

  const numerals = [
    (1000, 'M'),
    (900, 'CM'),
    (500, 'D'),
    (400, 'CD'),
    (100, 'C'),
    (90, 'XC'),
    (50, 'L'),
    (40, 'XL'),
    (10, 'X'),
    (9, 'IX'),
    (5, 'V'),
    (4, 'IV'),
    (1, 'I'),
  ];

  final buffer = StringBuffer();
  var n = value;
  for (final (number, numeral) in numerals) {
    while (n >= number) {
      buffer.write(numeral);
      n -= number;
    }
  }
  return buffer.toString();
}

class _ChecklistMarker extends StatelessWidget {
  const _ChecklistMarker({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    final lineHeight = (style.fontSize ?? 14) * (style.height ?? 1.4);

    return SizedBox(
      height: lineHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: _ChecklistBox(checked: checked),
      ),
    );
  }
}

class _ChecklistBox extends StatelessWidget {
  const _ChecklistBox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final style = _styleOf(context);
    final color = style.onSurfaceVariantColor ?? const Color(0xff71717a);
    return Semantics(
      checked: checked,
      child: CustomPaint(
        size: const Size.square(16),
        painter: _ChecklistBoxPainter(checked: checked, color: color),
      ),
    );
  }
}

class _ChecklistBoxPainter extends CustomPainter {
  const _ChecklistBoxPainter({required this.checked, required this.color});

  final bool checked;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(3)),
      paint,
    );
    if (!checked) return;
    final path = Path()
      ..moveTo(size.width * 0.25, size.height * 0.52)
      ..lineTo(size.width * 0.43, size.height * 0.70)
      ..lineTo(size.width * 0.76, size.height * 0.30);
    canvas.drawPath(path, paint..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _ChecklistBoxPainter oldDelegate) {
    return checked != oldDelegate.checked || color != oldDelegate.color;
  }
}

class _CellView extends StatelessWidget {
  const _CellView({required this.cell});

  final tm.Cell cell;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: DefaultTextStyle.merge(
      style: cell.isHeader
          ? const TextStyle(fontWeight: FontWeight.w700)
          : null,
      child: SizedBox(
        width: double.infinity,
        child: _RichTextView(
          children: cell.children,
          textAlign: _cellTextAlign(cell.align),
        ),
      ),
    ),
  );
}

class _TableView extends StatelessWidget {
  const _TableView({required this.table});

  final tm.Table table;

  @override
  Widget build(BuildContext context) {
    final hasSpans = table.rows.any(
      (row) =>
          row.cells.any((cell) => cell.colspan != null || cell.rowspan != null),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasSpans) _SpanTable(table: table) else _RegularTable(table: table),
        if (table.caption.isNotEmpty)
          _CaptionView(caption: tm.Caption(text: table.caption)),
      ],
    );
  }
}

class _RegularTable extends StatelessWidget {
  const _RegularTable({required this.table});

  final tm.Table table;

  @override
  Widget build(BuildContext context) {
    final style = _styleOf(context);
    final columns = table.rows.fold<int>(
      0,
      (count, row) => math.max(count, row.cells.length),
    );
    if (columns == 0) return const SizedBox.shrink();

    return Table(
      border: table.bordered
          ? TableBorder.all(
              color: style.dividerColor ?? const Color(0xffe4e4e7),
            )
          : null,
      children: [
        for (var r = 0; r < table.rows.length; r++)
          TableRow(
            decoration: table.striped && r.isOdd
                ? BoxDecoration(color: style.surfaceVariantColor)
                : null,
            children: [
              for (final cell in table.rows[r].cells)
                TableCell(
                  verticalAlignment: _tableCellVerticalAlignment(cell.valign),
                  child: _CellView(cell: cell),
                ),
              for (var c = table.rows[r].cells.length; c < columns; c++)
                const TableCell(child: _CellView(cell: tm.Cell([]))),
            ],
          ),
      ],
    );
  }
}

// Flutter's built-in Table does not support colspan/rowspan and requires every
// row to have the same number of children. Span tables use a small positioned
// grid instead, so merged cells do not leave visual holes.
class _SpanTable extends StatelessWidget {
  const _SpanTable({required this.table});

  final tm.Table table;
  static const double _rowHeight = 40;

  @override
  Widget build(BuildContext context) {
    final layout = _TableLayout.fromRows(table.rows);
    final style = _styleOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = constraints.maxWidth / layout.columns;
        return SizedBox(
          height: layout.rows * _rowHeight,
          child: Stack(
            children: [
              for (final cell in layout.cells)
                Positioned(
                  left: cell.column * columnWidth,
                  top: cell.row * _rowHeight,
                  width: columnWidth * cell.colspan,
                  height: _rowHeight * cell.rowspan,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: table.striped && cell.row.isOdd
                          ? style.surfaceVariantColor
                          : null,
                      border: table.bordered
                          ? Border.all(
                              color:
                                  style.dividerColor ?? const Color(0xffe4e4e7),
                            )
                          : null,
                    ),
                    child: _SpanCellView(cell: cell.cell),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TableLayout {
  const _TableLayout({
    required this.columns,
    required this.rows,
    required this.cells,
  });

  final int columns;
  final int rows;
  final List<_PlacedCell> cells;

  static _TableLayout fromRows(List<tm.TableRow> rows) {
    final occupied = <int, Set<int>>{};
    final cells = <_PlacedCell>[];
    var columnCount = 0;
    var rowCount = rows.length;

    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      var column = 0;
      occupied.putIfAbsent(rowIndex, () => <int>{});

      for (final cell in rows[rowIndex].cells) {
        while (occupied[rowIndex]!.contains(column)) {
          column++;
        }

        final colspan = cell.colspan ?? 1;
        final rowspan = cell.rowspan ?? 1;
        cells.add(
          _PlacedCell(
            cell: cell,
            row: rowIndex,
            column: column,
            colspan: colspan,
            rowspan: rowspan,
          ),
        );

        for (var r = rowIndex; r < rowIndex + rowspan; r++) {
          final occupiedRow = occupied.putIfAbsent(r, () => <int>{});
          for (var c = column; c < column + colspan; c++) {
            occupiedRow.add(c);
          }
        }

        column += colspan;
        if (column > columnCount) columnCount = column;
        final endRow = rowIndex + rowspan;
        if (endRow > rowCount) rowCount = endRow;
      }
    }

    for (final row in occupied.values) {
      if (row.isEmpty) continue;
      final width = row.reduce((a, b) => a > b ? a : b) + 1;
      if (width > columnCount) columnCount = width;
    }

    return _TableLayout(
      columns: columnCount == 0 ? 1 : columnCount,
      rows: rowCount == 0 ? 1 : rowCount,
      cells: cells,
    );
  }
}

class _SpanCellView extends StatelessWidget {
  const _SpanCellView({required this.cell});

  final tm.Cell cell;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: _cellMainAxisAlignment(cell.valign),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [_CellView(cell: cell)],
  );
}

TableCellVerticalAlignment _tableCellVerticalAlignment(
  tm.TableCellValign? valign,
) {
  return switch (valign) {
    tm.TableCellValign.middle => TableCellVerticalAlignment.middle,
    tm.TableCellValign.bottom => TableCellVerticalAlignment.bottom,
    tm.TableCellValign.top || null => TableCellVerticalAlignment.top,
  };
}

MainAxisAlignment _cellMainAxisAlignment(tm.TableCellValign? valign) {
  return switch (valign) {
    tm.TableCellValign.middle => MainAxisAlignment.center,
    tm.TableCellValign.bottom => MainAxisAlignment.end,
    tm.TableCellValign.top || null => MainAxisAlignment.start,
  };
}

TextAlign _cellTextAlign(tm.TableCellAlign? align) {
  return switch (align) {
    tm.TableCellAlign.center => TextAlign.center,
    tm.TableCellAlign.right => TextAlign.right,
    tm.TableCellAlign.left || null => TextAlign.left,
  };
}

class _PlacedCell {
  const _PlacedCell({
    required this.cell,
    required this.row,
    required this.column,
    required this.colspan,
    required this.rowspan,
  });

  final tm.Cell cell;
  final int row;
  final int column;
  final int colspan;
  final int rowspan;
}
