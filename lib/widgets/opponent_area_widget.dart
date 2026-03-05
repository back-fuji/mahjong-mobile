import 'package:flutter/material.dart';

import '../models/player_filtered.dart';
import 'discard_pool_widget.dart';
import 'tile_widget.dart';

enum OpponentPosition { top, left, right }

/// One opponent area: name, face-down hand (closedCount), melds, discard pool.
class OpponentAreaWidget extends StatelessWidget {
  const OpponentAreaWidget({
    super.key,
    required this.player,
    required this.position,
    this.tileWidth = 28,
    this.tileHeight = 38,
    this.faceDownSize = 28,
    this.showName = true,
  });

  final PlayerFiltered player;
  final OpponentPosition position;
  final double tileWidth;
  final double tileHeight;
  final double faceDownSize;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final count = player.closedCount ?? 0;
    final discards = player.discards;
    final melds = player.melds;

    Widget nameLabel(String text) {
      if (!showName) return const SizedBox.shrink();
      return Padding(
        padding: position == OpponentPosition.top
            ? const EdgeInsets.only(bottom: 4)
            : const EdgeInsets.only(bottom: 2),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      );
    }

    switch (position) {
      case OpponentPosition.top:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            nameLabel(player.name),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    count,
                    (_) => _faceDownTile(faceDownSize),
                  ),
                ),
                if (melds.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  ...melds.map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: m.tiles
                            .map(
                              (t) => Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: TileWidget(
                                  tile: t,
                                  size: faceDownSize * 0.9,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            DiscardPoolWidget(
              discards: discards,
              riichiDiscardIndex: player.riichiDiscardIndex >= 0
                  ? player.riichiDiscardIndex
                  : -1,
              tileWidth: tileWidth,
              tileHeight: tileHeight,
              position: DiscardPosition.top,
            ),
          ],
        );
      case OpponentPosition.left:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                nameLabel(player.name),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        count,
                        (_) => _faceDownTile(faceDownSize * 0.7),
                      ),
                    ),
                    if (melds.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      ...melds.map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: m.tiles
                                .map(
                                  (t) => Padding(
                                    padding: const EdgeInsets.only(right: 2),
                                    child: Transform.rotate(
                                      angle: 1.5708,
                                      child: TileWidget(
                                        tile: t,
                                        size: faceDownSize * 0.6,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(width: 4),
            DiscardPoolWidget(
              discards: discards,
              riichiDiscardIndex: player.riichiDiscardIndex >= 0
                  ? player.riichiDiscardIndex
                  : -1,
              tileWidth: tileWidth,
              tileHeight: tileHeight,
              position: DiscardPosition.left,
            ),
          ],
        );
      case OpponentPosition.right:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            DiscardPoolWidget(
              discards: discards,
              riichiDiscardIndex: player.riichiDiscardIndex >= 0
                  ? player.riichiDiscardIndex
                  : -1,
              tileWidth: tileWidth,
              tileHeight: tileHeight,
              position: DiscardPosition.right,
            ),
            const SizedBox(width: 4),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                nameLabel(player.name),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        count,
                        (_) => _faceDownTile(faceDownSize * 0.7),
                      ),
                    ),
                    if (melds.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      ...melds.map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: m.tiles
                                .map(
                                  (t) => Padding(
                                    padding: const EdgeInsets.only(right: 2),
                                    child: Transform.rotate(
                                      angle: -1.5708,
                                      child: TileWidget(
                                        tile: t,
                                        size: faceDownSize * 0.6,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        );
    }
  }

  Widget _faceDownTile(double size) {
    return Container(
      width: size,
      height: size * 1.35,
      margin: position == OpponentPosition.top
          ? const EdgeInsets.only(right: 2)
          : const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        border: Border.all(color: Colors.amber.shade300),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: Container(
          width: size * 0.5,
          height: size * 0.5,
          decoration: BoxDecoration(
            color: Colors.green.shade800,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
