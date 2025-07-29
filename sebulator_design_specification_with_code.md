# Chrome拡張機能「SEBulator」基本設計書 (コード参照版)

## 1. 概要

### 1.1. 目的
本拡張機能は、Google Chromeブラウザ上で動作し、Safe Exam Browser (SEB) クライアントの通信プロトコルを模倣する。これにより、SEBが必須とされるLMS（学習管理システム）のコンテンツに、SEBクライアントを使用せずにアクセスすることを技術的に検証・実証することを目的とする。

### 1.2. システム構成図（概念）
```
+---------------------------------------------------------------------- +
| Google Chrome                                                         |
| +------------------------------------------------------------------+  |
| | Webページ (LMS)                                                  |  |
| |                                                                  |  |
| | [JS] <--- 5. API提供/注入 --- [SEBulator: content_script.js]      |  |
| +------------------------------------------------------------------+  |
|        ^                                 |                            |
|        | 4. ヘッダ改竄                     | 1. URLスキーム検知         |
|        |                                 |                            |
| +------|---------------------------------|--------------------------+ |
| | [SEBulator: background.js (Service Worker)]                       | |
| |                                                                   | |
| | ・URL書き換え (.seb取得)                                          | |
| | ・設定解析、キー生成 (configKey, browserExamKey)                  | |
| | ・リクエスト傍受・ヘッダ書き換え                                    | |
| | ・状態管理                                                        | |
| +------------------------------------------------------------------+  |
+---------------------------------------------------------------------- +
```

## 2. 要件定義

(省略、前バージョンと同様)

## 3. 機能別設計詳細

### 3.1. SEB設定ファイルの取得と解析 (FR-01, FR-02)

*   **担当コンポーネント:** `background.js`
*   **具体的なロジック:**
    1.  `chrome.webRequest` APIで `sebs://` 等のURLを捕捉し、`https://` にリダイレクトして `.seb` ファイルをダウンロードさせる。
    2.  ダウンロードしたファイル内容を読み込み、zlib.js等でgzip伸長する。
    3.  データの先頭4バイトからプレフィックス (`plnd`, `pswd` 等)を判定し、必要ならパスワードを要求して復号処理（シミュレーション）を行う。
    4.  最終的に得られたplist(XML)データをJavaScriptオブジェクトに変換し、`chrome.storage.session` に保存する。
*   **参照コード（SEB側）:**
    <details>
    <summary><code>Classes/ConfigFiles/SEBConfigFileManager.m</code> -> <code>storeNewSEBSettings:</code> (クリックで展開)</summary>

    ```objectivec
    -(void) storeNewSEBSettings:(NSData *)sebData
                 forEditing:(BOOL)forEditing
     forceConfiguringClient:(BOOL)forceConfiguringClient
       showReconfiguredAlert:(BOOL)showReconfiguredAlert
                   callback:(id)callback
                   selector:(SEL)selector
    {
        storeSettingsForEditing = forEditing;
        storeSettingsForceConfiguringClient = forceConfiguringClient;
        storeShowReconfiguredAlert = showReconfiguredAlert;
        storeSettingsCallback = callback;
        storeSettingsSelector = selector;
        sebFileCredentials = [SEBConfigFileCredentials new];

        // ...

        // Ungzip the .seb (according to specification >= v14) source data
        NSData *unzippedSebData = [sebData gzipInflate];
        // if unzipped data is not nil, then unzipping worked, we use unzipped data
        // if unzipped data is nil, then the source data may be an uncompressed .seb file, we proceed with it
        BOOL uncompressed = NO;
        if (unzippedSebData) {
            sebData = unzippedSebData;
        } else {
            uncompressed = YES;
        }
        // ...

        // Get 4-char prefix
        prefixString = [self getPrefixStringFromData:&sebData];

        // ...

        // Prefix = pswd ("Password") ?
        if ([prefixString isEqualToString:@"pswd"]) {

            // ...
            // Ask the user to enter the settings password and proceed to the callback method after this happend
            [self.delegate promptPasswordWithMessageText:enterPasswordString
                                                       title:[NSString stringWithFormat:@"%@ (%@ %@)", NSLocalizedString(@"Starting Exam",nil), SEBShortAppName, MyGlobals.versionString]
                                                    callback:self
                                                    selector:@selector(passwordSettingsStartingExam:)];
            return;

        } else {

            // Prefix = pwcc ("Password Configuring Client") ?
            if ([prefixString isEqualToString:@"pwcc"]) {
                // ...
            } else {
                // Prefix = plnd ("Plain Data") ?
                if (![prefixString isEqualToString:@"plnd"]) {
                    // ...
                }
            }
        }

        // If we don't deal with an unencrypted seb file
        // ungzip the .seb (according to specification >= v14) decrypted serialized XML plist data
        if (![prefixString isEqualToString:@"<?xm"]) {
            encryptedSEBData = [encryptedSEBData gzipInflate];
        }
        [self parseSettingsStartingExamForEditing:forEditing];
    }
    ```
    </details>

