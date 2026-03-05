# Mahjong Mobile 未再現・バグ修正 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 元アプリ(mahjong-app)との機能・デザイン差異9箇所およびバグを修正し、Flutter版を元アプリと同等の品質にする

**Architecture:** Flutter widgets を最小限変更。既存コンポーネント単位で修正し、新規ウィジェットは演出系のみ追加。データは既存モデル（calledTile等）を活用する。

**Tech Stack:** Flutter/Dart、既存 assets/tiles 画像

---

## Task 1: 捨て牌プールのリーチ牌横向き表示

**Files:**
- Modify: `lib/widgets/discard_pool_widget.dart`

### Step 1: 現状確認

`_rowTiles`メソッドが`riichiDiscardIndex`を受け取っていないことを確認。

### Step 2: 実装

`_rowTiles`に`globalOffset`パラメータを追加し、リーチ宣言牌インデックスと一致する牌を横向き表示する。

`lib/widgets/discard_pool_widget.dart` の `_rowTiles` を以下に変更:

```dart
List<Widget> _rowTiles(
  List<TileInstance> row,
  int rowIndex, {
  double rotationDeg = 0,
}) {
  return row.asMap().entries.map((e) {
    final colIndex = e.key;
    final tile = e.value;
    final globalIdx = rowIndex * 6 + colIndex;
    final isRiichi = riichiDiscardIndex >= 0 && globalIdx == riichiDiscardIndex;

    Widget w = SizedBox(
      width: isRiichi ? tileHeight : tileWidth,
      height: isRiichi ? tileWidth : tileHeight,
      child: isRiichi
          ? Transform.rotate(
              angle: math.pi / 2,
              child: SizedBox(
                width: tileWidth,
                height: tileHeight,
                child: TileWidget(
                  tile: tile,
                  size: math.min(tileWidth, tileHeight * 0.85),
                ),
              ),
            )
          : TileWidget(
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
```

### Step 3: 動作確認

リーチ宣言時に捨て牌プールの対応牌が横向きになることを確認。

### Step 4: コミット

```bash
git add lib/widgets/discard_pool_widget.dart
git commit -m "fix: リーチ宣言牌の横向き表示を実装"
```

---

## Task 2: メルドのcalledTile横向き・暗カン裏向き表示

**Files:**
- Modify: `lib/widgets/opponent_area_widget.dart`
- Modify: `lib/screens/game_screen.dart`

### Step 1: opponent_area_widget.dart の修正

`top`/`left`/`right` 各ケースのメルド表示部分で、calledTile照合と暗カン裏向きを実装。

`OpponentPosition.top` のメルド部分（line 66-88）を以下に変更:

```dart
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
              Widget tile = isFaceDown
                  ? _faceDownTile(faceDownSize * 0.9)
                  : TileWidget(
                      tile: t,
                      size: faceDownSize * 0.9,
                    );
              if (isCalled) {
                tile = Transform.rotate(
                  angle: math.pi / 2,
                  child: tile,
                );
              }
              return Padding(
                padding: const EdgeInsets.only(right: 2),
                child: tile,
              );
            })
            .toList(),
      ),
    ),
  ),
],
```

`left`/`right` 各ケースの melds 表示も同様に修正（90度回転の上にisCalled/ankan処理を追加）。

`import 'dart:math' as math;` を追加。

### Step 2: game_screen.dart の自分メルド表示修正

`lib/screens/game_screen.dart` の自分のメルド表示部分（line 170-183）を以下に変更:

```dart
children: myPlayer.melds.map((m) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: m.tiles.asMap().entries.map((e) {
      final ti = e.key;
      final t = e.value;
      final isCalled = m.calledTile != null &&
          t.index == m.calledTile!.index;
      final isFaceDown = (m.type == 'ankan') &&
          (ti == 0 || ti == 3);
      Widget tile = isFaceDown
          ? Container(
              width: 28,
              height: 28 * 1.35,
              decoration: BoxDecoration(
                color: Colors.green.shade900,
                border: Border.all(color: Colors.amber.shade700),
                borderRadius: BorderRadius.circular(2),
              ),
            )
          : TileWidget(tile: t, size: 28);
      if (isCalled) {
        tile = Transform.rotate(
          angle: math.pi / 2,
          child: tile,
        );
      }
      return Padding(
        padding: const EdgeInsets.only(right: 2),
        child: tile,
      );
    }).toList(),
  );
}).toList(),
```

