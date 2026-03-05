# 麻雀オンライン（Flutter モバイル）

既存の [mahjong-app](https://github.com/your-org/mahjong-app) の Express + Socket.IO サーバーに接続するスマートフォン用クライアントです。  
Web 版と同じルームでオンライン対戦できます。

## 前提

- Flutter SDK 3.x
- サーバー: mahjong-app の `server/` を起動するか、本番 URL を使用

## セットアップ

```bash
cd mahjong-mobile
flutter pub get
```

## サーバー URL の設定

- **本番**: `lib/config/env.dart` の `serverUrl` は `kReleaseMode` 時に `https://mahjong-server-1jmv.onrender.com` を使用します。
- **開発（シミュレータ）**: デバッグビルドでは `http://localhost:3001` を使用します。
- **開発（実機）**: 実機では端末の「localhost」は PC を指さないため、`--dart-define=SERVER_URL=http://<あなたのPCのIP>:3001` で接続先を指定します（下記「実機で確認する」参照）。

## 起動

```bash
flutter run
```

- iOS: `flutter run` または Xcode で開いて実行
- Android: `flutter run` または Android Studio で実行

## 実機で確認する

**可能です。** テスト目的で手元の iPhone / Android 実機にインストールして動作確認できます。

### 共通準備

1. **USB で PC と接続**し、端末で「USB デバッグを許可」「このパソコンを信頼」などを許可する。
2. **接続確認**: `flutter devices` で実機が一覧に出ることを確認する。

### iOS（iPhone）

- **前提**: Mac + Xcode。iPhone は USB 接続（または Xcode の「Wireless Debugging」で Wi‑Fi 接続も可）。
- **署名**: 初回は Xcode で「Signing & Capabilities」から自分の **Apple ID（無料）** を選ぶ。開発用証明書で実機にインストールできる（有料の Developer Program は不要でテスト可能）。
- **信頼**: 実機で「設定 → 一般 → VPNとデバイス管理」から開発者アプリを信頼。
- **実行**:
  ```bash
  flutter run -d <実機のデバイスID>
  ```
  デバイス ID は `flutter devices` で確認。

### Android

- **前提**: 端末の「開発者向けオプション」で **USB デバッグ** を有効にする。
- **実行**:
  ```bash
  flutter run -d <実機のデバイスID>
  ```

### 実機でローカルサーバー（mahjong-app）に接続する場合

1. PC で mahjong-app のサーバーを起動する: `cd mahjong-app && npm run server`（ポート 3001）。
2. PC の **ローカル IP** を確認する（例: Mac なら「システム設定 → ネットワーク」、またはターミナルで `ipconfig getifaddr en0`）。
3. 実機と PC が **同じ Wi‑Fi** に接続されていることを確認する。
4. 次のように `SERVER_URL` を指定して実行する:
   ```bash
   flutter run -d <実機のデバイスID> --dart-define=SERVER_URL=http://192.168.x.x:3001
   ```
   `192.168.x.x` をあなたの PC の IP に置き換える。

本番サーバー（Render）に接続して試すだけなら、次のどちらかで実行する:
- デバッグで試す: `flutter run -d <実機ID> --dart-define=SERVER_URL=https://mahjong-server-1jmv.onrender.com`
- リリースビルド: `flutter run -d <実機ID> --release`（この場合は `serverUrl` が本番 URL になる）

## 使い方

1. アプリ起動後、サーバーに自動接続されます。
2. プレイヤー名を入力し「ルームを作成」または「ルームID」を入力して「参加」。
3. ホストは「ゲーム開始」で開始（2人以上で開始可能、残りは CPU で補充）。
4. 対局中は手牌タップで打牌、リーチ・ポン・チー・カン・和了等は画面下部のボタンから選択。

## プロジェクト構成

- `lib/config/env.dart` - サーバー URL
- `lib/services/socket_service.dart` - Socket.IO 接続・イベント
- `lib/models/` - サーバーから受信する型
- `lib/screens/` - ロビー・対局画面
- `lib/widgets/` - 牌・手牌・アクションボタン

## 既存 PJ との関係

- このリポジトリは **mahjong-app を変更しません**。
- 同じサーバー（Socket.IO のイベント仕様）に合わせたクライアントです。
