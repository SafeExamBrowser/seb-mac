# Safe Exam Browser (SEB) 通信プロトコル分析レポート（コード検証版）

## 1. はじめに

本レポートは、提供されたHTTP通信ログおよびSafe Exam Browserのソースコードに基づき、その通信仕様、特に認証に使われる2つのカスタムヘッダ `X-SafeExamBrowser-RequestHash` と `X-SafeExamBrowser-ConfigKeyHash` の具体的な計算ロジックを解明し、文書化することを目的とする。

## 2. プロセスの概要

ログ分析から、SEBの起動プロセスは以下の3段階で構成されることが判明している。

1.  **標準ブラウザによる設定取得:** ユーザーがLMS上のリンクをクリックし、`.seb` 設定ファイルをダウンロードする。
2.  **SEBクライアントの起動と設定再取得:** OSが `.seb` ファイルをSEBで開く。SEBは自身の`User-Agent`で設定ファイルを再取得する。
3.  **セキュアブラウザによる試験ページへのアクセス:** SEB内のブラウザが、設定内の `startURL` へ2つの認証用カスタムヘッダを付与してアクセスする。

この過程で `User-Agent` が変化することから、「標準ブラウザ → SEBネイティブクライアント → SEB内セキュアブラウザ」というコンテキストの移行が確認できる。

## 3. 2つのハッシュ値の役割

`X-SafeExamBrowser-ConfigKeyHash` と `X-SafeExamBrowser-RequestHash` は、それぞれ異なる目的を持ち、通信の正当性を多層的に検証するために存在する。

*   **`X-SafeExamBrowser-ConfigKeyHash` (Config Key):**
    *   **役割:** クライアントが **「正しい設定ファイル」** を使用していることを証明する。
    *   **目的:** 設定ファイルの改ざんを防ぎ、サーバーが意図した通りの制約（URLフィルタリングなど）の下でクライアントが動作していることを保証する。これはセッションを通じて比較的不変な「設定の完全性」を示す。

*   **`X-SafeExamBrowser-RequestHash` (Browser Exam Key):**
    *   **役割:** 現在の **「リクエスト（URL）」** が、その正しい設定の下で許可されていることを証明する。
    *   **目的:** 個々のリクエストの正当性を検証する。たとえ正しい設定ファイルを使用していても、許可されていないURLへのアクセスを防ぐ。これはリクエストごとに変動する「リクエストの正当性」を示す。

## 4. ハッシュ値の計算方法の特定

ソースコード `Classes/BrowserComponents/SEBBrowserController.m` の解析により、2つのハッシュ値の具体的な計算ロジックが判明した。これは当初の推測をおおむね裏付けるものであったが、より詳細な実装が明らかになった。

キーとなるメソッドは `- (NSString *)browserExamKeyForURL:(NSURL *)url` と `- (NSString *)configKeyForURL:(NSURL *)url` である。両者とも、最終的に **SHA-256** を用いてハッシュ値を生成している。

### 4.1. `X-SafeExamBrowser-ConfigKeyHash` の計算ロジック

この値は、実際には **2段階のハッシュ計算** を経て生成される。

**第1段階：`configKey` の生成（設定ファイル全体のハッシュ）**

*   このキーは、SEBが設定ファイル（`.seb`）を読み込む際に一度だけ計算され、`NSUserDefaults` に保存される。
*   **入力データ:** 設定ファイル（`.seb`ファイル）の **内容全体**。
*   **計算:** `SHA256(設定ファイルデータ)`
*   この結果（32バイトのバイナリ）が、以降の計算で `self.configKey` として参照される。当初のレポートで「設定ファイル内容全体から計算される」と推定した部分に相当するが、これが中間キーとして利用される点が重要である。

**第2段階：リクエストごとの `ConfigKeyHash` の生成**

*   **入力データ:**
    1.  アクセス先URL（フラグメント `#` 以降を除いたもの）。
    2.  第1段階で生成された `configKey`（32バイトのバイナリを16進数文字列化したもの）。
*   **計算プロセス:**
    1.  URL文字列の末尾に、`configKey` の16進数文字列を連結する。
    2.  連結してできた新しい文字列をUTF-8エンコードし、そのデータに対して **SHA-256** ハッシュを計算する。
    3.  結果の32バイトを16進数文字列に変換したものが、最終的なヘッダ値となる。