### 3.2. SEBキーの生成と管理 (FR-03)

*   **担当コンポーネント:** `background.js` (例: `keyGenerator.js` モジュール)
*   **具体的なロジック:**
    1.  **`configKey` の生成:** **【最重要課題】** Objective-Cの `NSPropertyListSerialization` の挙動をJavaScriptで完全に再現し、設定オブジェクトからJSON文字列を生成。その後、SHA-256ハッシュを計算する。
    2.  **`browserExamKey` の生成:** 設定から `examKeySalt` を取得。なければランダム生成。設定全体をplist(XML)に変換し、ソルトをキーとしてHMAC-SHA256ハッシュを計算する。
    3.  計算したキーを `chrome.storage.session` に保存する。
*   **参照コード（SEB側）:**
    <details>
    <summary><code>Classes/Cryptography/SEBCryptor.m</code> (クリックで展開)</summary>

    ```objectivec
    // browserExamKey の計算
    - (NSData *)checksumForPrefDictionary:(NSDictionary *)prefsDict
    {
        NSError *error = nil;

        NSData *archivedPrefs = [NSPropertyListSerialization dataWithPropertyList:prefsDict
                                                                           format:NSPropertyListXMLFormat_v1_0
                                                                          options:0
                                                                            error:&error];
        NSData *HMACData;
        if (error || !archivedPrefs) {
            // ...
            HMACData = [NSData data];
        } else {
            // Generate new pref key
            HMACData = [self generateChecksumForBEK:archivedPrefs];
        }
        return HMACData;
    }

    - (NSData *)generateChecksumForBEK:(NSData *)currentData
    {
        // Get current salt for exam key
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        NSData *HMACKey = [preferences secureDataForKey:@"org_safeexambrowser_SEB_examKeySalt"];

        return [self generateChecksumForData:currentData withSalt:HMACKey];
    }

    - (NSData *)generateChecksumForData:(NSData *)currentData withSalt:(NSData *)HMACKey {
        NSMutableData *HMACData = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
        CCHmac(kCCHmacAlgSHA256, HMACKey.bytes, HMACKey.length, currentData.bytes, currentData.length, HMACData.mutableBytes);
        return HMACData;
    }

    // ソルトの生成
    - (NSData *)generateExamKeySalt
    {
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        NSData *HMACKey = [RNCryptor randomDataOfLength:kCCKeySizeAES256];
        [preferences setSecureObject:HMACKey forKey:@"org_safeexambrowser_SEB_examKeySalt"];
        return HMACKey;
    }

    // configKey の計算
    - (void) updateConfigKey
    {
        // ...
        // Filter dictionary so only org_safeexambrowser_SEB_ keys are included
        NSDictionary *filteredPrefsDict = [preferences dictionaryRepresentationSEB];
        // ...
        [self updateConfigKeyInSettings:filteredPrefsDict
              configKeyContainedKeysRef:&configKeyContainedKeys
                           configKeyRef:&configKey
                initializeContainedKeys:initializeContainedKeys];
        // ...
    }

    - (NSDictionary *) updateConfigKeyInSettings:(NSDictionary *) sourceDictionary ...
    {
        // ...
        // Convert preferences dictionary to JSON and generate the Config Key hash
        *configKeyRef = [self checksumForJSONString:[jsonString copy]];
        // ...
    }

    - (NSData *)checksumForJSONString:(NSString *)jsonString
    {
        unsigned char hashedChars[CC_SHA256_DIGEST_LENGTH];
        CC_SHA256([jsonString UTF8String],
                  (uint)[jsonString lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
                  hashedChars);
        NSData *hashData = [NSData dataWithBytes:(const void *)hashedChars length:CC_SHA256_DIGEST_LENGTH];
        return hashData;
    }
    ```
    </details>

