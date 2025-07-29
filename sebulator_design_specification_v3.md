# Chrome拡張機能「SEBulator」基本設計書 (Manifest V3対応版)

## 1. 概要

### 1.1. 目的
本拡張機能は、Google Chromeブラウザ上で動作し、Safe Exam Browser (SEB) クライアントの通信プロトコルを模倣する。Manifest V3の制約下で、SEBが必須とされるLMSのコンテンツにアクセスする技術的実現性を検証・実証することを目的とする。

### 1.2. システム構成図（Manifest V3版）
```
+--------------------------------------------------------------------------------- +
| Google Chrome                                                                    |
| +-----------------------------------------------------------------------------+  |
| | Webページ (LMS)                                                             |  |
| |                                                                             |  |
| | [Original fetch] <--+                                                       |  |
| |      ^              | 4b. 元のfetch実行                                     |  |
| |      |              |                                                       |  |
| | [Patched fetch] ----+                                                       |  |
| |      | 4a. ヘッダ追加                                                         |  |
| |      |                                                                       |  |
| | [content_script.js] <--- 3. キー返信 --- [background.js (Service Worker)]     |  |
| |      |                                        ^                              |  |
| |      +------------ 2. キー計算要求 -----------+                              |  |
| +-----------------------------------------------------------------------------+  |
|                                                                                  |
| 1. .sebファイル取得とキーの事前計算                                            |
| [background.js] がダウンロードを検知し、キーを計算して chrome.storage に保存   |
|                                                                                  |
+--------------------------------------------------------------------------------- +
```

## 2. 要件定義

(省略、以前の定義書と同様)

## 3. 機能別設計詳細 (Manifest V3版)

### 3.1. SEB設定ファイルの取得とキーの事前計算 (FR-01, FR-02, FR-03)

*   **担当コンポーネント:** `background.js` (Service Worker)
*   **トリガー:** `chrome.downloads.onCreated` および `chrome.downloads.onChanged`
*   **具体的なロジック:**
    1.  `manifest.json` の `host_permissions` でLMSのドメインを許可する。
    2.  ユーザーがLMSから `.seb` ファイルのダウンロードを開始する。（`sebs://` スキームのリダイレクトは `declarativeNetRequest` では困難なため、ユーザーに手動でダウンロードしてもらうか、LMS側のリンクが通常の `https` であることを前提とする）
    3.  `onChanged` イベントでダウンロードの完了を検知する。
    4.  `chrome.downloads.search` でファイルパスを取得し、Fetch API等で内容を読み込む。 **【重要】** ローカルファイルへのアクセスはサンドボックス化された拡張機能ページから行う必要がある。
    5.  読み込んだデータを解析（gzip伸長、プレフィックス判定、パスワード要求、plistパース）し、設定オブジェクトを生成する。
    6.  **【事前計算】** 生成した設定オブジェクトから `configKey` と `browserExamKey` を計算する。この計算ロジックはV2版設計書と同様。
    7.  計算したキーと、パースした設定内容を `chrome.storage.session` に保存する。キーはタブIDに関連付ける。

### 3.2. リクエストヘッダの動的改竄 (FR-04) - 【V3における最重要変更点】

*   **担当コンポーネント:** `content_script.js` と `background.js`
*   **アーキテクチャ:** `declarativeNetRequest` では動的なヘッダ値の付与が不可能なため、**`window.fetch` を上書き（モンキーパッチ）**する方式を採用する。
*   **具体的なロジック:**
    1.  **`fetch` の上書き:**
        *   `content_script.js` が、ページのJavaScriptが読み込まれる最初のタイミング (`"run_at": "document_start"`)で注入される。
        *   元の `window.fetch` を変数に保存しておく（例: `const originalFetch = window.fetch;`）。
        *   `window.fetch` を、我々が定義する新しい非同期関数で上書きする。
    2.  **新しい `fetch` 関数の内部処理:**
        a.  引数（URL, options）を受け取る。
        b.  `chrome.runtime.sendMessage` を使い、`background.js` に `{ type: 'GET_SEB_HEADERS', url: ... }` というメッセージを送信する。
        c.  `background.js` からヘッダ情報が返ってくるのを `await` で待つ。
        d.  `background.js` の処理（後述）:
            i.  メッセージを受け取ると、`chrome.storage.session` から現在のタブIDに対応するキー（`browserExamKey`, `configKey`）を取得する。
            ii. リクエストURLとキーを使って、`RequestHash` と `ConfigKeyHash` を動的に計算する。
            iii. 計算したヘッダとカスタム `User-Agent` をオブジェクトとして返す。
        e.  返ってきたヘッダ情報を、リクエストの `headers` オブジェクトに追加・マージする。
        f.  最後に、**元の `originalFetch`** を、ヘッダが追加された新しいリクエスト情報で呼び出し、その結果を返す。

*   **`XMLHttpRequest` への対応:** 必要に応じて `XMLHttpRequest.prototype.open` と `setRequestHeader` も同様に上書きし、`send` が呼ばれる直前にヘッダを付与するロジックを組み込む。

### 3.3. JavaScript APIの提供 (FR-05)

*   **担当コンポーネント:** `content_script.js`, `background.js`
*   **具体的なロジック:**
    1.  FR-04と同様に、`content_script.js` が `window.SafeExamBrowser` オブジェクトをページ上に定義する。
    2.  `updateKeys` 関数が呼び出されたら、`chrome.runtime.sendMessage` で `background.js` に `{ type: 'CALCULATE_KEYS_FOR_JS', url: ... }` というメッセージを送る。
    3.  `background.js` はキーを計算し、`content_script.js` に返信する。
    4.  `content_script.js` は、返ってきたキーで `window.SafeExamBrowser.security` オブジェクトの値を更新し、コールバックを実行する。このロジックは、ヘッダ改竄のためのキー計算ロジックと共有できる。

## 4. Manifest V3への対応に伴う考慮事項

*   **Service Workerのライフサイクル:** Service Workerはイベントがないと停止するため、キーなどの状態は必ず `chrome.storage` に永続化する必要がある。メモリ上のグローバル変数に依存した実装はできない。
*   **コンテンツスクリプトの注入:** `manifest.json` の `content_scripts` と、必要に応じて `chrome.scripting.executeScript` を使い、適切なタイミングでスクリプトが注入されるように設計する。
*   **権限の最小化:** `manifest.json` の `host_permissions` は、対象となるLMSのドメインに限定する。`webRequest` のような広範な権限は不要となる。必要なのは `storage`, `downloads`, `scripting` など。
*   **`fetch` 上書きの堅牢性:** 対象のWebページが `fetch` を上書きする他のライブラリを使用している場合、競合する可能性がある。`document_start` で可能な限り早く上書き処理を行う必要がある。

このV3対応設計により、`webRequest` のブロッキング機能なしに、SEBの動的なヘッダ生成プロトコルを模倣する道筋が立った。次のステップは、この設計に基づいたPoC（概念実証）の実装である。
