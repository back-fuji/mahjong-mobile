import 'tile_instance.dart';
import 'meld.dart';

/// Player data as sent by filterStateForPlayer (own hand visible only for myIndex).
class PlayerFiltered {
  final String id;
  final String name;
  final int score;
  final int seatWind;
  final bool isRiichi;
  final int riichiDiscardIndex;
  final List<TileInstance> discards;
  final List<Meld> melds;
  final int? closedCount;
  final List<TileInstance>? closed;
  final TileInstance? tsumo;
  final bool isMenzen;
  final bool isHuman;
  final bool connected;
  final List<int>? kuikaeDisallowedTiles;

  const PlayerFiltered({
    required this.id,
    required this.name,
    required this.score,
    required this.seatWind,
    required this.isRiichi,
    required this.riichiDiscardIndex,
    required this.discards,
    required this.melds,
    this.closedCount,
    this.closed,
    this.tsumo,
    required this.isMenzen,
    required this.isHuman,
    required this.connected,
    this.kuikaeDisallowedTiles,
  });

  factory PlayerFiltered.fromJson(Map<String, dynamic> json) {
    final discardsList = json['discards'] as List<dynamic>?;
    final meldsList = json['melds'] as List<dynamic>?;
    final closedList = json['closed'] as List<dynamic>?;
    final kuikaeList = json['kuikaeDisallowedTiles'] as List<dynamic>?;
    return PlayerFiltered(
      id: json['id'] as String,
      name: json['name'] as String,
      score: json['score'] as int,
      seatWind: json['seatWind'] as int,
      isRiichi: json['isRiichi'] as bool? ?? false,
      riichiDiscardIndex: json['riichiDiscardIndex'] as int? ?? -1,
      discards: discardsList != null
          ? discardsList.map((e) => TileInstance.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      melds: meldsList != null
          ? meldsList.map((e) => Meld.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      closedCount: json['closedCount'] as int?,
      closed: closedList
          ?.map((e) => TileInstance.fromJson(e as Map<String, dynamic>)).toList(),
      tsumo: json['tsumo'] != null
          ? TileInstance.fromJson(json['tsumo'] as Map<String, dynamic>)
          : null,
      isMenzen: json['isMenzen'] as bool? ?? true,
      isHuman: json['isHuman'] as bool? ?? true,
      connected: json['connected'] as bool? ?? true,
      kuikaeDisallowedTiles: kuikaeList?.map((e) => e as int).toList(),
    );
  }
}
