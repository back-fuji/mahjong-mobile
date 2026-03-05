import 'player_filtered.dart';
import 'round_state.dart';
import 'tile_instance.dart';
import 'meld.dart';

/// Round result (agari or draw). Simplified for UI.
class RoundResultData {
  final List<AgariResultData>? agari;
  final DrawResultData? draw;

  const RoundResultData({this.agari, this.draw});

  factory RoundResultData.fromJson(Map<String, dynamic> json) {
    final agariList = json['agari'] as List<dynamic>?;
    return RoundResultData(
      agari: agariList != null
          ? agariList.map((e) => AgariResultData.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      draw: json['draw'] != null
          ? DrawResultData.fromJson(json['draw'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AgariResultData {
  final int winner;
  final int loser;
  final bool isTsumo;
  final Map<String, dynamic>? scoreResult;

  const AgariResultData({
    required this.winner,
    required this.loser,
    required this.isTsumo,
    this.scoreResult,
  });

  factory AgariResultData.fromJson(Map<String, dynamic> json) {
    return AgariResultData(
      winner: json['winner'] as int,
      loser: json['loser'] as int,
      isTsumo: json['isTsumo'] as bool? ?? false,
      scoreResult: json['scoreResult'] as Map<String, dynamic>?,
    );
  }
}

class DrawResultData {
  final String type;
  final List<int> tenpaiPlayers;
  final List<int> payments;

  const DrawResultData({
    required this.type,
    required this.tenpaiPlayers,
    required this.payments,
  });

  factory DrawResultData.fromJson(Map<String, dynamic> json) {
    final tenpaiList = json['tenpaiPlayers'] as List<dynamic>?;
    final payList = json['payments'] as List<dynamic>?;
    return DrawResultData(
      type: json['type'] as String,
      tenpaiPlayers: tenpaiList != null ? tenpaiList.map((e) => e as int).toList() : [],
      payments: payList != null ? payList.map((e) => e as int).toList() : [],
    );
  }
}

/// Last discard: tile + playerIndex
class LastDiscardData {
  final TileInstance tile;
  final int playerIndex;

  const LastDiscardData({required this.tile, required this.playerIndex});

  factory LastDiscardData.fromJson(Map<String, dynamic> json) {
    return LastDiscardData(
      tile: TileInstance.fromJson(json['tile'] as Map<String, dynamic>),
      playerIndex: json['playerIndex'] as int,
    );
  }
}

/// Filtered game state from server (filterStateForPlayer). CamelCase keys.
class GameStateFiltered {
  final List<PlayerFiltered> players;
  final String phase;
  final int currentPlayer;
  final RoundState round;
  final List<TileInstance> doraIndicators;
  final LastDiscardData? lastDiscard;
  final RoundResultData? roundResult;
  final int kanCount;
  final int myIndex;
  final List<String> availableActions;
  final List<ChiOption> chiOptions;
  final List<int> kanTiles;

  const GameStateFiltered({
    required this.players,
    required this.phase,
    required this.currentPlayer,
    required this.round,
    required this.doraIndicators,
    this.lastDiscard,
    this.roundResult,
    required this.kanCount,
    required this.myIndex,
    required this.availableActions,
    required this.chiOptions,
    required this.kanTiles,
  });

  factory GameStateFiltered.fromJson(Map<String, dynamic> json) {
    final playersList = json['players'] as List<dynamic>?;
    final doraList = json['doraIndicators'] as List<dynamic>?;
    final actionsList = json['availableActions'] as List<dynamic>?;
    final chiList = json['chiOptions'] as List<dynamic>?;
    final kanList = json['kanTiles'] as List<dynamic>?;
    return GameStateFiltered(
      players: playersList != null
          ? playersList.map((e) => PlayerFiltered.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      phase: json['phase'] as String? ?? 'waiting',
      currentPlayer: json['currentPlayer'] as int? ?? 0,
      round: json['round'] != null
          ? RoundState.fromJson(json['round'] as Map<String, dynamic>)
          : const RoundState(bakaze: 0, kyoku: 0, honba: 0, riichiSticks: 0, remainingTiles: 70, turn: 0),
      doraIndicators: doraList != null
          ? doraList.map((e) => TileInstance.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      lastDiscard: json['lastDiscard'] != null
          ? LastDiscardData.fromJson(json['lastDiscard'] as Map<String, dynamic>)
          : null,
      roundResult: json['roundResult'] != null
          ? RoundResultData.fromJson(json['roundResult'] as Map<String, dynamic>)
          : null,
      kanCount: json['kanCount'] as int? ?? 0,
      myIndex: json['myIndex'] as int? ?? 0,
      availableActions:
          actionsList != null ? actionsList.map((e) => e as String).toList() : [],
      chiOptions: chiList != null
          ? chiList.map((e) => ChiOption.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      kanTiles: kanList != null ? kanList.map((e) => e as int).toList() : [],
    );
  }
}
