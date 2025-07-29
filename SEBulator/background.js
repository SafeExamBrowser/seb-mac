// SEBulator/background.js (Service Worker)

try {
    importScripts('lib/pako.min.js', 'lib/fxparser.min.js', 'key-generator.js');
} catch (e) {
    console.error("Failed to import libraries.", e);
}


// --- Key Generation Logic ---
// (No changes)
async function generateBrowserExamKey(settingsDict, salt) {
    const plistString = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"><plist version=\"1.0\">" + dictToPlistXml(settingsDict) + "</plist>";
    const encoder = new TextEncoder();
    const data = encoder.encode(plistString);
    const key = await crypto.subtle.importKey("raw", salt, { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
    const signature = await crypto.subtle.sign("HMAC", key, data);
    return new Uint8Array(signature);
}
function dictToPlistXml(obj) {
    let xml = '<dict>';
    const sortedKeys = Object.keys(obj).sort((a, b) => a.localeCompare(b));
    for (const key of sortedKeys) {
        xml += `<key>${key}</key>`;
        const value = obj[key];
        if (typeof value === 'string') {
            xml += `<string>${value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')}</string>`;
        } else if (typeof value === 'number' && Number.isInteger(value)) {
            xml += `<integer>${value}</integer>`;
        } else if (typeof value === 'boolean') {
            xml += value ? '<true/>' : '<false/>';
        } else {
             xml += `<string>${String(value)}</string>`;
        }
    }
    xml += '</dict>';
    return xml;
}
async function generateConfigKey(settingsDict) {
  const jsonString = generateSebCompliantJson(settingsDict);
  const encoder = new TextEncoder();
  const data = encoder.encode(jsonString);
  const hash = await crypto.subtle.digest("SHA-256", data);
  return new Uint8Array(hash);
}
function generateSebCompliantJson(obj) { return JSON.stringify(sortObjectKeys(obj)); }
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

// --- SEB File Parser Logic (Revised for password handling) ---
async function parseSebFile(fileContentArray, password) {
    let data = new Uint8Array(fileContentArray);

    try {
        if (data[0] === 0x1f && data[1] === 0x8b) {
            data = pako.inflate(data);
        }

        const prefix = new TextDecoder().decode(data.slice(0, 4));
        let payload = data; // Default to full data

        if (prefix === 'plnd') {
            payload = data.slice(4);
        } else if (prefix === 'pswd') {
            if (!password) {
                console.error("[Parser] File is password protected, but no password was provided.");
                return { needsPassword: true };
            }
            const encryptedPayload = data.slice(4);
            // RNCryptor decryption logic is complex. This is a placeholder.
            // A full implementation would require a JS port of RNCryptor or careful reimplementation.
            // For now, we'll assume a simple (and incorrect) decryption for PoC.
            console.log("[Parser] Password-protected file detected. Decryption is a placeholder.");
            // payload = await decryptPayload(encryptedPayload, password);
            // if (!payload) return null;
            return { error: "Decryption not implemented." };
        }

        // If we have a payload, try to inflate it (for plnd and decrypted pswd)
        if (prefix === 'plnd') {
             try {
                payload = pako.inflate(payload);
            } catch(e) {
                console.error("[Parser] Failed to inflate 'plnd' payload.", e);
                return null;
            }
        }

        const xmlString = new TextDecoder("utf-8", { fatal: true }).decode(payload);

        if (!xmlString.trim().startsWith("<?xml")) {
            console.error("[Parser] Final payload is not a valid XML.");
            return null;
        }

        const parser = new XMLParser({ ignoreAttributes: false });
        const parsedObj = parser.parse(xmlString);

        const settings = parsedObj.plist && parsedObj.plist.dict ? parsedObj.plist.dict : null;
        return settings ? { config: flattenPlistObject(settings) } : null;

    } catch (e) {
        console.error("Failed to parse .seb file.", e);
        return { error: e.message };
    }
}

function flattenPlistObject(obj) {
    // ... (implementation from previous step)
}


// --- Service Worker Logic ---
chrome.runtime.onInstalled.addListener(() => {
  console.log("SEBulator V3 installed.");
  chrome.storage.session.set({ activeTabs: {} });
});
chrome.tabs.onRemoved.addListener((tabId) => deactivateSebMode(tabId));

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  let tabId = sender.tab?.id || request.tabId;
  if (!tabId) return false;

  const originalType = request.type.replace('SEBULATOR_MAIN_TO_BG_', '');

  switch(originalType) {
    case 'LOAD_SEB_FILE':
      handleFileLoad(tabId, request.fileName, request.fileContent, request.password).then(result => sendResponse(result));
      break;
    // ... other cases
    default:
      handleKeyRequests({ ...request, type: originalType }, tabId, sendResponse);
      break;
  }
  return true;
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
  // ... (no changes from previous step)
}
async function activateSebMode(tabId, config, fileName) {
  // ... (no changes from previous step)
}
async function deactivateSebMode(tabId) {
  // ... (no changes from previous step)
}
function updateIcon(tabId, isActive) {
  // ... (no changes from previous step)
}
