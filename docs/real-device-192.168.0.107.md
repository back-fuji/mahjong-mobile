# 実機確認手順（PC IP: 192.168.0.107）

## 前提

- PC の IP: **192.168.0.107**
- 実機と PC は **同じ Wi‑Fi** に接続すること

---

## 手順 1: PC でサーバーを起動

```bash
cd /Users/goto/WorkCase/mahjong-app
npm run server
```

「Mahjong server running on port 3001」と表示されれば OK。

---

## 手順 2: 実機を USB で接続

- **iPhone**: ケーブルで接続し、「このコンピュータを信頼」で信頼する
- **Android**: USB デバッグを有効にし、接続して「許可」する

---

## 手順 3: 接続されているデバイスを確認

```bash
cd /Users/goto/WorkCase/mahjong-mobile
flutter devices
```

一覧に実機（例: "iPhone" や "samsung SM-xxx"）が出ていることを確認する。  
**実機のデバイス ID または名前**をメモする（次の手順で使う）。

---

## 手順 4: 実機でアプリを起動（ローカルサーバーに接続）

**iPhone 実機の場合:**

```bash
cd /Users/goto/WorkCase/mahjong-mobile
flutter run -d <実機のデバイスID> --dart-define=SERVER_URL=http://192.168.0.107:3001
```

例（実機が "Goto's iPhone" の場合）:

```bash
flutter run -d "Goto's iPhone" --dart-define=SERVER_URL=http://192.168.0.107:3001
```

**Android 実機の場合:**

```bash
flutter run -d <実機のデバイスID> --dart-define=SERVER_URL=http://192.168.0.107:3001
```

デバイス ID は `flutter devices` の一覧の左端（例: `00008103-001234567890001E` や `emulator-5554`）でも指定できる。

---

## 手順 5: アプリでルーム作成・参加

1. アプリ起動後、「サーバーに接続中」から「接続済み」になるのを確認
2. プレイヤー名を入力し「ルームを作成」または ルーム ID を入力して「参加」
3. ホストは「ゲーム開始」で開始

---

## まとめ（コピペ用）

```bash
# ターミナル1: サーバー起動
cd /Users/goto/WorkCase/mahjong-app && npm run server

# ターミナル2: 実機でアプリ起動（デバイスIDは flutter devices で確認）
cd /Users/goto/WorkCase/mahjong-mobile
flutter run -d <実機のデバイスID> --dart-define=SERVER_URL=http://192.168.0.107:3001
```
