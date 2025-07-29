// SEBulator/background.js (Service Worker)

try {
    // 外部ライブラリをインポート
    importScripts('lib/pako.min.js', 'lib/fxparser.min.js', 'key-generator.js');
} catch (e) {
    console.error("Failed to import libraries. Make sure pako.min.js and fxparser.min.js are in the lib/ directory.", e);
}


// --- SEB File Parser Logic ---
function parseSebFile(fileContentArray) {
    let data = new Uint8Array(fileContentArray);

    try {
        // Gzip圧縮されているかマジックナンバーで判定
        if (data[0] === 0x1f && data[1] === 0x8b) {
            console.log("[Parser] GZIP magic number detected. Inflating...");
            data = pako.inflate(data);
        }

        const prefix = new TextDecoder().decode(data.slice(0, 4));
        let payload;

        if (prefix === 'plnd') {
            console.log("[Parser] 'plnd' prefix detected.");
            payload = data.slice(4);
            try {
                payload = pako.inflate(payload); // ペイロードもgzip圧縮されている
            } catch(e) {
                console.error("[Parser] Failed to inflate 'plnd' payload.", e);
                return { error: "Failed to inflate 'plnd' payload." };
            }
        } else if (prefix === 'pswd') {
            console.error("[Parser] Password-encrypted files are not supported yet.");
            // パスワードが必要であることをUIに通知するための情報を返す
            return { needsPassword: true };
        } else {
            // プレフィックスがない場合は、データ全体がペイロード（生のXMLの可能性）
            payload = data;
        }

        const xmlString = new TextDecoder("utf-8", { fatal: true }).decode(payload);

        if (!xmlString.trim().startsWith("<?xml")) {
            console.error("[Parser] Final payload is not a valid XML.");
            return { error: "Final payload is not a valid XML." };
        }

        const parserOptions = {
            ignoreAttributes: false,
            attributeNamePrefix: "",
            textNodeName: "#text",
            parseAttributeValue: true,
            isArray: (name, jpath, isLeafNode, isAttribute) => name === "array",
            tagValueProcessor: (tagName, tagValue) => {
                if (isLeafNode) {
                    if (tagName === 'integer') return parseInt(tagValue, 10);
                    if (tagName === 'true') return true;
                    if (tagName === 'false') return false;
                    if (tagName === 'data') {
                        const binary_string = atob(tagValue);
                        const len = binary_string.length;
                        const bytes = new Uint8Array(len);
                        for (let i = 0; i < len; i++) {
                            bytes[i] = binary_string.charCodeAt(i);
                        }
                        return bytes;
                    }
                }
                return tagValue;
            }
        };
        const parser = new XMLParser(parserOptions);
        const parsedObj = parser.parse(xmlString);

        const settings = parsedObj.plist && parsedObj.plist.dict ? parsedObj.plist.dict : null;
        if (!settings) {
            return { error: "Could not find 'dict' inside 'plist'." };
        }

        return { config: flattenPlistObject(settings) };

    } catch (e) {
        return { error: e.message };
    }
}

function flattenPlistObject(obj) {
    if (typeof obj !== 'object' || obj === null || obj instanceof Uint8Array) return obj;
    if (Array.isArray(obj)) return obj.map(flattenPlistObject);

    const newObj = {};
    const keys = obj.key ? (Array.isArray(obj.key) ? obj.key : [obj.key]) : [];
    const values = [];
    ['string', 'integer', 'true', 'false', 'dict', 'array', 'data'].forEach(type => {
        if (obj[type] !== undefined) {
             const items = Array.isArray(obj[type]) ? obj[type] : [obj[type]];
             values.push(...items);
        }
    });
    for (let i = 0; i < keys.length; i++) {
        newObj[keys[i]] = flattenPlistObject(values[i]);
    }
    const remainingKeys = Object.keys(obj).filter(k => !['key', 'string', 'integer', 'true', 'false', 'dict', 'array', 'data'].includes(k));
    for (const key of remainingKeys) {
        newObj[key] = flattenPlistObject(obj[key]);
    }
    return newObj;
}


// --- Service Worker Logic ---

chrome.runtime.onInstalled.addListener(() => {
  console.log("SEBulator V3 installed.");
  chrome.storage.session.set({ activeTabs: {} });
});

