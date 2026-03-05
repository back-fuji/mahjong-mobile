import 'tile_instance.dart';

/// Meld type: chi, pon, minkan, ankan, shouminkan
class Meld {
  final String type;
  final List<TileInstance> tiles;
  final TileInstance? calledTile;
  final int? fromPlayer;

  const Meld({
    required this.type,
    required this.tiles,
    this.calledTile,
    this.fromPlayer,
  });

  factory Meld.fromJson(Map<String, dynamic> json) {
    final tilesList = json['tiles'] as List<dynamic>?;
    return Meld(
      type: json['type'] as String,
      tiles: tilesList != null
          ? tilesList.map((e) => TileInstance.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      calledTile: json['calledTile'] != null
          ? TileInstance.fromJson(json['calledTile'] as Map<String, dynamic>)
          : null,
      fromPlayer: json['fromPlayer'] as int?,
    );
  }
}

/// Chi option from server (calling phase): tiles (TileId[]), calledTile, type
class ChiOption {
  final String type;
  final List<int> tiles;
  final int calledTile;

  const ChiOption({
    required this.type,
    required this.tiles,
    required this.calledTile,
  });

  factory ChiOption.fromJson(Map<String, dynamic> json) {
    final tilesList = json['tiles'] as List<dynamic>?;
    return ChiOption(
      type: json['type'] as String,
      tiles: tilesList != null ? tilesList.map((e) => e as int).toList() : [],
      calledTile: json['calledTile'] as int,
    );
  }
}