### 3.3. HTTPリクエストヘッダの改竄 (FR-04)

*   **担当コンポーネント:** `background.js`
*   **具体的なロジック:**
    1.  `onBeforeSendHeaders` リスナーで、SEBモード中であることを確認。
    2.  ストレージから `browserExamKey` と `configKey` を取得。
    3.  `URL + key.hex()` の文字列をSHA-256でハッシュ化し、`X-SafeExamBrowser-*` ヘッダを生成。
    4.  `User-Agent` ヘッダをSEBのフォーマットに書き換える。
*   **参照コード（SEB側）:**
    <details>
    <summary><code>Classes/BrowserComponents/SEBBrowserController.m</code> (クリックで展開)</summary>

    ```objectivec
    - (NSURLRequest *) modifyRequest:(NSURLRequest *)request
    {
        NSURL *url = request.URL;

        // ...

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

    - (NSString *) browserExamKeyForURL:(NSURL *)url
    {
        // ...
        NSData *browserExamKey = self.browserExamKey;
        [browserExamKey getBytes:hashedChars length:32];

        NSMutableString* browserExamKeyString = [[NSMutableString alloc] initWithString:urlStrippedFragment(url)];
        for (NSUInteger i = 0 ; i < 32 ; ++i) {
            [browserExamKeyString appendFormat: @"%02x", hashedChars[i]];
        }
        const char *urlString = [browserExamKeyString UTF8String];
        CC_SHA256(urlString,
                  (uint)strlen(urlString),
                  hashedChars);

        // ... (16進数文字列に変換) ...
    }

    - (NSString*) customSEBUserAgent
    {
        // ...
        // Add "SEB <version number>" to the browser's user agent, so the LMS SEB plugins recognize us
        overrideUserAgent = [overrideUserAgent stringByAppendingString:[NSString stringWithFormat:@" %@/%@ %@/3.4 %@/3.4.1 %@/3.5 %@", SEBUserAgentDefaultSuffix, versionString, SEBUserAgentDefaultSuffix, SEBUserAgentDefaultSuffix, SEBUserAgentDefaultSuffix, browserUserAgentSuffix]];
        _customSEBUserAgent = overrideUserAgent;
        return _customSEBUserAgent;
    }
    ```
    </details>

### 3.4. JavaScript APIの提供 (FR-05)

*   **担当コンポーネント:** `content_script.js`, `background.js`
*   **具体的なロジック:**
    1.  `content_script.js` が `window.SafeExamBrowser` オブジェクトをページ上に定義する。
    2.  `updateKeys` が呼び出されたら、`chrome.runtime.sendMessage` で `background.js` に通知。
    3.  `background.js` はキーを再計算し、`chrome.tabs.sendMessage` で `content_script.js` に返信。
    4.  `content_script.js` は受け取ったキーで `window.SafeExamBrowser.security` オブジェクトの値を更新し、コールバックを実行する。
*   **参照コード（SEB側）:**
    <details>
    <summary><code>Classes/BrowserComponents/SEBAbstractModernWebView.swift</code> (クリックで展開)</summary>

    ```swift
    // JavaScript APIの定義と注入
    public var wkWebViewConfiguration: WKWebViewConfiguration {
        // ...
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
        // ...
        userContentController.add(self, name: "updateKeys")
        // ...
    }

    // ネイティブ側ハンドラ
    public func userContentController(_ userContentController: WKUserContentController,
                                      didReceive message: WKScriptMessage) {
        if message.name == "updateKeys" {
            // ...
            updateKeyJSVariables(sebWebView, frame: frame) { response, error in
                // ...
            }
        }
    }

    // JavaScript変数を更新する処理
    private func updateKeyJSVariables(_ webView: WKWebView, frame: WKFrameInfo?, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        // ...
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
    </details>

## 4. 実装上の考慮事項と推奨事項

(省略、前バージョンと同様)
