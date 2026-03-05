import 'package:flutter/foundation.dart';

/// Server URL for Socket.IO. Same backend as mahjong-app (Express + Socket.IO).
/// In release: always uses production URL.
/// In debug: uses SERVER_URL from --dart-define if set (for real device: your Mac's IP, e.g. http://192.168.1.10:3001), else localhost for simulator.
String get serverUrl {
  if (kReleaseMode) {
    return 'https://mahjong-server-1jmv.onrender.com';
  }
  const fromDefine = String.fromEnvironment(
    'SERVER_URL',
    defaultValue: '',
  );
  if (fromDefine.isNotEmpty) return fromDefine;
  return 'http://localhost:3001';
}
