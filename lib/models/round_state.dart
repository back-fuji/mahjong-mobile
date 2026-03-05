/// Round state from server. Matches RoundState in game-state.ts
class RoundState {
  final int bakaze;
  final int kyoku;
  final int honba;
  final int riichiSticks;
  final int remainingTiles;
  final int turn;
  final bool? isFirstTurn;

  const RoundState({
    required this.bakaze,
    required this.kyoku,
    required this.honba,
    required this.riichiSticks,
    required this.remainingTiles,
    required this.turn,
    this.isFirstTurn,
  });

  factory RoundState.fromJson(Map<String, dynamic> json) {
    return RoundState(
      bakaze: json['bakaze'] as int,
      kyoku: json['kyoku'] as int,
      honba: json['honba'] as int,
      riichiSticks: json['riichiSticks'] as int,
      remainingTiles: json['remainingTiles'] as int,
      turn: json['turn'] as int,
      isFirstTurn: json['isFirstTurn'] as bool?,
    );
  }
}
