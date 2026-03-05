import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/room_player_info.dart';
import '../services/socket_service.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({
    super.key,
    required this.socketService,
    required this.onBack,
  });

  final SocketService socketService;
  final VoidCallback onBack;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'プレイヤー');
  final TextEditingController _joinIdController = TextEditingController();
  List<RoomListItem> _rooms = [];

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _joinIdController.dispose();
    super.dispose();
  }

  void _loadRooms() {
    if (widget.socketService.connected && widget.socketService.roomId == null) {
      widget.socketService.getRooms().then((list) {
        if (mounted) setState(() => _rooms = list);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: widget.socketService.connectedStream,
      initialData: widget.socketService.connected,
      builder: (context, snap) {
        final connected = snap.data ?? false;
        if (!connected) {
          return _buildConnecting();
        }
        return StreamBuilder<String?>(
          stream: widget.socketService.roomIdStream,
          initialData: widget.socketService.roomId,
          builder: (context, roomSnap) {
            final roomId = roomSnap.data;
            if (roomId != null && roomId.isNotEmpty) {
              return _buildInRoom(roomId);
            }
            return _buildRoomSelect();
          },
        );
      },
    );
  }

  Widget _buildConnecting() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF0f3460)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.amber),
              const SizedBox(height: 16),
              const Text(
                'サーバーに接続中...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: widget.onBack,
                child: const Text('戻る', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInRoom(String roomId) {
    return StreamBuilder<List<RoomPlayerInfo>>(
      stream: widget.socketService.playersStream,
      initialData: widget.socketService.players,
      builder: (context, snap) {
        final players = snap.data ?? [];
        final isHost = players.isNotEmpty && players.first.isHost;
        final humanCount = players.where((p) => !p.isCpu).length;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1a1a2e), Color(0xFF0f3460)],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'ルーム',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        roomId,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 18,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 24),
                      ...List.generate(4, (i) {
                        if (i < players.length) {
                          final p = players[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: p.isCpu
                                  ? Colors.grey.shade800
                                  : p.connected
                                      ? Colors.green.shade900.withValues(alpha: 0.5)
                                      : Colors.red.shade900.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    if (p.isHost)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 8),
                                        child: Text('★', style: TextStyle(color: Colors.amber)),
                                      ),
                                    Text(p.name, style: const TextStyle(color: Colors.white)),
                                  ],
                                ),
                                Text(
                                  p.isCpu ? 'CPU' : (p.connected ? '接続中' : '切断'),
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        }
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text('待機中...', style: TextStyle(color: Colors.grey)),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      const Text(
                        '2人以上でゲーム開始可能（残りはCPU補充）',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      if (isHost)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => widget.socketService.startGame(),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              'ゲーム開始（$humanCount人 + CPU ${4 - humanCount}人）',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      if (isHost) const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: widget.onBack,
                          child: const Text('戻る'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoomSelect() {
    return StreamBuilder<String?>(
      stream: widget.socketService.errorStream,
      initialData: widget.socketService.error,
      builder: (context, errSnap) {
        final error = errSnap.data;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1a1a2e), Color(0xFF0f3460)],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'オンライン対戦',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (error != null && error.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade900.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(error, style: TextStyle(color: Colors.red.shade200)),
                        ),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'プレイヤー名',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _nameController,
                        onChanged: (v) => setState(() {}),
                        maxLength: 10,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade800,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => widget.socketService.createRoom(_nameController.text),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('ルームを作成', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _joinIdController,
                              onChanged: (v) => setState(() {}),
                              maxLength: 5,
                              inputFormatters: [
                                UpperCaseTextFormatter(),
                              ],
                              style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                              decoration: InputDecoration(
                                hintText: 'ルームID',
                                filled: true,
                                fillColor: Colors.grey.shade800,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _joinIdController.text.isNotEmpty
                                ? () => widget.socketService.joinRoom(
                                    _joinIdController.text.toUpperCase(),
                                    _nameController.text)
                                : null,
                            style: FilledButton.styleFrom(backgroundColor: Colors.blue.shade700),
                            child: const Text('参加'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_rooms.isNotEmpty) ...[
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '公開ルーム',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...(_rooms.where((r) => !r.inGame).map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                widget.socketService.joinRoom(r.id, _nameController.text);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(r.id, style: const TextStyle(fontFamily: 'monospace')),
                                  Text('${r.playerCount}/4人'),
                                ],
                              ),
                            ),
                          ),
                        ))),
                        const SizedBox(height: 16),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            _loadRooms();
                          },
                          child: const Text('ルーム一覧を更新'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: widget.onBack,
                          child: const Text('戻る'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