chrome.tabs.onRemoved.addListener((tabId) => deactivateSebMode(tabId));

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  let tabId = sender.tab?.id || request.tabId;
  if (!tabId) {
      console.error("Message received without a valid tab ID.");
      return false;
  }

  const originalType = request.type.replace('SEBULATOR_MAIN_TO_BG_', '');

  switch(originalType) {
    case 'LOAD_SEB_FILE':
      handleFileLoad(tabId, request.fileName, request.fileContent, request.password).then(sendResponse);
      break;
    case 'ACTIVATE_SEB_MODE':
      activateSebMode(tabId, null, "Dummy Config").then(() => sendResponse({success: true}));
      break;
    case 'DEACTIVATE_SEB_MODE':
      deactivateSebMode(tabId).then(() => sendResponse({success: true}));
      break;
    case 'GET_SEB_HEADERS':
    case 'UPDATE_JS_KEYS':
      handleKeyRequests({ ...request, type: originalType }, tabId, sendResponse);
      break;
    default:
      console.warn("Unknown message type received:", request.type);
      return false;
  }
  return true; //非同期応答を示す
});

async function handleFileLoad(tabId, fileName, fileContent, password) {
    console.log(`[Service Worker] Loading file ${fileName} for tab ${tabId}`);
    const result = await parseSebFile(fileContent, password);

    if (result?.config) {
        await activateSebMode(tabId, result.config, fileName);
        return { success: true, config: result.config };
    } else {
        return { success: false, error: result?.error || "Failed to parse .seb file.", needsPassword: result?.needsPassword };
    }
}

async function handleKeyRequests(request, tabId, sendResponse) {
  const { activeTabs } = await chrome.storage.session.get('activeTabs');
  const tabState = activeTabs[tabId];

  if (tabState && tabState.sebConfig?.sendBrowserExamKey !== false) {
    const browserExamKey = new Uint8Array(Object.values(tabState.browserExamKey));
    const configKey = new Uint8Array(Object.values(tabState.configKey));
    const userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) SEBulator/3.5";

    if (request.type === 'GET_SEB_HEADERS') {
      const requestHash = await calculateRequestHash(request.url, browserExamKey);
      const configKeyHash = await calculateRequestHash(request.url, configKey);
      sendResponse({ headers: {
        'X-SafeExamBrowser-RequestHash': requestHash,
        'X-SafeExamBrowser-ConfigKeyHash': configKeyHash,
        'User-Agent': userAgent,
      }});
    } else if (request.type === 'UPDATE_JS_KEYS') {
        const browserExamKeyHex = Array.from(browserExamKey).map(b => b.toString(16).padStart(2, '0')).join('');
        const configKeyHex = Array.from(configKey).map(b => b.toString(16).padStart(2, '0')).join('');
        sendResponse({
          success: true,
          browserExamKey: browserExamKeyHex,
          configKey: configKeyHex,
        });
    }
  } else {
    if (request.type === 'GET_SEB_HEADERS') sendResponse({ headers: null });
    if (request.type === 'UPDATE_JS_KEYS') sendResponse({ success: false, error: "Not in SEB mode." });
  }
}

async function activateSebMode(tabId, config, fileName) {
    const sebConfig = config || { startURL: "https://example.com", sendBrowserExamKey: true };

    let salt;
    if (sebConfig.org_safeexambrowser_SEB_examKeySalt && sebConfig.org_safeexambrowser_SEB_examKeySalt instanceof Uint8Array) {
        salt = sebConfig.org_safeexambrowser_SEB_examKeySalt;
    } else {
        salt = crypto.getRandomValues(new Uint8Array(32));
        sebConfig.org_safeexambrowser_SEB_examKeySalt = salt;
    }

    const browserExamKey = await generateBrowserExamKey(sebConfig, salt);
    const configKey = await generateConfigKey(sebConfig);

    const { activeTabs } = await chrome.storage.session.get('activeTabs');
    activeTabs[tabId] = {
        fileName,
        sebConfig,
        browserExamKey: Object.assign({}, browserExamKey),
        configKey: Object.assign({}, configKey),
        salt: Object.assign({}, salt)
    };
    await chrome.storage.session.set({ activeTabs });
    updateIcon(tabId, true);
}

async function deactivateSebMode(tabId) {
    const { activeTabs } = await chrome.storage.session.get('activeTabs');
    if (activeTabs[tabId]) {
        delete activeTabs[tabId];
        await chrome.storage.session.set({ activeTabs });
        updateIcon(tabId, false);
    }
}

function updateIcon(tabId, isActive) {
  const path = isActive ? "/icons/icon_active_128.png" : "/icons/icon_inactive_128.png";
  chrome.action.setIcon({ path, tabId });
}
