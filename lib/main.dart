import 'package:flutter/material.dart';

import 'models/game_state_filtered.dart';
import 'screens/game_screen.dart';
import 'screens/lobby_screen.dart';
import 'services/socket_service.dart';

void main() {
  runApp(const MahjongApp());
}

class MahjongApp extends StatelessWidget {
  const MahjongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '麻雀オンライン',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const _RootPage(),
    );
  }
}

class _RootPage extends StatefulWidget {
  const _RootPage();

  @override
  State<_RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<_RootPage> {
  final SocketService _socketService = SocketService();
  GameStateFiltered? _gameState;
  bool _showLobby = true;

  @override
  void initState() {
    super.initState();
    _socketService.gameStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _gameState = state;
          if (state != null) _showLobby = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gameState != null && !_showLobby) {
      return GameScreen(
        socketService: _socketService,
        gameState: _gameState!,
        onBack: () => setState(() => _showLobby = true),
      );
    }
    return LobbyScreen(
      socketService: _socketService,
      onBack: () {}, // Root: no navigation back
    );
  }
}