*   **該当コード (`- (NSString *)configKeyForURL:(NSURL *)url`):**
    ```objectivec
    - (NSString *) configKeyForURL:(NSURL *)url
    {
        unsigned char hashedChars[32];

        [self.configKey getBytes:hashedChars length:32]; // 第1段階で計算済みのconfigKeyを取得

        NSMutableString* configKeyString = [[NSMutableString alloc] initWithString:urlStrippedFragment(url)];
        for (NSUInteger i = 0 ; i < 32 ; ++i) {
            [configKeyString appendFormat: @"%02x", hashedChars[i]]; // URLとconfigKeyを連結
        }

        const char *urlString = [configKeyString UTF8String];
        CC_SHA256(urlString, // SHA-256でハッシュ化
                  (uint)strlen(urlString),
                  hashedChars);

        NSMutableString* hashedConfigKeyString = [[NSMutableString alloc] initWithCapacity:32];
        for (NSUInteger i = 0 ; i < 32 ; ++i) {
            [hashedConfigKeyString appendFormat: @"%02x", hashedChars[i]]; // 16進数文字列に変換
        }
        return hashedConfigKeyString;
    }
    ```

### 4.2. `X-SafeExamBrowser-RequestHash` の計算ロジック

こちらも `ConfigKeyHash` と同様の構造を持つ。

*   **ベースとなるキー:** `browserExamKey`。これは設定ファイル内の `examKeySalt` と呼ばれる値などから生成され、`NSUserDefaults` に保存されている。
*   **入力データ:**
    1.  アクセス先URL（フラグメント `#` 以降を除いたもの）。
    2.  `browserExamKey`（32バイトのバイナリを16進数文字列化したもの）。
*   **計算プロセス:**
    1.  URL文字列の末尾に、`browserExamKey` の16進数文字列を連結する。
    2.  連結してできた文字列に対して **SHA-256** ハッシュを計算する。
    3.  結果を16進数文字列に変換する。

*   **該当コード (`- (NSString *)browserExamKeyForURL:(NSURL *)url`):**
    ```objectivec
    - (NSString *) browserExamKeyForURL:(NSURL *)url
    {
        unsigned char hashedChars[32];
        // ...
        NSData *browserExamKey = self.browserExamKey; // browserExamKeyを取得
        [browserExamKey getBytes:hashedChars length:32];

        NSMutableString* browserExamKeyString = [[NSMutableString alloc] initWithString:urlStrippedFragment(url)];
        for (NSUInteger i = 0 ; i < 32 ; ++i) {
            [browserExamKeyString appendFormat: @"%02x", hashedChars[i]]; // URLとbrowserExamKeyを連結
        }
        const char *urlString = [browserExamKeyString UTF8String];
        CC_SHA256(urlString, // SHA-256でハッシュ化
                  (uint)strlen(urlString),
                  hashedChars);

        NSMutableString* hashedString = [[NSMutableString alloc] initWithCapacity:32];
        for (NSUInteger i = 0 ; i < 32 ; ++i) {
            [hashedString appendFormat: @"%02x", hashedChars[i]]; // 16進数文字列に変換
        }
        return hashedString;
    }
    ```

### 4.3. なぜ2つのハッシュ値が異なるのか（コードからの結論）

2つのハッシュ値は、**連結される元の中間キーが異なるため**、最終的な値が異なる。

*   `ConfigKeyHash` は、**URL + SHA256(設定ファイル全体)** から計算される。
*   `RequestHash` は、**URL + browserExamKey** から計算される。

`SHA256(設定ファイル全体)` と `browserExamKey` は異なる値であるため、たとえ同じURLに対して計算しても、入力データが異なり、結果として2つのハッシュ値は全く異なるものとなる。

## 5. 結論

ソースコードの解析により、SEBの認証プロトコルは、当初の推測よりもさらに洗練された、2段階のハッシュ計算に基づいていることが確認された。

*   まず、設定ファイル全体から **`configKey`** という不変のハッシュ値を生成し、設定の完全性を保証するベースとする。
*   次に、リクエストごとに、アクセス先URLとこの `configKey` を連結して再度ハッシュ化することで **`X-SafeExamBrowser-ConfigKeyHash`** を生成し、リクエストのコンテキストにおける設定の正当性を検証する。
*   並行して、別のキー `browserExamKey` を用いて同様の計算を行い **`X-SafeExamBrowser-RequestHash`** を生成し、リクエストそのものの正当性を検証する。

この二重の検証メカニズムにより、設定の改ざん防止と、個々のリクエストの正当性確認を両立させ、堅牢なセキュリティを実現している。
