# SEB設定ファイルの読み込みからハッシュ生成までの完全なプロセス分析

## 1. はじめに

本レポートは、Safe Exam Browser (SEB) が `.seb` 設定ファイルをどのように読み込み、解析し、そして最終的に `X-SafeExamBrowser-RequestHash` ヘッダを生成するのか、その一連のプロセスをソースコードレベルで解明することを目的とする。

## 2. プロセスの全体像

SEBが `.seb` ファイルを扱うプロセスは、大まかに以下のステップで構成される。

1.  **ファイル受信:** ユーザー操作（ダウンロードリンクのクリック、ファイルのダブルクリックなど）により、SEBアプリケーションに `.seb` ファイルが渡される。
2.  **デコード/復号:** `.seb` ファイルは通常、**gzip圧縮**および**暗号化**されている。SEBはこれを適切な方法でデコード・復号する。
3.  **パース:** 復号されたデータは **XMLベースのplist** であり、これを `NSDictionary` オブジェクトにパースする。
4.  **設定の適用:** パースされた辞書の内容を、SEBの実行時設定（`NSUserDefaults`）に適用する。
5.  **ハッシュキーの再計算:** 新しい設定が適用されたことをトリガーとして、セキュリティの根幹である `browserExamKey` と `configKey` を再計算する。
6.  **リクエスト生成:** ブラウザがリクエストを送信する際に、再計算されたキーを用いて `X-SafeExamBrowser-RequestHash` と `X-SafeExamBrowser-ConfigKeyHash` を動的に生成する。

## 3. 詳細なロジック分析

### 3.1. ファイル処理の開始点

`.seb` ファイルの処理は、`AppDelegate` から `SEBController` を経て、最終的に `SEBConfigFileManager` クラスの `- (void)storeNewSEBSettings:...` メソッドで本格的に開始される。このメソッドが、ファイル解析の主要なエントリーポイントとなる。

```objectivec
// SEBController.m
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    // ...
    [self.configFileController storeNewSEBSettings:sebData ...];
    // ...
}
```

### 3.2. デコードと復号

`-storeNewSEBSettings:...` メソッド内では、まず受け取った `NSData` に対していくつかのデコード処理が行われる。

1.  **gzip伸長:** `.seb` ファイルはgzipで圧縮されているのが標準。まず `[sebData gzipInflate]` を試みる。
    ```objectivec
    // SEBConfigFileManager.m
    NSData *unzippedSebData = [sebData gzipInflate];
    if (unzippedSebData) {
        sebData = unzippedSebData;
    }
    ```

2.  **プレフィックスの確認と復号:**
    伸長されたデータの先頭4バイトには、暗号化の状態を示すプレフィックスが含まれている。
    *   `pswd`: パスワードで暗号化されている。ユーザーにパスワード入力を求め、`RNDecryptor` を使って復号する。
    *   `pwcc`: クライアント設定用のパスワードで暗号化されている。
    *   `pkhs`: 公開鍵で暗号化されている。
    *   `plnd` または `<?xm`: データは暗号化されていない。

    ```objectivec
    // SEBConfigFileManager.m
    prefixString = [self getPrefixStringFromData:&sebData];

    if ([prefixString isEqualToString:@"pswd"]) {
        // ... パスワード入力ダイアログを表示 ...
        sebDataDecrypted = [RNDecryptor decryptData:encryptedSEBData withPassword:password error:&error];
        // ...
    } else if (![prefixString isEqualToString:@"plnd"]) {
        // ...
    }
    ```

3.  **二重gzip伸長:** 暗号化されたペイロード自体もgzip圧縮されているため、復号後にもう一度 `gzipInflate` を実行する。
    ```objectivec
    // SEBConfigFileManager.m
    encryptedSEBData = [sebDataDecrypted gzipInflate];
    ```

### 3.3. パースと設定適用

1.  **plistのパース:** 完全にデコードされたデータはXML形式のplistなので、`NSPropertyListSerialization` を使って `NSDictionary` に変換する。
    ```objectivec
    // SEBConfigFileManager.m - getPreferencesDictionaryFromConfigData:error:
    NSDictionary *sebPreferencesDict = [NSPropertyListSerialization propertyListWithData:sebData ...];
    ```

2.  **設定の永続化:** パースされた `sebPreferencesDict` の内容を `NSUserDefaults` に書き込む。これにより、SEBアプリケーション全体で新しい設定が有効になる。
    ```objectivec
    // SEBConfigFileManager.m - storeIntoUserDefaults:
    [preferences storeSEBDictionary:sebPreferencesDict];
    ```

### 3.4. ハッシュキーの再計算

設定が `NSUserDefaults` に書き込まれた後、最も重要なプロセスであるハッシュキーの再計算がトリガーされる。

1.  **`updateEncryptedUserDefaults` の呼び出し:** `storeIntoUserDefaults:` の内部で、`SEBCryptor` の `updateConfigKeyInSettings:...` が呼び出され、これが最終的に `updateEncryptedUserDefaults` をトリガーする。

2.  **`browserExamKey` の計算:**
    *   `-updateEncryptedUserDefaults:...` は、まず現在の全設定をXML plist形式にシリアライズする。
    *   次に、設定内の `org_safeexambrowser_SEB_examKeySalt` をキーとして、シリアライズしたデータ全体に対して **HMAC-SHA256** を計算する。これが新しい `browserExamKey` となる。
    *   **ソルトがない場合:** `-updateEncryptedUserDefaults:` は `[self generateExamKeySalt]` を呼び出し、ランダムな32バイトのソルトを生成して設定に保存する。これにより、サーバーからソルトが提供されなくても、クライアント側で一意の `browserExamKey` が生成される。

