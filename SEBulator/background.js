// SEBulator/background.js (Service Worker)

// このPoCではファイルを分割せず、すべてここに記述します。
// importScripts('key-generator.js', 'seb-parser.js');


// --- Key Generation Logic (from key-generator.js) ---
async function generateBrowserExamKey(settingsDict, salt) {
  const plistString = await generateSebCompliantPlist(settingsDict);
  const encoder = new TextEncoder();
  const data = encoder.encode(plistString);
  const key = await crypto.subtle.importKey("raw", salt, { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const signature = await crypto.subtle.sign("HMAC", key, data);
  return new Uint8Array(signature);
}
async function generateConfigKey(settingsDict) {
  const jsonString = await generateSebCompliantJson(settingsDict);
  const encoder = new TextEncoder();
  const data = encoder.encode(jsonString);
  const hash = await crypto.subtle.digest("SHA-256", data);
  return new Uint8Array(hash);
}
function generateSebCompliantJson(obj) { return JSON.stringify(sortObjectKeys(obj)); }
function generateSebCompliantPlist(obj) { return JSON.stringify(sortObjectKeys(obj)); } // Placeholder
function sortObjectKeys(value) {
    if (value === null || typeof value !== 'object') return value;
    if (Array.isArray(value)) return value.map(sortObjectKeys);
    const sortedKeys = Object.keys(value).sort((a, b) => a.localeCompare(b));
    const result = {};
    for (const key of sortedKeys) {
        result[key] = sortObjectKeys(value[key]);
    }
    return result;
}
async function calculateRequestHash(url, key) {
    const urlWithoutFragment = url.split('#')[0];
    const keyHex = Array.from(key).map(b => b.toString(16).padStart(2, '0')).join('');
    const combinedString = urlWithoutFragment + keyHex;
    const encoder = new TextEncoder();
    const data = encoder.encode(combinedString);
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

// --- SEB File Parser Logic (from seb-parser.js) ---
// PoCのため、このパーサーは非常に簡易的です。
// 実際にはzlib.jsやplist parserライブラリが必要です。
function parseSebFile(fileContentArray) {
    const fileContent = new Uint8Array(fileContentArray);
    // 簡易的に、非圧縮・非暗号化のplist(JSON)と仮定します。
    try {
        const decodedString = new TextDecoder().decode(fileContent);
        return JSON.parse(decodedString);
    } catch (e) {
        console.error("Failed to parse .seb file. This PoC only supports unencrypted, uncompressed JSON files masquerading as .seb files.", e);
        return null;
    }
}


// --- Service Worker Logic ---

chrome.runtime.onInstalled.addListener(() => {
  console.log("SEBulator V3 installed.");
  chrome.storage.session.set({ activeTabs: {} });
});

chrome.tabs.onRemoved.addListener((tabId) => deactivateSebMode(tabId));

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  const tabId = sender.tab?.id;
  if (!tabId && request.tabId) { // popupからの場合
      tabId = request.tabId;
  }
  if (!tabId) return false;

  switch(request.type) {
    case 'ACTIVATE_SEB_MODE':
      activateSebMode(tabId, null, "Dummy Config");
      sendResponse({success: true});
      break;
    case 'DEACTIVATE_SEB_MODE':
      deactivateSebMode(tabId);
      sendResponse({success: true});
      break;
    case 'LOAD_SEB_FILE':
      handleFileLoad(tabId, request.fileName, request.fileContent);
      sendResponse({success: true});
      break;
    case 'GET_SEB_HEADERS':
    case 'UPDATE_JS_KEYS':
      handleKeyRequests(request, tabId, sendResponse);
      break;
    default:
      return false; // 未知のメッセージ
  }
  return true; // 非同期応答
});

async function handleFileLoad(tabId, fileName, fileContent) {
    console.log(`Loading file ${fileName} for tab ${tabId}`);
    const config = parseSebFile(fileContent);
    if (config) {
        await activateSebMode(tabId, config, fileName);
    } else {
        // エラー通知などをここに実装
        console.error("Failed to load and activate SEB config.");
    }
}


async function handleKeyRequests(request, tabId, sendResponse) {
  const { activeTabs } = await chrome.storage.session.get('activeTabs');
  const tabState = activeTabs[tabId];

  if (tabState && tabState.sebConfig?.sendBrowserExamKey !== false) {
    const browserExamKey = new Uint8Array(Object.values(tabState.browserExamKey));
    const configKey = new Uint8Array(Object.values(tabState.configKey));
    const userAgent = tabState.userAgent || "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) SEBulator/3.5";

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

    let salt = sebConfig.org_safeexambrowser_SEB_examKeySalt
        ? new Uint8Array(sebConfig.org_safeexambrowser_SEB_examKeySalt)
        : crypto.getRandomValues(new Uint8Array(32));

    const browserExamKey = await generateBrowserExamKey(sebConfig, salt);
    const configKey = await generateConfigKey(sebConfig);

    const { activeTabs } = await chrome.storage.session.get('activeTabs');
    activeTabs[tabId] = {
        fileName: fileName,
        sebConfig: sebConfig,
        browserExamKey: Object.assign({}, browserExamKey),
        configKey: Object.assign({}, configKey),
        salt: Object.assign({}, salt)
    };
    await chrome.storage.session.set({ activeTabs });
    updateIcon(tabId, true);
    console.log(`SEB Mode Activated for tab ${tabId} with config: ${fileName}`);
}

async function deactivateSebMode(tabId) {
    const { activeTabs } = await chrome.storage.session.get('activeTabs');
    if (activeTabs[tabId]) {
        console.log(`Deactivating SEB Mode for tab ${tabId}.`);
        delete activeTabs[tabId];
        await chrome.storage.session.set({ activeTabs });
        updateIcon(tabId, false);
    }
}

function updateIcon(tabId, isActive) {
  const iconPath = isActive ? "/icons/icon_active_128.png" : "/icons/icon_inactive_128.png";
  chrome.action.setIcon({ path: iconPath, tabId: tabId });
}

// アイコンは物理ファイルとして配置するため、インストール時のダミー生成は不要
// ただし、アイコンファイルがないとエラーになるため、空の処理を残す
chrome.runtime.onInstalled.addListener(async () => {});
