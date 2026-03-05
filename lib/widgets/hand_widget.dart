import 'package:flutter/material.dart';

import '../models/tile_instance.dart';
import 'tile_widget.dart';

/// Displays hand (closed + optional tsumo). Tap to select a tile for discard.
class HandWidget extends StatelessWidget {
  const HandWidget({
    super.key,
    required this.closed,
    this.tsumo,
    required this.selectedTileIndex,
    required this.onTileTap,
    this.tileSize = 36,
    this.dimmedTileIds = const [],
  });

  final List<TileInstance> closed;
  final TileInstance? tsumo;
  final int? selectedTileIndex;
  final void Function(TileInstance tile) onTileTap;
  final double tileSize;
  // 喰い替え禁止牌のIDリスト（Opacity 0.35でグレーアウト表示）
  final List<int> dimmedTileIds;

  @override
  Widget build(BuildContext context) {
    final all = tsumo != null ? [...closed, tsumo!] : closed;
    return Wrap(
      spacing: 2,
      runSpacing: 2,
      alignment: WrapAlignment.center,
      children: all.map((t) {
        final selected = selectedTileIndex != null && t.index == selectedTileIndex;
        final isDimmed = dimmedTileIds.contains(t.id);
        return Padding(
          padding: const EdgeInsets.all(2),
          child: Opacity(
            opacity: isDimmed ? 0.35 : 1.0,
            child: TileWidget(
              tile: t,
              size: tileSize,
              selected: selected,
              onTap: () => onTileTap(t),
            ),
          ),
        );
      }).toList(),
    );
  }
}