`import 'dart:math' as math;` を game_screen.dart に追加。

### Step 3: コミット

```bash
git add lib/widgets/opponent_area_widget.dart lib/screens/game_screen.dart
git commit -m "fix: メルドのcalledTile横向き・暗カン裏向き表示を実装"
```

---

## Task 3: ChiSelectorの牌名テキスト改善

**Files:**
- Modify: `lib/screens/game_screen.dart`

### Step 1: `_buildChiSelectorCard` の修正

`tileLabel` を使って牌名を表示する。`tile_widget.dart` から `tileLabel` をimportして使用。

`game_screen.dart` の chi selector ボタンのchildを変更:

```dart
// 変更前
child: Text(opt.tiles.join(', ')),

// 変更後
child: Row(
  mainAxisSize: MainAxisSize.min,
  mainAxisAlignment: MainAxisAlignment.center,
  children: opt.tiles.map((tileId) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(
      tileLabel(tileId),
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  )).toList(),
),
```

`tileLabel` は `lib/widgets/tile_widget.dart` に定義済みなので import を追加:
```dart
import '../widgets/tile_widget.dart';
```

### Step 2: コミット

```bash
git add lib/screens/game_screen.dart
git commit -m "fix: ChiSelectorの選択肢を牌ID数値から牌名テキストに変更"
```

---

## Task 4: 喰い替え禁止牌のdimmed表示

**Files:**
- Modify: `lib/widgets/hand_widget.dart`
- Modify: `lib/screens/game_screen.dart`

### Step 1: HandWidget に dimmedTileIds パラメータ追加

`lib/widgets/hand_widget.dart` を以下に変更:

```dart
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
```

### Step 2: GameScreen から dimmedTileIds を渡す

`lib/screens/game_screen.dart` の HandWidget 呼び出し部分（line 198-204）に追加:

```dart
HandWidget(
  closed: myPlayer.closed ?? [],
  tsumo: myPlayer.tsumo,
  selectedTileIndex: _selectedTile?.index,
  onTileTap: (tile) => _onHandTileTap(tile, canDiscard),
  tileSize: 44,
  dimmedTileIds: myPlayer.kuikaeDisallowedTiles ?? [],
),
```

### Step 3: コミット

```bash
git add lib/widgets/hand_widget.dart lib/screens/game_screen.dart
git commit -m "fix: 喰い替え禁止牌のdimmed（グレーアウト）表示を実装"
```

---

## Task 5: リーチ後自動ツモ切り

**Files:**
- Modify: `lib/screens/game_screen.dart`

### Step 1: `_GameScreenState` にdidAutoDiscardRefを追加

以下のフィールドを `_GameScreenState` に追加:
```dart
bool _didAutoDiscardRiichi = false;
```

### Step 2: didUpdateWidget で自動ツモ切りをトリガー

`_GameScreenState` に `didUpdateWidget` を追加:

```dart
@override
void didUpdateWidget(GameScreen oldWidget) {
  super.didUpdateWidget(oldWidget);
  _checkAutoDiscard();
}

void _checkAutoDiscard() {
  final myPlayer = gs.players[gs.myIndex];
  final isRiichiDiscardTurn = gs.phase == 'discard' &&
      gs.currentPlayer == gs.myIndex &&
      myPlayer.isRiichi &&
      myPlayer.tsumo != null;

  if (isRiichiDiscardTurn && !_didAutoDiscardRiichi) {
    _didAutoDiscardRiichi = true;
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted && gs.phase == 'discard' &&
          gs.currentPlayer == gs.myIndex &&
          gs.players[gs.myIndex].isRiichi) {
        final tsumo = gs.players[gs.myIndex].tsumo;
        if (tsumo != null) {
          widget.socketService.sendAction({
            'type': 'discard',
            'tileIndex': tsumo.index,
          });
        }
      }
    });
  } else if (!isRiichiDiscardTurn) {
    _didAutoDiscardRiichi = false;
  }
}
```

### Step 3: コミット

```bash
git add lib/screens/game_screen.dart
git commit -m "fix: リーチ後の自動ツモ切りを実装"
```

---

## Task 6: 鳴き・リーチ演出ウィジェット

**Files:**
- Create: `lib/widgets/announcement_overlay.dart`
- Modify: `lib/screens/game_screen.dart`

