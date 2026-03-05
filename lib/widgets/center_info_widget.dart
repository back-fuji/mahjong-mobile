import 'package:flutter/material.dart';

import '../models/player_filtered.dart';
import '../models/round_state.dart';
import '../models/tile_instance.dart';
import 'tile_widget.dart';

const List<String> _windNames = ['東', '南', '西', '北'];

/// Center info: round label, 4 players (wind + score) in diamond, dora.
class CenterInfoWidget extends StatelessWidget {
  const CenterInfoWidget({
    super.key,
    required this.round,
    required this.players,
    required this.currentPlayer,
    required this.doraIndicators,
    required this.myIndex,
    this.compact = true,
  });

  final RoundState round;
  final List<PlayerFiltered> players;
  final int currentPlayer;
  final List<TileInstance> doraIndicators;
  final int myIndex;
  final bool compact;

  int _rel(int offset) => (myIndex + offset) % 4;

  @override
  Widget build(BuildContext context) {
    final bakazeStr = _windNames[round.bakaze];
    final kyokuNum = (round.kyoku % 4) + 1;
    final roundLabel = '$bakazeStr$kyokuNum局';

    final topP = players[_rel(2)];
    final rightP = players[_rel(1)];
    final bottomP = players[_rel(0)];
    final leftP = players[_rel(3)];

    final tileSize = compact ? 18.0 : 28.0;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.shade900.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            roundLabel,
            style: TextStyle(
              color: Colors.amber.shade300,
              fontWeight: FontWeight.bold,
              fontSize: compact ? 12 : 16,
            ),
          ),
          Text(
            '残り${round.remainingTiles}枚${round.honba > 0 ? ' ${round.honba}本場' : ''}${round.riichiSticks > 0 ? ' 供託${round.riichiSticks}' : ''}',
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: compact ? 9 : 12,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: compact ? 160 : 240,
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: 1.2,
              children: [
                const SizedBox(),
                _PlayerCell(
                  player: topP,
                  playerIndex: _rel(2),
                  currentPlayer: currentPlayer,
                ),
                const SizedBox(),
                _PlayerCell(
                  player: leftP,
                  playerIndex: _rel(3),
                  currentPlayer: currentPlayer,
                ),
                const SizedBox(),
                _PlayerCell(
                  player: rightP,
                  playerIndex: _rel(1),
                  currentPlayer: currentPlayer,
                ),
                const SizedBox(),
                _PlayerCell(
                  player: bottomP,
                  playerIndex: _rel(0),
                  currentPlayer: currentPlayer,
                ),
                const SizedBox(),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ドラ',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: compact ? 8 : 12,
                ),
              ),
              const SizedBox(width: 4),
              ...List.generate(5, (i) {
                if (i < doraIndicators.length) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: TileWidget(tile: doraIndicators[i], size: tileSize),
                  );
                }
                return Container(
                  width: tileSize,
                  height: tileSize * 1.2,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green.shade700),
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.green.shade800.withValues(alpha: 0.3),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayerCell extends StatelessWidget {
  const _PlayerCell({
    required this.player,
    required this.playerIndex,
    required this.currentPlayer,
  });

  final PlayerFiltered player;
  final int playerIndex;
  final int currentPlayer;

  @override
  Widget build(BuildContext context) {
    final isDealer = player.seatWind == 0;
    final isCurrent = playerIndex == currentPlayer;

    Color bg;
    if (isDealer) {
      bg = isCurrent
          ? Colors.red.shade500
          : Colors.red.shade900.withValues(alpha: 0.5);
    } else {
      bg = isCurrent
          ? Colors.amber.shade700.withValues(alpha: 0.4)
          : Colors.green.shade800.withValues(alpha: 0.5);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isCurrent ? Colors.amber : Colors.grey.shade600,
          width: isCurrent ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${_windNames[player.seatWind]}${isDealer ? '親' : ''}',
            style: TextStyle(
              color: isDealer
                  ? Colors.red.shade200
                  : (isCurrent ? Colors.amber.shade200 : Colors.grey.shade300),
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          Text(
            player.score.toString(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
