// SEBulator/key-generator.js

/**
 * SEBの `browserExamKey` の生成ロジックを再現します。
 * @param {object} settingsDict - パースされた設定オブジェクト。
 * @param {Uint8Array} salt - 使用するソルト。
 * @returns {Promise<Uint8Array>} 計算された `browserExamKey` (32バイト)。
 */
async function generateBrowserExamKey(settingsDict, salt) {
  // `NSPropertyListSerialization` (format: NSPropertyListXMLFormat_v1_0) の出力を模倣
  const plistString = dictToPlistXml(settingsDict);
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
  const jsonString = generateSebCompliantJson(settingsDict);
  const encoder = new TextEncoder();
  const data = encoder.encode(jsonString);
  const hash = await crypto.subtle.digest("SHA-256", data);
  return new Uint8Array(hash);
}

/**
 * SEBの `getConfigKeyDictionaryForKey:` の動作を模倣し、
 * 特殊なルールでJSON文字列を生成します。
 * @param {object} obj - 設定オブジェクト。
 * @returns {string} - SEB互換のJSON文字列。
 */
function generateSebCompliantJson(obj) {
    if (obj === null || typeof obj !== 'object') {
        return objectToJsonString(obj);
    }

    if (Array.isArray(obj)) {
        const arrayItems = obj.map(item => generateSebCompliantJson(item));
        return `[${arrayItems.join(',')}]`;
    }

    const sortedKeys = Object.keys(obj)
        .filter(key => key !== 'originatorVersion')
        .sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()));

    const keyValuePairs = sortedKeys.map(key => {
        const valueJson = generateSebCompliantJson(obj[key]);
        return `"${key}":${valueJson}`;
    });

    return `{${keyValuePairs.join(',')}}`;
}

/**
 * SEBの `jsonStringForObject:` の動作を模倣し、
 * 個々の値をJSON文字列フラグメントに変換します。
 * @param {*} value - 変換する値。
 * @returns {string} - JSON文字列フラグメント。
 */
function objectToJsonString(value) {
    if (typeof value === 'string') {
        // JSON標準に従い、特殊文字をエスケープ
        return JSON.stringify(value);
    }
    if (typeof value === 'boolean') {
        return value ? 'true' : 'false';
    }
    if (typeof value === 'number') {
        return String(value);
    }
    if (value instanceof Uint8Array) {
        if (value.length === 0) return '""';
        let binary = '';
        for (let i = 0; i < value.byteLength; i++) {
            binary += String.fromCharCode(value[i]);
        }
        return `"${btoa(binary)}"`;
    }
    return '""'; // null, undefinedなどは空文字列のJSON表現に
}


/**
 * JavaScriptオブジェクトをplistのXML文字列に変換する。
 * NSPropertyListSerialization (format: NSPropertyListXMLFormat_v1_0) の出力を模倣する。
 * @param {object} obj - 設定オブジェクト。
 * @returns {string} - plistの<dict>タグの内部XML。
 */
function dictToPlistXml(obj) {
    let xml = '';
    // SEBのキーはソートされないようなので、そのままの順序で処理
    // const sortedKeys = Object.keys(obj).sort((a, b) => a.localeCompare(b));
    const keys = Object.keys(obj);

    for (const key of keys) {
        xml += `<key>${key}</key>`;
        xml += objectToPlistValue(obj[key]);
    }
    return xml;
}

/**
 * JavaScriptの値を対応するplistのXML値タグに変換する。
 * @param {*} value - 変換する値。
 * @returns {string} - plistの値タグ（<string>, <integer>など）。
 */
function objectToPlistValue(value) {
    switch (typeof value) {
        case 'string':
            return `<string>${value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')}</string>`;
        case 'number':
            if (Number.isInteger(value)) {
                return `<integer>${value}</integer>`;
            }
            return `<real>${value}</real>`; // 浮動小数点の場合
        case 'boolean':
            return value ? '<true/>' : '<false/>';
        case 'object':
            if (value === null) {
                return '<string></string>'; // nullは空文字列として扱う
            }
            if (value instanceof Uint8Array) {
                let binary = '';
                for (let i = 0; i < value.byteLength; i++) {
                    binary += String.fromCharCode(value[i]);
                }
                return `<data>${btoa(binary)}</data>`;
            }
            if (Array.isArray(value)) {
                const items = value.map(objectToPlistValue).join('');
                return `<array>${items}</array>`;
            }
            // 通常のオブジェクトはdictとして再帰的に処理
            return `<dict>${dictToPlistXml(value)}</dict>`;
        default:
            return `<string></string>`; // undefinedなど
    }
}
