import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/tile_instance.dart';
import 'tile_widget.dart';

enum DiscardPosition { bottom, top, left, right }

/// Discard pool: 6 tiles per row, up to 4 rows.
class DiscardPoolWidget extends StatelessWidget {
  const DiscardPoolWidget({
    super.key,
    required this.discards,
    this.riichiDiscardIndex = -1,
    this.tileWidth = 32,
    this.tileHeight = 44,
    this.position = DiscardPosition.bottom,
  });

  final List<TileInstance> discards;
  final int riichiDiscardIndex;
  final double tileWidth;
  final double tileHeight;
  final DiscardPosition position;

  static List<List<TileInstance>> _toRows(List<TileInstance> list) {
    final rows = <List<TileInstance>>[];
    for (var i = 0; i < list.length; i += 6) {
      rows.add(list.sublist(i, math.min(i + 6, list.length)));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _toRows(discards);
    if (rows.isEmpty) return const SizedBox.shrink();

    Widget content;
    switch (position) {
      case DiscardPosition.bottom:
        content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            rows.length,
            (ri) => Row(
              mainAxisSize: MainAxisSize.min,
              children: _rowTiles(rows[ri], ri),
            ),
          ),
        );
        break;
      case DiscardPosition.top:
        content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(rows.length, (i) {
            final ri = rows.length - 1 - i;
            return Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.rtl,
              children: _rowTiles(rows[ri], ri, rotationDeg: 180),
            );
          }),
        );
        break;
      case DiscardPosition.left:
      case DiscardPosition.right: {
        final angle = position == DiscardPosition.left ? math.pi / 2 : -math.pi / 2;
        final col = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            rows.length,
            (ri) => Row(
              mainAxisSize: MainAxisSize.min,
              children: _rowTiles(rows[ri], ri),
            ),
          ),
        );
        // Rotated content needs bounded box + clip to avoid "tape" overflow strip
        final maxCols = rows.isEmpty ? 0 : rows.map((r) => r.length).reduce(math.max);
        final maxW = maxCols * tileWidth;
        final maxH = rows.length * tileHeight;
        content = ClipRect(
          child: SizedBox(
            width: maxH,
            height: maxW,
            child: Center(
              child: Transform.rotate(
                angle: angle,
                child: col,
              ),
            ),
          ),
        );
        break;
      }
    }

    return content;
  }

  List<Widget> _rowTiles(
    List<TileInstance> row,
    int rowIndex, {
    double rotationDeg = 0,
  }) {
    return row.asMap().entries.map((e) {
      final tile = e.value;
      Widget w = SizedBox(
        width: tileWidth,
        height: tileHeight,
        child: TileWidget(
          tile: tile,
          size: math.min(tileWidth, tileHeight * 0.85),
        ),
      );
      if (rotationDeg != 0) {
        w = Transform.rotate(angle: rotationDeg * math.pi / 180, child: w);
      }
      return w;
    }).toList();
  }
}
