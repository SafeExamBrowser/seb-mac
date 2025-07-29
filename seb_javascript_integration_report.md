# SEBのJavaScript連携とセキュリティモデルに関する分析レポート

## 1. はじめに

本レポートは、Safe Exam Browser (SEB) がWebページに注入（インジェクション）するJavaScriptの役割と、ネイティブコードとの連携メカニズムを解明することを目的とする。特に、以前の議論で仮説として挙げた「JavaScriptを介したチャレンジ・レスポンス」のような高度な検証機能が存在するのかどうか、コード上の証拠に基づいて明らかにすることに主眼を置く。

## 2. JavaScript連携の全体像

SEBのJavaScript連携は、`WebKit`の`WKUserContentController`と`WKScriptMessageHandler`プロトコルを用いて実現されている。主な処理は`Classes/BrowserComponents/SEBAbstractModernWebView.swift`に集約されている。

プロセスは以下の通り。

1.  **JavaScriptコードの注入:** WebViewが初期化される際、`WKUserContentController`を使用して、SEBが用意したカスタムJavaScriptコードをすべてのWebページに注入する。
2.  **グローバルAPIの提供:** 注入されたJavaScriptは、`window.SafeExamBrowser`というグローバルオブジェクトを作成し、Webページ側から呼び出し可能なAPIを定義する。
3.  **メッセージハンドラの登録:** ネイティブ側（Swift）は、`WKScriptMessageHandler`プロトコルに準拠し、JavaScriptからのメッセージを受け取るためのハンドラを登録する。
4.  **双方向通信:**
    *   Webページは `window.SafeExamBrowser` のAPIを呼び出す。
    *   APIは `window.webkit.messageHandlers.[ハンドラ名].postMessage()` を使ってネイティブ側にメッセージを送信する。
    *   ネイティブ側は `userContentController:didReceiveScriptMessage:` メソッドでメッセージを受信し、対応する処理を実行する。
    *   ネイティブ側は `evaluateJavaScript()` を使って、結果を返すためのJavaScriptコードを実行する。

## 3. 注入されるJavaScript APIの機能

`SEBAbstractModernWebView.swift`の`wkWebViewConfiguration`プロパティ内で、注入されるJavaScriptコードが定義されている。

```swift
// Classes/BrowserComponents/SEBAbstractModernWebView.swift
let jsApiCode = """
window.SafeExamBrowser = {
  version: '\(appVersion ?? "")',
  security: {
    browserExamKey: '',
    configKey: '',
    appVersion: '\(appVersion ?? "")',
    updateKeys: function (callback) {
      if (callback) {
        window.webkit.messageHandlers.updateKeys.postMessage(callback.name);
      } else {
        window.webkit.messageHandlers.updateKeys.postMessage();
      }
    }
  }
}
"""
let jsApiUserScript = WKUserScript(source: jsApiCode, injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: false)
userContentController.addUserScript(jsApiUserScript)
```

このコードにより、Webページ上のJavaScriptは `window.SafeExamBrowser` オブジェクトにアクセスできるようになる。このオブジェクトが提供する機能は以下の通り。

*   `SafeExamBrowser.version`: SEBのバージョン文字列を返す。
*   `SafeExamBrowser.security.appVersion`: SEBのバージョン文字列を返す。（重複している）
*   `SafeExamBrowser.security.browserExamKey`: **（初期値は空文字列）**
*   `SafeExamBrowser.security.configKey`: **（初期値は空文字列）**
*   `SafeExamBrowser.security.updateKeys(callback)`: ネイティブ側に `updateKeys` というメッセージを送信する関数。ネイティブ側での処理完了後に`callback`関数を実行させることができる。

## 4. ネイティブ側ハンドラの処理

JavaScriptから `updateKeys` メッセージが送信されると、ネイティブ側の `userContentController(_:didReceive:)` メソッドが呼び出される。

```swift
// Classes/BrowserComponents/SEBAbstractModernWebView.swift
public func userContentController(_ userContentController: WKUserContentController,
                                  didReceive message: WKScriptMessage) {
    if message.name == "updateKeys" {
        let frame = message.frameInfo
        // ...
        updateKeyJSVariables(sebWebView, frame: frame) { response, error in
            // ... コールバック処理 ...
        }
    }
    // ...
}
```

