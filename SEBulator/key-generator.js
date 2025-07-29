// SEBulator/key-generator.js

/**
 * SEBの `browserExamKey` の生成ロジックを再現します。
 * @param {object} settingsDict - パースされた設定オブジェクト。
 * @param {Uint8Array} salt - 使用するソルト。
 * @returns {Promise<Uint8Array>} 計算された `browserExamKey` (32バイト)。
 */
async function generateBrowserExamKey(settingsDict, salt) {
  // `NSPropertyListXMLFormat_v1_0` を模倣するため、plistlibのようなライブラリが必要。
  // ここでは簡易的にJSON.stringifyで代用するが、本実装では正確なplistシリアライズが必要。
  const plistString = JSON.stringify(sortObjectKeys(settingsDict));
  const encoder = new TextEncoder();
  const data = encoder.encode(plistString);

  const key = await crypto.subtle.importKey(
    "raw",
    salt,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign("HMAC", key, data);
  return new Uint8Array(signature);
}

/**
 * SEBの `configKey` の生成ロジックを再現します。
 * @param {object} settingsDict - パースされた設定オブジェクト。
 * @returns {Promise<Uint8Array>} 計算された `configKey` (32バイト)。
 */
async function generateConfigKey(settingsDict) {
  // 【最重要課題】SEBのObjective-C実装に合わせた、特殊なJSONシリアライズ処理が必要。
  // これは単純なJSON.stringifyでは再現できない。
  const jsonString = generateSebCompliantJson(settingsDict);
  const encoder = new TextEncoder();
  const data = encoder.encode(jsonString);

  const hash = await crypto.subtle.digest("SHA-256", data);
  return new Uint8Array(hash);
}


/**
 * SEBの特殊なJSONシリアライズを模倣する（簡易版）。
 * TODO: この関数はリバースエンジニアリングに基づき、より正確に実装する必要がある。
 * @param {object} obj - 設定オブジェクト。
 * @returns {string} - JSON文字列。
 */
function generateSebCompliantJson(obj) {
  // SEBの `- (NSDictionary *)getConfigKeyDictionaryForKey:...` のロジックをここに実装する。
  // - キーのアルファベット順ソート
  // - 特定キーの除外（例: originatorVersion）
  // - データ型の特殊な文字列表現（例: NSData -> Base64）
  // - ネストしたオブジェクトの再帰的処理

  // PoC段階では、単純なソート済みJSONで代用する。
  return JSON.stringify(sortObjectKeys(obj));
}


/**
 * オブジェクトのキーを再帰的にソートするヘルパー関数。
 * @param {*} value - ソート対象のオブジェクト。
 * @returns {*} - キーがソートされたオブジェクト。
 */
function sortObjectKeys(value) {
    if (value === null || typeof value !== 'object') {
        return value;
    }
    if (Array.isArray(value)) {
        return value.map(sortObjectKeys);
    }
    const sortedKeys = Object.keys(value).sort((a, b) => a.localeCompare(b));
    const result = {};
    for (const key of sortedKeys) {
        result[key] = sortObjectKeys(value[key]);
    }
    return result;
}
