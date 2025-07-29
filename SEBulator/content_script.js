// SEBulator/content_script.js

console.log("SEBulator V3 content script injected into MAIN world.");

// --- `fetch` の上書き ---
const originalFetch = window.fetch;
window.fetch = async (input, init) => {
  const url = (input instanceof Request) ? input.url : input;
  console.log("[SEBulator] Intercepted fetch request:", url);

  try {
    const sebHeaders = await chrome.runtime.sendMessage({ type: 'GET_SEB_HEADERS', url });

    if (sebHeaders && sebHeaders.headers) {
      console.log("[SEBulator] Modifying headers:", sebHeaders.headers);
      const headers = new Headers(init?.headers || (input instanceof Request ? input.headers : {}));
      for (const [key, value] of Object.entries(sebHeaders.headers)) {
        headers.set(key, value);
      }
      const newInit = { ...init, headers };

      if (input instanceof Request) {
        return originalFetch(new Request(input, newInit));
      }
      return originalFetch(input, newInit);
    }
  } catch (error) {
    console.error("[SEBulator] Error during fetch modification:", error);
  }

  return originalFetch(input, init);
};


// --- `window.SafeExamBrowser` API の実装 ---
const SEB_API = {
  version: 'SEBulator/1.0 (based on SEB 3.5)',
  security: {
    browserExamKey: '',
    configKey: '',
    appVersion: 'SEBulator/1.0',
    updateKeys: (callback) => {
      console.log("[SEBulator] window.SafeExamBrowser.security.updateKeys() called.");

      chrome.runtime.sendMessage({ type: 'UPDATE_JS_KEYS', url: window.location.href }, (response) => {
        if (response && response.success) {
          console.log("[SEBulator] Keys updated for JS API:", response);
          SEB_API.security.browserExamKey = response.browserExamKey;
          SEB_API.security.configKey = response.configKey;

          if (callback && typeof window[callback] === 'function') {
            console.log(`[SEBulator] Executing callback function: ${callback}()`);
            window[callback]();
          }
        } else {
          console.error("[SEBulator] Failed to update keys for JS API.", response?.error);
        }
      });
    }
  }
};

// `window.SafeExamBrowser` を定義
// `Object.defineProperty` を使うことで、LMS側から上書きされにくくする
Object.defineProperty(window, 'SafeExamBrowser', {
  value: SEB_API,
  writable: false,
  configurable: true
});

console.log("[SEBulator] `window.SafeExamBrowser` API is now available.");