`updateKeys` メッセージを受け取ると、`-updateKeyJSVariables` メソッドが実行される。このメソッドの役割が、**今回の調査の核心**である。

```swift
// Classes/BrowserComponents/SEBAbstractModernWebView.swift
private func updateKeyJSVariables(_ webView: WKWebView, frame: WKFrameInfo?, completionHandler: ((Any?, Error?) -> Void)? = nil) {
    // ... urlを取得 ...
    if url != nil {
        let browserExamKey = navigationDelegate?.browserExamKey?(for: url!)
        let configKey = navigationDelegate?.configKey?(for: url!)
        // ...
        webView.evaluateJavaScript("SafeExamBrowser.security.browserExamKey = '\(browserExamKey ?? "")';SafeExamBrowser.security.configKey = '\(configKey ?? "")';") { (response, error) in
            completionHandler?(response ?? "", error)
        }
    }
}
```

このコードが示しているのは、以下の事実である。

1.  JavaScriptから `updateKeys` が要求されると、ネイティブ側はその時点でのURLに対して**`browserExamKey` と `configKey` を計算**する。
2.  そして、計算したハッシュ値を `evaluateJavaScript` を使って、`window.SafeExamBrowser.security.browserExamKey` と `window.SafeExamBrowser.security.configKey` の**値を上書き**する。

## 5. 結論：「チャレンジ・レスポンス」仮説の検証結果

**私の仮説は、半分正しく、半分間違っていました。**

*   **正しかった点:** SEBは、Webページ上のJavaScriptと連携し、動的にハッシュキーを操作する仕組みを持っている。
*   **間違っていた点:** その仕組みは、私が想定した「サーバーからのチャレンジコードに署名する」という**チャレンジ・レスポンスモデルではなかった。**

SEBが実装しているのは、よりシンプルな**「オンデマンドでのキー計算と提供」**モデルである。

### SEBの実際のセキュリティモデル

1.  LMSのWebページは、読み込まれた時点ではハッシュ値を知らない。
2.  ページ内のJavaScriptが、任意のタイミングで `SafeExamBrowser.security.updateKeys()` を呼び出す。
3.  SEBクライアントは、そのリクエスト（のURL）に対応する正しい `browserExamKey` と `configKey` を計算し、JavaScriptのグローバル変数に設定する。
4.  その後、JavaScriptはこれらの（計算済みで信頼できる）キーの値を読み取り、例えばフォームの隠しフィールドに設定したり、Ajaxリクエストでサーバーに送信したりすることができる。

### なぜこのモデルなのか？

このモデルは、サーバー側がクライアントのソルトを知らなくても、クライアントの正当性を確認する巧妙な方法を提供している。

1.  **LMSサーバーの動作:**
    *   `.seb` 設定を配布する際、サーバーは**ソルトを含めずに**配布する。
    *   しかし、サーバーは**「この設定ファイルから計算されるべき `configKey`（ソルト不要のハッシュ）」の値は知っている。**
    *   サーバーは、この期待される `configKey` の値を、ユーザーセッションに紐付けて保存しておく。

2.  **クライアント（SEB）の動作:**
    *   SEBは `.seb` ファイルを読み込み、ランダムなソルトを生成して `browserExamKey` を計算する。同時に、ソルト不要の `configKey` も計算する。

3.  **検証プロセス:**
    *   LMSのJavaScriptが `updateKeys()` を呼び出し、`configKey` を取得する。
    *   JavaScriptが、取得した `configKey` をサーバーに送信する。
    *   サーバーは、送られてきた `configKey` と、セッションに保存しておいた期待値が一致するかどうかを比較する。

**この方法により、サーバーはクライアントが「正しい設定ファイルを使用している」ことを、ソルトを知ることなく検証できる。** `browserExamKey` は、主に `RequestHash` ヘッダの生成に使われ、直接の検証対象ではない可能性が高い。

最終的に、SEBの偽装は、`configKey` の計算ロジック（JSON化のルールなど）を完璧に再現し、かつこのJavaScript連携に応答できない限り、やはり困難であるという結論になる。
