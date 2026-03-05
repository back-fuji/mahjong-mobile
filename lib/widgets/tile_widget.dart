import 'package:flutter/material.dart';

import '../models/tile_instance.dart';

/// Japanese tile names: 0-8 manzu, 9-17 pinzu, 18-26 souzu, 27-33 jihai
const List<String> _tileNames = [
  '一萬', '二萬', '三萬', '四萬', '五萬', '六萬', '七萬', '八萬', '九萬',
  '一筒', '二筒', '三筒', '四筒', '五筒', '六筒', '七筒', '八筒', '九筒',
  '一索', '二索', '三索', '四索', '五索', '六索', '七索', '八索', '九索',
  '東', '南', '西', '北', '白', '發', '中',
];

String tileLabel(int tileId, {bool isRed = false}) {
  if (tileId < 0 || tileId >= _tileNames.length) return '?';
  final name = _tileNames[tileId];
  if (isRed && (tileId == 4 || tileId == 12 || tileId == 22)) return '赤$name';
  return name;
}

/// ドラ指示牌からドラ牌IDを計算
int indicatorToDora(int indicatorId) {
  // 萬子 (0-8)
  if (indicatorId >= 0 && indicatorId <= 8) {
    return indicatorId == 8 ? 0 : indicatorId + 1;
  }
  // 筒子 (9-17)
  if (indicatorId >= 9 && indicatorId <= 17) {
    return indicatorId == 17 ? 9 : indicatorId + 1;
  }
  // 索子 (18-26)
  if (indicatorId >= 18 && indicatorId <= 26) {
    return indicatorId == 26 ? 18 : indicatorId + 1;
  }
  // 字牌 東南西北 (27-30) → 北東南西の順でサイクル
  if (indicatorId >= 27 && indicatorId <= 30) {
    return indicatorId == 30 ? 27 : indicatorId + 1;
  }
  // 字牌 白發中 (31-33) → 中白發の順でサイクル
  if (indicatorId >= 31 && indicatorId <= 33) {
    return indicatorId == 33 ? 31 : indicatorId + 1;
  }
  return indicatorId;
}

/// Asset path for tile image. Matches mahjong-app getTileImagePath (tiles from public/tiles).
String tileAssetPath(int tileId, {bool isRed = false}) {
  if (isRed) {
    if (tileId == 4) return 'assets/tiles/aka3-66-90-l.png'; // 赤五萬
    if (tileId == 13) return 'assets/tiles/aka1-66-90-l.png'; // 赤五筒
    if (tileId == 22) return 'assets/tiles/aka2-66-90-l.png'; // 赤五索
  }
  if (tileId >= 0 && tileId <= 8) {
    return 'assets/tiles/man${tileId + 1}-66-90-l.png';
  }
  if (tileId >= 9 && tileId <= 17) {
    return 'assets/tiles/pin${tileId - 8}-66-90-l.png';
  }
  if (tileId >= 18 && tileId <= 26) {
    return 'assets/tiles/sou${tileId - 17}-66-90-l.png';
  }
  // 27=東, 28=南, 29=西, 30=北, 31=白, 32=發, 33=中 (mahjong-app tile.ts)
  const jiPaths = {
    27: 'assets/tiles/ji1-66-90-l.png', // 東
    28: 'assets/tiles/ji2-66-90-l.png', // 南
    29: 'assets/tiles/ji3-66-90-l.png', // 西
    30: 'assets/tiles/ji4-66-90-l.png', // 北
    31: 'assets/tiles/ji6-66-90-l.png', // 白
    32: 'assets/tiles/ji5-66-90-l.png', // 發
    33: 'assets/tiles/ji7-66-90-l.png', // 中
  };
  final ji = jiPaths[tileId];
  if (ji != null) return ji;
  return 'assets/tiles/man1-66-90-l.png';
}

/// Single tile display. Uses images from mahjong-app/public/tiles.
class TileWidget extends StatelessWidget {
  const TileWidget({
    super.key,
    required this.tile,
    this.size = 40,
    this.selected = false,
    this.isDora = false,
    this.onTap,
  });

  final TileInstance tile;
  final double size;
  final bool selected;
  final bool isDora;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final path = tileAssetPath(tile.id, isRed: tile.isRed);
    final height = size * 1.35;

    Widget child = Container(
      width: size,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: selected
              ? Colors.amber.shade700
              : isDora
                  ? Colors.red.shade400
                  : Colors.transparent,
          width: selected ? 3 : isDora ? 2 : 0,
        ),
        boxShadow: selected
            ? [BoxShadow(color: Colors.amber.shade200.withValues(alpha: 0.5), blurRadius: 4)]
            : isDora
                ? [BoxShadow(color: Colors.red.shade300.withValues(alpha: 0.4), blurRadius: 4)]
                : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _fallbackTile(),
      ),
    );

    if (onTap != null) {
      child = GestureDetector(onTap: onTap, child: child);
    }
    return child;
  }

  Widget _fallbackTile() {
    final label = tileLabel(tile.id, isRed: tile.isRed);
    final isMan = tile.id >= 0 && tile.id <= 8;
    final isPin = tile.id >= 9 && tile.id <= 17;
    final isSou = tile.id >= 18 && tile.id <= 26;
    final color = tile.isRed
        ? Colors.red.shade700
        : (isMan
            ? Colors.brown.shade800
            : (isPin ? Colors.blue.shade800 : (isSou ? Colors.green.shade800 : Colors.black87)));
    return Container(
      color: Colors.amber.shade50,
      child: Center(
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: size * 0.35, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
