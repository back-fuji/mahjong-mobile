/// Matches server room-manager getPlayerList(): name, index, connected, isHost, isCpu
class RoomPlayerInfo {
  final String name;
  final int index;
  final bool connected;
  final bool isHost;
  final bool isCpu;

  const RoomPlayerInfo({
    required this.name,
    required this.index,
    required this.connected,
    required this.isHost,
    required this.isCpu,
  });

  factory RoomPlayerInfo.fromJson(Map<String, dynamic> json) {
    return RoomPlayerInfo(
      name: json['name'] as String,
      index: json['index'] as int,
      connected: json['connected'] as bool? ?? true,
      isHost: json['isHost'] as bool? ?? false,
      isCpu: json['isCpu'] as bool? ?? false,
    );
  }
}
