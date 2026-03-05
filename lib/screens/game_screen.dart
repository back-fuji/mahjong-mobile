import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_state_filtered.dart';
import '../models/player_filtered.dart';
import '../models/tile_instance.dart';
import '../services/socket_service.dart';
import '../widgets/action_bar.dart';
import '../widgets/center_info_widget.dart';
import '../widgets/discard_pool_widget.dart';
import '../widgets/hand_widget.dart';
import '../widgets/opponent_area_widget.dart';
import '../widgets/announcement_overlay.dart';
import '../widgets/tile_widget.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.socketService,
    required this.gameState,
    required this.onBack,
  });

  final SocketService socketService;
  final GameStateFiltered gameState;
  final VoidCallback onBack;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  TileInstance? _selectedTile;
  bool _showChiSelector = false;
  // リーチ後の自動ツモ切り二重送信防止フラグ
  bool _didAutoDiscardRiichi = false;
  // アナウンスオーバーレイ用
  String? _announcementText;
  int _prevMeldTotal = 0;
  bool _prevMyRiichi = false;

  GameStateFiltered get gs => widget.gameState;
  int get myIndex => gs.myIndex;
  PlayerFiltered get myPlayer => gs.players[myIndex];

  int _rel(int offset) => (myIndex + offset) % 4;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _prevMeldTotal = widget.gameState.players.fold<int>(0, (s, p) => s + p.melds.length);
    _prevMyRiichi = widget.gameState.players[widget.gameState.myIndex].isRiichi;
  }

  @override
  void didUpdateWidget(GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAutoDiscard();
    _checkAnnouncements(oldWidget);
  }

  /// リーチ中のツモ番で自動ツモ切りを行う
  void _checkAutoDiscard() {
    final myPlayer = gs.players[gs.myIndex];
    final isRiichiDiscardTurn = gs.phase == 'discard' &&
        gs.currentPlayer == gs.myIndex &&
        myPlayer.isRiichi &&
        myPlayer.tsumo != null;

    if (isRiichiDiscardTurn && !_didAutoDiscardRiichi) {
      _didAutoDiscardRiichi = true;
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        final currentPlayer = gs.players[gs.myIndex];
        if (gs.phase == 'discard' &&
            gs.currentPlayer == gs.myIndex &&
            currentPlayer.isRiichi) {
          final tsumo = currentPlayer.tsumo;
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

  /// 鳴き・リーチのアナウンスオーバーレイを表示する
  void _checkAnnouncements(GameScreen oldWidget) {
    // 鳴き検知: メルド総数の増加を確認
    final newTotal = gs.players.fold<int>(0, (s, p) => s + p.melds.length);
    if (newTotal > _prevMeldTotal) {
      for (int i = 0; i < gs.players.length; i++) {
        final newCount = gs.players[i].melds.length;
        final oldCount = i < oldWidget.gameState.players.length
            ? oldWidget.gameState.players[i].melds.length
            : 0;
        if (newCount > oldCount && gs.players[i].melds.isNotEmpty) {
          final meld = gs.players[i].melds.last;
          final callName = meld.type == 'chi'
              ? 'チー'
              : meld.type == 'pon'
                  ? 'ポン'
                  : (meld.type == 'minkan' ||
                          meld.type == 'ankan' ||
                          meld.type == 'shouminkan')
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

    // リーチ検知: 自分のリーチ状態変化
    final myRiichi = gs.players[gs.myIndex].isRiichi;
    if (myRiichi && !_prevMyRiichi) {
      setState(() => _announcementText = 'リーチ');
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _announcementText = null);
      });
    }
    _prevMyRiichi = myRiichi;
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canDiscard = gs.availableActions.contains('discard');
    final canCall = gs.availableActions.any(
      (a) => ['pon', 'chi', 'ron'].contains(a),
    );

    // ドラ指示牌からドラ牌IDセットを計算
    final doraIds = <int>{};
    for (final indicator in gs.doraIndicators) {
      doraIds.add(indicatorToDora(indicator.id));
    }

    // 最後の捨て牌のプレイヤーインデックス（ハイライト表示用）
    final lastDiscardPlayerIndex = gs.lastDiscard?.playerIndex;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade900, Colors.green.shade800],
          ),
        ),
        child: SafeArea(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main 4-player layout: top+middle flexible, bottom fixed so hand is always at bottom
              Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top: opposite player
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          child: OpponentAreaWidget(
                            player: gs.players[_rel(2)],
                            position: OpponentPosition.top,
                            tileWidth: 32,
                            tileHeight: 44,
                            faceDownSize: 28,
                            doraIds: doraIds,
                            highlightLastDiscard: lastDiscardPlayerIndex == _rel(2),
                          ),
                        ),
                        // Middle: left | center | right
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: ClipRect(
                                    child: OpponentAreaWidget(
                                      player: gs.players[_rel(3)],
                                      position: OpponentPosition.left,
                                      tileWidth: 28,
                                      tileHeight: 38,
                                      faceDownSize: 20,
                                      doraIds: doraIds,
                                      highlightLastDiscard: lastDiscardPlayerIndex == _rel(3),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: CenterInfoWidget(
                                    round: gs.round,
                                    players: gs.players,
                                    currentPlayer: gs.currentPlayer,
                                    doraIndicators: gs.doraIndicators,
                                    myIndex: myIndex,
                                    compact: true,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: ClipRect(
                                    child: OpponentAreaWidget(
                                      player: gs.players[_rel(1)],
                                      position: OpponentPosition.right,
                                      tileWidth: 28,
                                      tileHeight: 38,
                                      faceDownSize: 20,
                                      doraIds: doraIds,
                                      highlightLastDiscard: lastDiscardPlayerIndex == _rel(1),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bottom: my melds + discards + hand (always at screen bottom)
                  Padding(
                    padding: EdgeInsets.only(
                      left: 8,
                      right: 8,
                      top: 4,
                      bottom: 4 + (gs.availableActions.isNotEmpty ? 56 : 0),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // My melds (pon/chi/kan)
                        if (myPlayer.melds.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
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
                                    Widget tileWidget = isFaceDown
                                        ? Container(
                                            width: 28,
                                            height: 28 * 1.35,
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade900,
                                              border: Border.all(
                                                  color: Colors.amber.shade700),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          )
                                        : TileWidget(tile: t, size: 28);
                                    if (isCalled) {
                                      tileWidget = Transform.rotate(
                                        angle: math.pi / 2,
                                        child: tileWidget,
                                      );
                                    }
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 2),
                                      child: tileWidget,
                                    );
                                  }).toList(),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                        ClipRect(
                          child: DiscardPoolWidget(
                            discards: myPlayer.discards,
                            riichiDiscardIndex: myPlayer.riichiDiscardIndex >= 0
                                ? myPlayer.riichiDiscardIndex
                                : -1,
                            tileWidth: 36,
                            tileHeight: 50,
                            position: DiscardPosition.bottom,
                            doraIds: doraIds,
                            highlightLastDiscard: lastDiscardPlayerIndex == myIndex,
                          ),
                        ),
                        const SizedBox(height: 8),
                        HandWidget(
                          closed: myPlayer.closed ?? [],
                          tsumo: myPlayer.tsumo,
                          selectedTileIndex: _selectedTile?.index,
                          onTileTap: (tile) => _onHandTileTap(tile, canDiscard),
                          tileSize: 44,
                          dimmedTileIds: myPlayer.kuikaeDisallowedTiles ?? [],
                          doraIds: doraIds,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Home button top-right
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.home, color: Colors.white),
                  onPressed: _onBackTap,
                ),
              ),
              // Phase message top-center
              Positioned(
                top: 4,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade400),
                    ),
                    child: Text(
                      _phaseMessage(canDiscard, canCall),
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              // Action bar: fixed bottom-left
              Positioned(
                bottom: 80,
                left: 8,
                child: ActionBarWidget(
                  availableActions: gs.availableActions,
                  onAction: _onAction,
                  chiOptionCount: gs.chiOptions.length,
                  kanTilesCount: gs.kanTiles.length,
                ),
              ),
              // Discard button when tile selected
              if (canDiscard && _selectedTile != null)
                Positioned(
                  bottom: 72,
                  left: 8,
                  child: Material(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        if (_selectedTile != null &&
                            !(myPlayer.kuikaeDisallowedTiles ?? []).contains(
                              _selectedTile!.id,
                            )) {
                          widget.socketService.sendAction({
                            'type': 'discard',
                            'tileIndex': _selectedTile!.index,
                          });
                          setState(() => _selectedTile = null);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          '打牌',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // アナウンスオーバーレイ
              if (_announcementText != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnnouncementOverlay(
                      key: ValueKey(_announcementText),
                      text: _announcementText!,
                    ),
                  ),
                ),
              // Chi selector overlay
              if (_showChiSelector)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: Center(child: _buildChiSelectorCard()),
                  ),
                ),
              // Round result modal
              if (gs.phase == 'round_result' && gs.roundResult != null)
                Positioned.fill(child: _buildRoundResultOverlay()),
            ],
          ),
        ),
      ),
    );
  }

  void _onHandTileTap(TileInstance tile, bool canDiscard) {
    final kuikae = myPlayer.kuikaeDisallowedTiles ?? [];
    if (kuikae.contains(tile.id)) return;
    if (canDiscard && gs.currentPlayer == myIndex) {
      if (_selectedTile?.index == tile.index) {
        widget.socketService.sendAction({
          'type': 'discard',
          'tileIndex': tile.index,
        });
        setState(() => _selectedTile = null);
      } else {
        setState(() => _selectedTile = tile);
      }
    }
  }

  String _phaseMessage(bool canDiscard, bool canCall) {
    if (gs.phase == 'round_result') return '局終了';
    if (canCall) return '鳴きまたはスキップ';
    if (canDiscard && gs.currentPlayer == myIndex) {
      return _selectedTile != null ? '打牌ボタンで捨てる' : '捨てる牌を選んでください';
    }
    return 'お待ちください...';
  }

  Future<void> _onBackTap() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ホームに戻る'),
        content: const Text('対局は中断されます。よろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('戻る'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) widget.onBack();
  }

  Widget _buildChiSelectorCard() {
    return Card(
      margin: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'チーする面子を選んでください',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...gs.chiOptions.map(
              (opt) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      setState(() => _showChiSelector = false);
                      widget.socketService.sendAction({
                        'type': 'chi',
                        'tiles': opt.tiles,
                      });
                    },
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
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _showChiSelector = false),
              child: const Text('キャンセル'),
            ),
          ],
        ),
      ),
    );
  }

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
                  if (hasAgari)
                    ..._buildAgariResult(result.agari!.first)
                  else if (result.draw != null)
                    ..._buildDrawResult(result.draw!)
                  else
                    const Text('局終了'),
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
    final tsumoKo = payment?['tsumoKo'] as int?;
    final tsumoOya = payment?['tsumoOya'] as int?;
    final label = score?['label'] as String?;

    return [
      // ツモ/ロン
      Text(
        agari.isTsumo ? 'ツモ' : 'ロン',
        style: TextStyle(
          color: Colors.orange.shade400,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      // 和了者名
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '和了者の手牌',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 2,
                runSpacing: 2,
                children: [
                  ...winner.closed!.map((t) => TileWidget(tile: t, size: 26)),
                  if (winner.tsumo != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: TileWidget(
                        tile: winner.tsumo!,
                        size: 26,
                        selected: true,
                      ),
                    ),
                ],
              ),
              // 副露
              if (winner.melds.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: winner.melds.map((m) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: m.tiles.asMap().entries.map((e) {
                        final ti = e.key;
                        final t = e.value;
                        final isCalled = m.calledTile != null &&
                            t.index == m.calledTile!.index;
                        final isFaceDown = (m.type == 'ankan') &&
                            (ti == 0 || ti == 3);
                        Widget w = isFaceDown
                            ? Container(
                                width: 22,
                                height: 22 * 1.35,
                                decoration: BoxDecoration(
                                  color: Colors.green.shade900,
                                  border: Border.all(color: Colors.amber.shade700),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              )
                            : TileWidget(tile: t, size: 22);
                        if (isCalled) {
                          w = Transform.rotate(angle: math.pi / 2, child: w);
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 1),
                          child: w,
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],

      // 役一覧
      if (yaku.isNotEmpty) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
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
              Divider(color: Colors.grey.shade700, height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '合計',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
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

      // 点数表示
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade900.withValues(alpha: 0.3),
              Colors.orange.shade800.withValues(alpha: 0.2),
            ],
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
              total != null ? '$total点' : '${winner.score}点',
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (agari.isTsumo && tsumoKo != null)
              Text(
                tsumoOya != null
                    ? '$tsumoKo点 / $tsumoOya点'
                    : '$tsumoKo点 オール',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
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
        style: TextStyle(color: Colors.grey.shade300, fontSize: 14),
      ),
      if (draw.tenpaiPlayers.isNotEmpty && draw.tenpaiPlayers.length < 4)
        Text(
          'ノーテン罰符あり',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        ),
    ];
  }

  String _windName(int seatWind) {
    const names = ['東', '南', '西', '北'];
    return seatWind >= 0 && seatWind < 4 ? names[seatWind] : '?';
  }

  void _onAction(String action, [Map<String, dynamic>? params]) {
    switch (action) {
      case 'tsumo_agari':
        widget.socketService.sendAction({'type': 'tsumo_agari'});
        break;
      case 'ron':
        widget.socketService.sendAction({'type': 'ron'});
        break;
      case 'riichi':
        if (_selectedTile != null) {
          widget.socketService.sendAction({
            'type': 'riichi',
            'tileIndex': _selectedTile!.index,
          });
          setState(() => _selectedTile = null);
        }
        break;
      case 'pon':
        widget.socketService.sendAction({'type': 'pon'});
        break;
      case 'chi':
        if (gs.chiOptions.length == 1) {
          widget.socketService.sendAction({
            'type': 'chi',
            'tiles': gs.chiOptions.first.tiles,
          });
        } else {
          setState(() => _showChiSelector = true);
        }
        break;
      case 'kan':
        if (gs.kanTiles.isNotEmpty) {
          widget.socketService.sendAction({
            'type': 'kan',
            'tileId': gs.kanTiles.first,
          });
        } else {
          widget.socketService.sendAction({'type': 'kan'});
        }
        break;
      case 'skip_call':
        widget.socketService.sendAction({'type': 'skip_call'});
        break;
      case 'kyuushu':
        widget.socketService.sendAction({'type': 'kyuushu'});
        break;
      case 'next_round':
        widget.socketService.sendAction({'type': 'next_round'});
        break;
    }
  }
}
