# SEBにおけるHTTPリクエストの構築とヘッダ付与プロセス

## 1. はじめに

本レポートは、Safe Exam Browser (SEB) がどのようにして標準のHTTPリクエストに独自の認証情報（`X-SafeExamBrowser-*` ヘッダ）とカスタム`User-Agent`を付与しているのか、その技術的な実装をソースコードレベルで解明し、考察することを目的とする。

## 2. リクエスト改変の心臓部：`-modifyRequest:`

SEBにおけるリクエスト改変のプロセスは、`SEBBrowserController.m` に実装されている `- (NSURLRequest *)modifyRequest:(NSURLRequest *)request` メソッドに集約されている。このメソッドは、WebViewで発生するすべてのリクエスト（ページの読み込み、APIコールなど）に対して呼び出される。

このメソッドの主な役割は、元のリクエストをコピーし、それにSEB独自のヘッダ情報を追加して、改変後の新しいリクエストを返すことである。

```objectivec
// Classes/BrowserComponents/SEBBrowserController.m

- (NSURLRequest *) modifyRequest:(NSURLRequest *)request
{
    NSURL *url = request.URL;

    // ... quitURLのチェックなど ...

    NSMutableURLRequest *modifiedRequest = [request mutableCopy];

    // Browser Exam Key
    [modifiedRequest setValue:[self browserExamKeyForURL:url] forHTTPHeaderField:SEBBrowserExamKeyHeaderKey];

    // Config Key
    [modifiedRequest setValue:[self configKeyForURL:url] forHTTPHeaderField:SEBConfigKeyHeaderKey];

    // User Agent
    if ([request valueForHTTPHeaderField:UserAgentHeaderKey].length >= 0) {
        [modifiedRequest setValue:[self customSEBUserAgent] forHTTPHeaderField:UserAgentHeaderKey];
    }

    return [modifiedRequest copy];
}
```

### 2.1. ヘッダ付与のトリガーと条件

コードをさらに詳しく見ると、ハッシュヘッダの付与は無条件に行われるわけではないことがわかる。`SEBBrowserController.m` の `-init` メソッド内で、`sendHashKeys` というインスタンス変数が設定されている。

```objectivec
// Classes/BrowserComponents/SEBBrowserController.m - (instancetype)init

sendHashKeys = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_sendBrowserExamKey"] || [self isUsingServerBEK];
```

この `sendHashKeys` フラグは、`.seb` 設定ファイル内の `sendBrowserExamKey` というキーが `true` に設定されている場合にのみ有効になる。そして、`-modifyRequest:` の（旧バージョンや別ブランチのコードでは）このフラグで処理が分岐する。

**重要な点:**
提供された最新のコードでは `-modifyRequest:` 内での `if (sendHashKeys)` のような明示的な分岐が削除されているように見えるが、この `sendHashKeys` フラグ自体は存在しており、設定によってヘッダ送信の有無を制御するという設計思想は明確である。**もし `sendBrowserExamKey` が `false` の場合、LMSはSEBからのアクセスを識別できなくなる**ため、これはSEBとLMSを連携させる上で極めて重要な設定項目である。

## 3. `User-Agent` の構築ロジック

カスタム `User-Agent` の生成は、`- (NSString*)customSEBUserAgent` メソッドが担当する。このメソッドのロジックは以下の通りである。

1.  **ベースとなるUser-Agentの決定:**
    *   設定キー `browserUserAgentMac` の値に応じて、ベースとなるUAが決まる。
        *   `browserUserAgentModeMacDefault`: SEBに組み込まれているWebKitのデフォルトUAが使用される。
        *   `browserUserAgentModeMacCustom`: 設定内の `browserUserAgentMacCustom` に記述されたカスタム文字列が使用される。

2.  **SEB情報の付与:**
    *   ベースとなるUA文字列の末尾に、以下の情報がスペース区切りで連結される。
        *   `SEB/[バージョン番号]` (例: `SEB/3.5`)
        *   `SEB/3.4`, `SEB/3.4.1`, `SEB/3.5` (後方互換性のための固定文字列)
        *   設定キー `browserUserAgent` で指定されたカスタムサフィックス文字列。

    ```objectivec
    // Classes/BrowserComponents/SEBBrowserController.m
    - (NSString*) customSEBUserAgent
    {
        // ... overrideUserAgent を設定値から決定 ...

        // Add "SEB <version number>" to the browser's user agent
        overrideUserAgent = [overrideUserAgent stringByAppendingString:[NSString stringWithFormat:@" %@/%@ %@/3.4 %@/3.4.1 %@/3.5 %@", SEBUserAgentDefaultSuffix, versionString, SEBUserAgentDefaultSuffix, SEBUserAgentDefaultSuffix, SEBUserAgentDefaultSuffix, browserUserAgentSuffix]];
        _customSEBUserAgent = overrideUserAgent;

        return _customSEBUserAgent;
    }
    ```

## 4. 影響の分析と考察

### 4.1. `X-SafeExamBrowser-*` ヘッダの影響

*   **アクセス制御:** これら2つのヘッダの**存在**が、LMS側で「SEBからのアクセスである」と判断するための最も基本的な条件となる。LMSのプラグインは、これらのヘッダがないリクエストをブロックすることで、通常のブラウザからの試験受験を防ぐ。
*   **セッションの正当性:** `RequestHash` はURLごとに値が変わるため、限定的なリプレイ攻撃耐性を持つ。LMS側が（たとえ検証はできなくとも）直前のリクエストと同じハッシュ値を持つリクエストを拒否する、といった実装は考えられる。

### 4.2. カスタム `User-Agent` の影響

*   **ブラウザ・バージョン判定:** LMSは `User-Agent` 内の `SEB/[バージョン番号]` を見ることで、クライアントのSEBバージョンを特定できる。これにより、「バージョン2.x以下のSEBからのアクセスを拒否する」といった制御が可能になる。
*   **機能の有効化:** LMS側で、特定の `User-Agent` サフィックスを持つSEBに対してのみ特別な機能（例: 特定のAPIの呼び出し許可）を提供することができる。例えば、大学独自のカスタマイズを施したSEBを識別するために、 `browserUserAgent` に大学名を含むサフィックス（例: `MyUniveristy-SEB-Custom`）を設定し、LMS側はそのサフィックスを持つリクエストにのみ特別な試験設定を適用する、といった高度な連携が可能になる。
*   **互換性維持:** `SEB/3.4` のような固定文字列を複数含んでいるのは、古いLMSプラグインが特定の固定バージョン文字列をハードコーディングでチェックしている場合を想定した、後方互換性のための措置と考えられる。

## 5. 結論

SEBのリクエストヘッダとUser-Agentのカスタマイズは、単なる識別情報に留まらず、LMSとの連携において柔軟かつ強力なアクセス制御と機能拡張を実現するための基盤となっている。

*   **ハッシュヘッダ**は、「正当なSEBクライアントであること」と「正しい設定で動作していること」の証明書として機能する。
*   **User-Agent**は、バージョンチェックや、特定のクライアント群にのみ特別な機能を提供するための「識別タグ」として機能する。

これらの要素が組み合わさることで、SEBはセキュアな試験環境を提供するための堅牢な通信プロトコルを構築している。
