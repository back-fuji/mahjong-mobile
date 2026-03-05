# Xcode で実機（GOTO's iPhone）を表示する方法

## 方法1: メニューから開く（Xcode 15 / 16 系）

1. **Xcode** を起動する（プロジェクトを開かなくてよい）
2. 画面上部メニューで **Window（ウィンドウ）** をクリック
3. **Devices and Simulators** を選択

   - 英語メニュー: **Window** → **Devices and Simulators**
   - 日本語メニューの場合: **ウィンドウ** → **デバイスとシミュレータ**

4. 開いたウィンドウの上部で **Devices（デバイス）** タブを選択
5. 左の一覧に **GOTO's iPhone** が出ていれば、選択してペアリング・信頼の指示に従う

---

## 方法2: メニューに「Devices and Simulators」がない場合

- **Xcode** → **Settings…**（または **Preferences…**）を開く
- 左側の **Platforms** や **Accounts** を確認し、デバイス関連の項目がないか見る
- または **Product** → **Destination** → **Show All Run Destinations** を開くと、接続中の実機が一覧に出ることがある

---

## 方法3: Finder から iPhone を信頼する

1. iPhone を USB で Mac に接続
2. **Finder** を開く
3. 左サイドバーで **「GOTO's iPhone」**（または自分の iPhone 名）をクリック
4. iPhone に「このコンピュータを信頼しますか？」と出たら **信頼** をタップ
5. 必要なら Mac 側でパスコード入力

これで「信頼」は完了。その後、Xcode の **Window → Devices and Simulators** で再度確認する。

---

## 方法4: ショートカットでウィンドウを開く

- **Shift + Command + 2** で Organizer が開くことがある（Xcode のバージョンによる）
- Organizer 内に **Devices** の一覧がある場合がある

---

## Xcode のバージョン確認

メニュー **Xcode** → **About Xcode** でバージョンが分かります。

- **26.0.1** と表示される場合、ベータ版や将来バージョンの可能性があります。メニュー名が変わっている場合は、**Window** や **Xcode → Settings** の下を順に確認してください。

---

## それでも実機が出ない場合

1. **USB ケーブル**を抜き差しする（データ転送対応のケーブルか確認）
2. iPhone で **設定 → 一般 → 転送またはiPhoneをリセット → リセット → 位置情報とプライバシーをリセット** は行わず、**「このコンピュータを信頼」** だけ再度試す
3. Mac を再起動してから、再度 iPhone を接続して Finder / Xcode で確認

信頼まで完了していれば、ターミナルで次のコマンドで実機が表示されるはずです。

```bash
flutter devices
```

「GOTO's iPhone」が **available** と出ていれば、実機でアプリを実行できます。