3.  **`configKey` の計算:**
    *   `browserExamKey` と同様に、設定内容からキーを計算するが、こちらはHMACではなく、**設定項目をJSON形式に変換し、その文字列に対して単純なSHA-256ハッシュを計算する**という違いがある。

これらの計算結果は `NSUserDefaults` に保存され、後のリクエスト生成時に使用される。

## 4. Pythonによる再現コード

上記プロセスを再現し、`.seb` ファイルから直接 `RequestHash` を計算するPythonコードを以下に示す。

```python
import hashlib
import hmac
import plistlib
import zlib
import argparse
from typing import Dict, Any, Optional

def parse_seb_file(file_path: str, password: Optional[str] = None) -> Optional[Dict[str, Any]]:
    """
    .sebファイルを読み込み、デコードし、辞書としてパースします。
    """
    print(f"--- 1. .sebファイルの読み込み: {file_path} ---")
    with open(file_path, 'rb') as f:
        raw_data = f.read()

    # .sebファイルはgzip圧縮されている場合がある
    try:
        data = zlib.decompress(raw_data)
        print("gzip展開に成功しました。")
    except zlib.error:
        print("gzip展開に失敗しました。非圧縮データとして扱います。")
        data = raw_data

    # プレフィックスをチェックして、暗号化されているか判断
    prefix = data[:4].decode('utf-8')
    print(f"データプレフィックス: '{prefix}'")

    decrypted_data = None
    if prefix in ["pswd", "pwcc"]:
        if not password:
            print("エラー: この設定ファイルは暗号化されています。パスワードが必要です。")
            return None
        # RNCryptorの実際の復号は複雑なため、シミュレートに留めます
        print(f"'{prefix}' プレフィックスを検出。パスワード '{password}' での復号をシミュレートします。")
        decrypted_data = data[4:]
    elif prefix == "plnd":
        print("'plnd' プレフィックスを検出。データは暗号化されていません。")
        decrypted_data = data[4:]
    elif prefix.startswith("<?xm"):
        print("XML宣言を検出。データは暗号化されていないplistと判断します。")
        decrypted_data = data
    else:
        print(f"エラー: 不明なプレフィックス '{prefix}' です。")
        return None

    if not decrypted_data:
        print("エラー: データの復号/取得に失敗しました。")
        return None

    # 暗号化ペイロードもgzip圧縮されている場合がある
    try:
        final_data = zlib.decompress(decrypted_data)
        print("内部データのgzip展開に成功しました。")
    except zlib.error:
        print("内部データは非圧縮でした。")
        final_data = decrypted_data

    # plist (XML) をパースして辞書に変換
    try:
        settings_dict = plistlib.loads(final_data)
        print("plistのパースに成功しました。")
        return settings_dict
    except plistlib.InvalidFileException as e:
        print(f"エラー: plistのパースに失敗しました。 {e}")
        return None

def generate_browser_exam_key(settings_dict: Dict[str, Any]) -> Optional[bytes]:
    """
    SEBの `browserExamKey` の生成ロジックを再現します。
    """
    print("\n--- 2. browserExamKey の生成 ---")

    salt = settings_dict.get("org_safeexambrowser_SEB_examKeySalt")
    if not salt:
        print("警告: 設定内にソルトが見つかりません。クライアント側で新規生成される動作を模倣します。")
        salt = hashlib.sha256(b'random_salt_generated_by_client').digest() # ダミーのソルト生成

    print(f"使用するSalt: {salt.hex()}")

    try:
        # SEBはキーの順序を保証しないため、Pythonの辞書からそのまま変換
        plist_data = plistlib.dumps(settings_dict, fmt=plistlib.FMT_XML, sort_keys=True)
        print("設定辞書をplist(XML)データに変換しました。")
    except Exception as e:
        print(f"エラー: plistへの変換に失敗しました。 {e}")
        return None

    bek = hmac.new(salt, plist_data, hashlib.sha256).digest()
    print(f"生成された browserExamKey: {bek.hex()}")
    return bek

def generate_request_hash(url: str, browser_exam_key: bytes) -> str:
    """
    `X-SafeExamBrowser-RequestHash` ヘッダの値を計算します。
    """
    print("\n--- 3. RequestHash の生成 ---")
    print(f"対象URL: {url}")

    browser_exam_key_hex = browser_exam_key.hex()
    combined_string = url + browser_exam_key_hex

    sha256_hash = hashlib.sha256(combined_string.encode('utf-8')).hexdigest()
    return sha256_hash

def main():
    parser = argparse.ArgumentParser(description="SEB RequestHash計算ロジックの再現")
    parser.add_argument("seb_file", help=".seb設定ファイルのパス")
    parser.add_argument("--url", required=True, help="アクセス対象のURL")
    parser.add_argument("--password", help=".sebファイルが暗号化されている場合のパスワード")

    args = parser.parse_args()

    settings = parse_seb_file(args.seb_file, args.password)
    if not settings: return

    browser_exam_key = generate_browser_exam_key(settings)
    if not browser_exam_key: return

    url_without_fragment = args.url.split('#')[0]
    request_hash = generate_request_hash(url_without_fragment, browser_exam_key)

    print("\n--- 最終結果 ---")
    print(f"X-SafeExamBrowser-RequestHash: {request_hash}")

if __name__ == '__main__':
    # ... (テスト用のダミーファイル生成部分は省略) ...
    main()
```
