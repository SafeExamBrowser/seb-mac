import hashlib
import hmac
import plistlib
import zlib
import argparse
from typing import Dict, Any, Optional

# SEBの暗号化設定（RNCryptorの定数に対応）
# 実際の復号にはRNCryptorライブラリが必要だが、ここでは構造を模倣する
RNCryptorSettings = {
    "algorithm": "AES",
    "options": "PKCS7Padding",
    "salt_size": 8,
    "iv_size": 16,
    "key_size": 32,
    "hmac_algorithm": "SHA256",
    "hmac_length": 32,
}

def decrypt_seb_data_with_password(data: bytes, password: str) -> Optional[bytes]:
    """
    パスワードで暗号化された.sebデータ（のシミュレーション）を復号します。
    注意: この関数は実際のRNCryptorの複雑な復号ロジックを実装していません。
          正しいプレフィックスとパスワードが与えられた場合に、
          ダミーの復号処理（何もしない）を行うシミュレーターです。
    """
    prefix = data[:4].decode('utf-8')
    if prefix not in ["pswd", "pwcc"]:
        print(f"エラー: 無効なプレフィックス '{prefix}' です。")
        return None

    # RNCryptorの実際の復号は非常に複雑なため、ここでは省略します。
    # 実際のライブラリ: https://github.com/RNCryptor/RNCryptor
    # ここでは、プレフィックスを除いたデータをそのまま返します。
    # 本来はこのペイロードに対してパスワードを使った復号が行われます。
    print(f"'{prefix}' プレフィックスを検出。パスワード '{password}' での復号をシミュレートします。")
    return data[4:]

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
        decrypted_data = decrypt_seb_data_with_password(data, password)
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

    # .sebファイルの中身はさらにgzip圧縮されている場合がある (二重圧縮)
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

    # SEBCryptor.m -> updateEncryptedUserDefaults
    # ソルトは設定辞書から取得する。なければエラーとする（本来は生成される）
    salt = settings_dict.get("org_safeexambrowser_SEB_examKeySalt")
    if not salt:
        print("エラー: 設定内に 'org_safeexambrowser_SEB_examKeySalt' が見つかりません。")
        return None

    print(f"使用するSalt: {salt.hex()}")

    # SEBCryptor.m -> checksumForPrefDictionary
    # `NSPropertyListXMLFormat_v1_0` を使用してシリアライズする
    try:
        # Pythonのplistlib.dumpsはキーをソートしないため、手動でソートする
        # SEBはキーの順序を保証していないように見えるが、念のためソートする
        sorted_dict = dict(sorted(settings_dict.items()))
        plist_data = plistlib.dumps(sorted_dict, fmt=plistlib.FMT_XML, sort_keys=True)
        print("設定辞書をplist(XML)データに変換しました。")
    except Exception as e:
        print(f"エラー: plistへの変換に失敗しました。 {e}")
        return None

    # SEBCryptor.m -> generateChecksumForBEK
    # HMAC-SHA256でハッシュを計算
    bek = hmac.new(salt, plist_data, hashlib.sha256).digest()
    print(f"生成された browserExamKey: {bek.hex()}")
    return bek

def generate_request_hash(url: str, browser_exam_key: bytes) -> str:
    """
    `X-SafeExamBrowser-RequestHash` ヘッダの値を計算します。
    """
    print("\n--- 3. RequestHash の生成 ---")
    print(f"対象URL: {url}")
    print(f"連結する browserExamKey: {browser_exam_key.hex()}")

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

    # 1. .seb ファイルを読み込み、パースする
    settings = parse_seb_file(args.seb_file, args.password)
    if not settings:
        return

    # 2. パースした設定から browserExamKey を生成する
    browser_exam_key = generate_browser_exam_key(settings)
    if not browser_exam_key:
        return

    # 3. RequestHash を生成する
    # URLのフラグメントは除去する
    url_without_fragment = args.url.split('#')[0]
    request_hash = generate_request_hash(url_without_fragment, browser_exam_key)

    print("\n--- 最終結果 ---")
    print(f"X-SafeExamBrowser-RequestHash: {request_hash}")

if __name__ == '__main__':
    # このスクリプトを実行するには、まずテスト用の .seb ファイルを作成する必要があります。
    # 以下はダミーの .seb ファイルを作成する例です。

    # --- ダミーの.sebファイルを作成 ---
    DUMMY_SEB_FILENAME = "dummy_config.seb"

    salt_bytes = b'\\x01\\x02\\x03\\x04\\x05\\x06\\x07\\x08\\t\\n\\x0b\\x0c\\r\\x0e\\x0f\\x10' \\
                 b'\\x11\\x12\\x13\\x14\\x15\\x16\\x17\\x18\\x19\\x1a\\x1b\\x1c\\x1d\\x1e\\x1f\\x20'

    dummy_settings = {
        "startURL": "https://moodle2.maizuru-ct.ac.jp/moodle/mod/quiz/view.php?id=90256",
        "org_safeexambrowser_SEB_examKeySalt": salt_bytes,
        "sendBrowserExamKey": True,
        "allowQuit": True,
    }

    # plist(XML)形式に変換
    plist_data = plistlib.dumps(dummy_settings, fmt=plistlib.FMT_XML, sort_keys=True)

    # プレフィックス 'plnd' をつけて非暗号化データとする
    prefixed_data = b'plnd' + zlib.compress(plist_data)

    # さらに全体をgzip圧縮
    final_seb_data = zlib.compress(prefixed_data)

    with open(DUMMY_SEB_FILENAME, 'wb') as f:
        f.write(final_seb_data)

    print(f"テスト用のダミー設定ファイル '{DUMMY_SEB_FILENAME}' を作成しました。")
    print("以下のコマンドでテスト実行できます:")
    print(f"python {__file__} {DUMMY_SEB_FILENAME} --url \"https://moodle2.maizuru-ct.ac.jp/moodle/mod/quiz/view.php?id=90256\"")
    print("-" * 20)

    # 引数がある場合のみmainを実行
    import sys
    if len(sys.argv) > 1:
        main()
    else:
        print("\n引数を指定して実行してください。")
