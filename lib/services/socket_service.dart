import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/env.dart';
import '../models/game_state_filtered.dart';
import '../models/room_player_info.dart';

/// Socket.IO service matching mahjong-app useSocket.ts and server events.
class SocketService {
  io.Socket? _socket;
  bool _connected = false;
  String? _roomId;
  List<RoomPlayerInfo> _players = [];
  GameStateFiltered? _gameState;
  String? _error;

  final _connectedController = StreamController<bool>.broadcast();
  final _roomIdController = StreamController<String?>.broadcast();
  final _playersController = StreamController<List<RoomPlayerInfo>>.broadcast();
  final _gameStateController = StreamController<GameStateFiltered?>.broadcast();
  final _errorController = StreamController<String?>.broadcast();

  Stream<bool> get connectedStream => _connectedController.stream;
  Stream<String?> get roomIdStream => _roomIdController.stream;
  Stream<List<RoomPlayerInfo>> get playersStream => _playersController.stream;
  Stream<GameStateFiltered?> get gameStateStream => _gameStateController.stream;
  Stream<String?> get errorStream => _errorController.stream;

  bool get connected => _connected;
  String? get roomId => _roomId;
  List<RoomPlayerInfo> get players => List.unmodifiable(_players);
  GameStateFiltered? get gameState => _gameState;
  String? get error => _error;

  SocketService() {
    _init();
  }

  void _init() {
    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      _connected = true;
      _connectedController.add(_connected);
    });

    _socket!.onDisconnect((_) {
      _connected = false;
      _connectedController.add(_connected);
    });

    _socket!.on('room_updated', (data) {
      if (data is Map<String, dynamic>) {
        final playersList = data['players'] as List<dynamic>?;
        if (playersList != null) {
          _players = playersList
              .map((e) => RoomPlayerInfo.fromJson(e as Map<String, dynamic>))
              .toList();
          _playersController.add(_players);
        }
      }
    });

    _socket!.on('game_state', (data) {
      if (data is Map<String, dynamic>) {
        try {
          _gameState = GameStateFiltered.fromJson(data);
          _gameStateController.add(_gameState);
        } catch (_) {
          _gameState = null;
          _gameStateController.add(null);
        }
      }
    });
  }

  void createRoom(String playerName) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emitWithAck('create_room', {'playerName': playerName}, ack: (response) {
      if (response is Map<String, dynamic>) {
        if (response['error'] != null) {
          _error = response['error'] as String?;
          _errorController.add(_error);
          return;
        }
        _roomId = response['roomId'] as String?;
        _error = null;
        final playersList = response['players'] as List<dynamic>?;
        if (playersList != null) {
          _players = playersList
              .map((e) => RoomPlayerInfo.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        _roomIdController.add(_roomId);
        _playersController.add(_players);
        _errorController.add(null);
      }
    });
  }

  void joinRoom(String roomId, String playerName) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emitWithAck(
        'join_room', {'roomId': roomId, 'playerName': playerName},
        ack: (response) {
      if (response is Map<String, dynamic>) {
        if (response['error'] != null) {
          _error = response['error'] as String?;
          _errorController.add(_error);
          return;
        }
        _roomId = response['roomId'] as String?;
        _error = null;
        final playersList = response['players'] as List<dynamic>?;
        if (playersList != null) {
          _players = playersList
              .map((e) => RoomPlayerInfo.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        _roomIdController.add(_roomId);
        _playersController.add(_players);
        _errorController.add(null);
      }
    });
  }

  void startGame() {
    _socket?.emit('start_game');
  }

  void sendAction(Map<String, dynamic> action) {
    _socket?.emit('game_action', action);
  }

  Future<List<RoomListItem>> getRooms() async {
    if (_socket == null || !_socket!.connected) return [];
    final completer = Completer<List<RoomListItem>>();
    _socket!.emitWithAck('get_rooms', null, ack: (response) {
      if (response is Map<String, dynamic>) {
        final roomsList = response['rooms'] as List<dynamic>?;
        if (roomsList != null) {
          final list = roomsList.map((e) {
            final m = e as Map<String, dynamic>;
            return RoomListItem(
              id: m['id'] as String? ?? '',
              playerCount: m['playerCount'] as int? ?? 0,
              inGame: m['inGame'] as bool? ?? false,
            );
          }).toList();
          completer.complete(list);
          return;
        }
      }
      completer.complete([]);
    });
    return completer.future;
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _connectedController.close();
    _roomIdController.close();
    _playersController.close();
    _gameStateController.close();
    _errorController.close();
  }
}

class RoomListItem {
  final String id;
  final int playerCount;
  final bool inGame;

  const RoomListItem({
    required this.id,
    required this.playerCount,
    required this.inGame,
  });
}
