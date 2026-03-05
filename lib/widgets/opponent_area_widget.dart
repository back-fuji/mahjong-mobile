import 'dart:math' as math;

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
    this.doraIds = const {},
  });

  final PlayerFiltered player;
  final OpponentPosition position;
  final double tileWidth;
  final double tileHeight;
  final double faceDownSize;
  final bool showName;
  // ドラ牌IDセット（捨て牌の赤枠ハイライト表示）
  final Set<int> doraIds;

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
                        children: m.tiles.asMap().entries
                            .map((e) {
                              final ti = e.key;
                              final t = e.value;
                              final isCalled = m.calledTile != null &&
                                  t.index == m.calledTile!.index;
                              final isFaceDown = (m.type == 'ankan') &&
                                  (ti == 0 || ti == 3);
                              Widget tileWidget = isFaceDown
                                  ? _faceDownTile(faceDownSize * 0.9)
                                  : TileWidget(
                                      tile: t,
                                      size: faceDownSize * 0.9,
                                    );
                              if (isCalled) {
                                tileWidget = Transform.rotate(
                                  angle: math.pi / 2,
                                  child: tileWidget,
                                );
                              }
                              return Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: tileWidget,
                              );
                            })
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
              doraIds: doraIds,
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
                            children: m.tiles.asMap().entries
                                .map((e) {
                                  final ti = e.key;
                                  final t = e.value;
                                  final isCalled = m.calledTile != null &&
                                      t.index == m.calledTile!.index;
                                  final isFaceDown = (m.type == 'ankan') &&
                                      (ti == 0 || ti == 3);
                                  Widget tileWidget = isFaceDown
                                      ? _faceDownTile(faceDownSize * 0.6)
                                      : TileWidget(
                                          tile: t,
                                          size: faceDownSize * 0.6,
                                        );
                                  // isCalled牌はさらに90度追加回転（通常の90度に重ねて横向き）
                                  const baseAngle = 1.5708; // math.pi / 2 (既存の回転)
                                  final extraAngle = isCalled ? math.pi / 2 : 0.0;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 2),
                                    child: Transform.rotate(
                                      angle: baseAngle + extraAngle,
                                      child: tileWidget,
                                    ),
                                  );
                                })
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
              doraIds: doraIds,
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
              doraIds: doraIds,
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
                            children: m.tiles.asMap().entries
                                .map((e) {
                                  final ti = e.key;
                                  final t = e.value;
                                  final isCalled = m.calledTile != null &&
                                      t.index == m.calledTile!.index;
                                  final isFaceDown = (m.type == 'ankan') &&
                                      (ti == 0 || ti == 3);
                                  Widget tileWidget = isFaceDown
                                      ? _faceDownTile(faceDownSize * 0.6)
                                      : TileWidget(
                                          tile: t,
                                          size: faceDownSize * 0.6,
                                        );
                                  const baseAngle = -1.5708; // 既存の回転
                                  final extraAngle = isCalled ? math.pi / 2 : 0.0;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 2),
                                    child: Transform.rotate(
                                      angle: baseAngle + extraAngle,
                                      child: tileWidget,
                                    ),
                                  );
                                })
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