### Step 1: announcement_overlay.dart を作成

```dart
import 'package:flutter/material.dart';

/// ポン/チー/カン/リーチ等のアナウンスオーバーレイ
class AnnouncementOverlay extends StatefulWidget {
  const AnnouncementOverlay({super.key, required this.text});
  final String text;

  @override
  State<AnnouncementOverlay> createState() => _AnnouncementOverlayState();
}

class _AnnouncementOverlayState extends State<AnnouncementOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: child,
          ),
        ),
        child: Center(
          child: Text(
            widget.text,
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(2, 2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### Step 2: GameScreenState に演出状態を追加

`_GameScreenState` に追加:
```dart
String? _announcementText;
int _prevMeldTotal = 0;
bool _prevRiichi = false;
```

`didUpdateWidget` 内に追加（`_checkAutoDiscard()` 呼び出しの後):

```dart
void _checkAnnouncements(GameScreen oldWidget) {
  // 鳴き検知
  final newTotal = gs.players.fold<int>(0, (s, p) => s + p.melds.length);
  if (newTotal > _prevMeldTotal) {
    // 最後に増えたプレイヤーを探す
    for (final p in gs.players) {
      final oldP = oldWidget.gameState.players.firstWhere(
        (op) => op.id == p.id,
        orElse: () => p,
      );
      if (p.melds.length > oldP.melds.length && p.melds.isNotEmpty) {
        final meld = p.melds.last;
        final callName = meld.type == 'chi' ? 'チー'
            : meld.type == 'pon' ? 'ポン'
            : (meld.type == 'minkan' || meld.type == 'ankan' || meld.type == 'shouminkan')
                ? 'カン'
                : null;
        if (callName != null) {
          setState(() => _announcementText = callName);
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) setState(() => _announcementText = null);
          });
        }
        break;
      }
    }
  }
  _prevMeldTotal = newTotal;

  // リーチ検知
  final myPlayer = gs.players[gs.myIndex];
  if (myPlayer.isRiichi && !_prevRiichi) {
    setState(() => _announcementText = 'リーチ');
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _announcementText = null);
    });
  }
  _prevRiichi = myPlayer.isRiichi;
}
```

`didUpdateWidget` から `_checkAnnouncements(oldWidget)` を呼び出す。

`initState` で初期値設定:
```dart
@override
void initState() {
  super.initState();
  // ... 既存コード ...
  _prevMeldTotal = widget.gameState.players.fold<int>(0, (s, p) => s + p.melds.length);
  _prevRiichi = widget.gameState.players[widget.gameState.myIndex].isRiichi;
}
```

### Step 3: Stackにオーバーレイを追加

`build` メソッドの Stack children に追加（ChiSelector の直前):

```dart
// アナウンスオーバーレイ
if (_announcementText != null)
  Positioned.fill(
    child: AnnouncementOverlay(
      key: ValueKey(_announcementText),
      text: _announcementText!,
    ),
  ),
```

`import '../widgets/announcement_overlay.dart';` を追加。

### Step 4: コミット

```bash
git add lib/widgets/announcement_overlay.dart lib/screens/game_screen.dart
git commit -m "feat: ポン/チー/カン/リーチのアナウンスオーバーレイを追加"
```

---

## Task 7: ドラハイライト（手牌・捨て牌）

**Files:**
- Modify: `lib/widgets/tile_widget.dart`
- Modify: `lib/widgets/hand_widget.dart`
- Modify: `lib/widgets/discard_pool_widget.dart`
- Modify: `lib/widgets/opponent_area_widget.dart`
- Modify: `lib/screens/game_screen.dart`

### Step 1: indicatorToDora 関数を tile_widget.dart に追加

`lib/widgets/tile_widget.dart` に追加:

```dart
/// ドラ指示牌からドラ牌IDを計算 (元アプリ indicatorToDora と同ロジック)
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
  // 字牌: 東南西北 (27-30) → 北東南西、白發中 (31-33)
  if (indicatorId >= 27 && indicatorId <= 30) {
    return indicatorId == 30 ? 27 : indicatorId + 1;
  }
  if (indicatorId >= 31 && indicatorId <= 33) {
    return indicatorId == 33 ? 31 : indicatorId + 1;
  }
  return indicatorId;
}
```

### Step 2: TileWidget に isDora パラメータ追加

`lib/widgets/tile_widget.dart` の TileWidget クラス:

```dart
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
  // ... _fallbackTile は変更なし
}
```

### Step 3: HandWidget に doraIds パラメータ追加

`lib/widgets/hand_widget.dart`:

```dart
class HandWidget extends StatelessWidget {
  const HandWidget({
    super.key,
    required this.closed,
    this.tsumo,
    required this.selectedTileIndex,
    required this.onTileTap,
    this.tileSize = 36,
    this.dimmedTileIds = const [],
    this.doraIds = const {},
  });

