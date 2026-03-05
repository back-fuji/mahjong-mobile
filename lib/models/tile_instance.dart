/// Single tile instance. Matches src/core/types/tile.ts TileInstance.
/// id: 0-33 (TileId), index: unique in wall 0-135, isRed: red dora.
class TileInstance {
  final int id;
  final int index;
  final bool isRed;

  const TileInstance({
    required this.id,
    required this.index,
    this.isRed = false,
  });

  factory TileInstance.fromJson(Map<String, dynamic> json) {
    return TileInstance(
      id: json['id'] as int,
      index: json['index'] as int,
      isRed: json['isRed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'index': index, 'isRed': isRed};
}