  // ... 既存フィールド ...
  final Set<int> doraIds;
```

TileWidget 呼び出し時に `isDora: doraIds.contains(t.id)` を追加。

### Step 4: DiscardPoolWidget に doraIds パラメータ追加

`lib/widgets/discard_pool_widget.dart`:

コンストラクタに `this.doraIds = const {}` を追加。フィールド: `final Set<int> doraIds;`

`_rowTiles` に `doraIds` を引き回し、TileWidget に `isDora: doraIds.contains(tile.id)` を追加。

### Step 5: GameScreen でドラIDセットを計算して渡す

`lib/screens/game_screen.dart` の `build` メソッド内に追加:

```dart
// ドラIDセット計算
final doraIds = <int>{};
for (final indicator in gs.doraIndicators) {
  doraIds.add(indicatorToDora(indicator.id));
}
```

HandWidget と各 OpponentArea/DiscardPool に `doraIds` を渡す。

`import '../widgets/tile_widget.dart';` は既存なので `indicatorToDora` を追加インポートなしで利用。

### Step 6: コミット

```bash
git add lib/widgets/tile_widget.dart lib/widgets/hand_widget.dart \
  lib/widgets/discard_pool_widget.dart lib/widgets/opponent_area_widget.dart \
  lib/screens/game_screen.dart
git commit -m "feat: ドラ牌の赤枠ハイライト表示を実装"
```

---

## Task 8: 最後の捨て牌ハイライト

**Files:**
- Modify: `lib/widgets/discard_pool_widget.dart`
- Modify: `lib/widgets/opponent_area_widget.dart`
- Modify: `lib/screens/game_screen.dart`

### Step 1: DiscardPoolWidget に highlightLastDiscard パラメータ追加

`lib/widgets/discard_pool_widget.dart` コンストラクタに追加:
```dart
this.highlightLastDiscard = false,
```
フィールド: `final bool highlightLastDiscard;`

`_rowTiles` 内で最後の牌を判定:
```dart
final isLast = highlightLastDiscard &&
    (rowIndex * 6 + colIndex == discards.length - 1);
```

最後の牌のTileWidgetに `selected: isLast`（または別のハイライト色）を渡す。
**注**: selectedとは別に`highlightLast`専用の視覚フィードバックとして黄色枠を使用。TileWidgetに`highlighted`パラメータを追加するか、`selected`を流用する。シンプルに`selected`を流用して問題ない。

### Step 2: OpponentAreaWidget と GameScreen から highlightLastDiscard を渡す

`lib/screens/game_screen.dart` で `gs.lastDiscard` を使用:
- 各対面プレイヤーの OpponentAreaWidget に `highlightLastDiscardPlayerIndex` 情報を渡す
- `lastDiscard?.playerIndex` と対面プレイヤーのインデックスが一致する場合に `highlightLastDiscard: true` を設定

`lib/widgets/opponent_area_widget.dart` の DiscardPoolWidget 呼び出しに追加。

### Step 3: コミット

```bash
git add lib/widgets/discard_pool_widget.dart lib/widgets/opponent_area_widget.dart \
  lib/screens/game_screen.dart
git commit -m "fix: 最後の捨て牌ハイライト表示を実装"
```

---

## Task 9: 局結果モーダルに役・翻数・符数・手牌公開を追加

**Files:**
- Modify: `lib/screens/game_screen.dart`

### Step 1: scoreResult の構造を把握

`AgariResultData.scoreResult` は `Map<String,dynamic>?`。サーバーから送られる構造（元アプリ `score-calc.ts` より）:
```json
{
  "yaku": [{ "name": "...", "han": 1, "isYakuman": false }],
  "han": 3,
  "fu": 30,
  "isYakuman": false,
  "payment": { "total": 5800 },
  "label": "満貫"
}
```

### Step 2: `_buildRoundResultOverlay` を拡張

`lib/screens/game_screen.dart` の `_buildRoundResultOverlay` を以下に変更:

```dart
Widget _buildRoundResultOverlay() {
  final result = gs.roundResult!;
  final hasAgari = result.agari != null && result.agari!.isNotEmpty;

  return Container(
    color: Colors.black54,
    child: Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasAgari) ..._buildAgariResult(result.agari!.first)
                else if (result.draw != null) ..._buildDrawResult(result.draw!)
                else const Text('局終了'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () =>
                        widget.socketService.sendAction({'type': 'next_round'}),
                    child: const Text('次局'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

List<Widget> _buildAgariResult(AgariResultData agari) {
  final winner = gs.players[agari.winner];
  final score = agari.scoreResult;
  final yaku = score != null ? (score['yaku'] as List<dynamic>?) ?? [] : [];
  final han = score?['han'] as int?;
  final fu = score?['fu'] as int?;
  final isYakuman = score?['isYakuman'] as bool? ?? false;
  final payment = score?['payment'] as Map<String, dynamic>?;
  final total = payment?['total'] as int?;
  final label = score?['label'] as String?;

  return [
    Text(
      agari.isTsumo ? 'ツモ' : 'ロン',
      style: TextStyle(
        color: Colors.orange.shade400,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    ),
    const SizedBox(height: 8),
    Text(
      '${_windName(winner.seatWind)} ${winner.name}',
      style: const TextStyle(fontSize: 16),
    ),
    if (!agari.isTsumo && agari.loser >= 0)
      Text(
        '← ${gs.players[agari.loser].name} 放銃',
        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
      ),
    const SizedBox(height: 12),

    // 和了者の手牌
    if (winner.closed != null && winner.closed!.isNotEmpty) ...[
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 2,
          runSpacing: 2,
          children: [
            ...winner.closed!.map((t) => TileWidget(tile: t, size: 28)),
            if (winner.tsumo != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: TileWidget(
                  tile: winner.tsumo!,
                  size: 28,
                  selected: true,
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
    ],

    // 役一覧
    if (yaku.isNotEmpty) ...[
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            ...yaku.map((y) {
              final yakuMap = y as Map<String, dynamic>;
              final yakuName = yakuMap['name'] as String? ?? '';
              final yakuHan = yakuMap['han'] as int? ?? 0;
              final yakuIsYakuman = yakuMap['isYakuman'] as bool? ?? false;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(yakuName, style: const TextStyle(fontSize: 13)),
                    Text(
                      yakuIsYakuman ? '役満' : '$yakuHan翻',
                      style: TextStyle(
                        color: yakuIsYakuman
                            ? Colors.red.shade400
                            : Colors.amber.shade400,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }),
            Divider(color: Colors.grey.shade700),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('合計', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                Text(
                  isYakuman ? '役満' : '${han ?? 0}翻 ${fu ?? 0}符',
                  style: TextStyle(
                    color: Colors.orange.shade300,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
    ],

    // 点数
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade900.withValues(alpha: 0.3), Colors.orange.shade800.withValues(alpha: 0.2)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          if (label != null && label.isNotEmpty)
            Text(
              label,
              style: TextStyle(color: Colors.orange.shade300, fontSize: 14),
            ),
          Text(
            total != null ? '${total}点' : '${winner.score}点',
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  ];
}

List<Widget> _buildDrawResult(DrawResultData draw) {
  return [
    const Text(
      '流局',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 8),
    Text(
      draw.tenpaiPlayers.isEmpty
          ? '全員ノーテン'
          : 'テンパイ: ${draw.tenpaiPlayers.map((i) => gs.players[i].name).join(', ')}',
      style: TextStyle(color: Colors.grey.shade300),
    ),
    if (draw.tenpaiPlayers.isNotEmpty && draw.tenpaiPlayers.length < 4)
      Text('ノーテン罰符あり', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
  ];
}
```

### Step 3: コミット

```bash
git add lib/screens/game_screen.dart
git commit -m "feat: 局結果モーダルに役・翻数・符数・手牌公開を追加"
```

---

## 最終確認

全タスク完了後:
1. `flutter analyze` でエラーがないことを確認
2. シミュレーターで起動してゲーム画面の動作確認
3. 特に確認: リーチ牌横向き、ポン後のメルド表示、Chi選択肢の牌名

```bash
cd /Users/goto/WorkCase/mahjong-mobile
flutter analyze
```
