// SEBulator/content_script.js
// This script runs in the MAIN world.

// スクリプトが既に注入済みかチェックするガード
if (window.sebulatorContentScriptInjected) {
  console.log("[SEBulator Content Script] Already injected. Skipping initialization.");
} else {
  window.sebulatorContentScriptInjected = true;
  console.log("SEBulator V3 content script (v3) initializing in MAIN world.");

  // --- Message Bridging with ISOLATED world ---

  const pendingPromises = new Map();
  let requestIdCounter = 0;

  // ISOLATEDワールド(injector.js)からの応答を待ち受ける
  window.addEventListener('message', (event) => {
      if (event.source !== window || !event.data.type?.startsWith('SEBULATOR_BG_TO_MAIN_RESPONSE_')) {
          return;
      }
      const message = event.data;
      const requestId = parseInt(message.type.split('_').pop(), 10);

      if (pendingPromises.has(requestId)) {
          const { resolve, reject } = pendingPromises.get(requestId);
          if (message.error) {
              reject(new Error(message.error));
          } else {
              resolve(message.response);
          }
          pendingPromises.delete(requestId);
      }
  });

  // Service Workerにメッセージを送信するための新しい関数
  function sendMessageToServiceWorker(message) {
      const requestId = requestIdCounter++;
      const messageToSend = { ...message, type: `SEBULATOR_MAIN_TO_BG_${message.type}`, requestId };

      return new Promise((resolve, reject) => {
          pendingPromises.set(requestId, { resolve, reject });
          // タイムアウト処理
          setTimeout(() => {
              if (pendingPromises.has(requestId)) {
                  pendingPromises.delete(requestId);
                  reject(new Error(`[SEBulator] Message request ${requestId} (${message.type}) timed out.`));
              }
          }, 5000); // 5秒のタイムアウト
          window.postMessage(messageToSend, window.location.origin);
      });
  }

  // --- `fetch` の上書き ---
  const originalFetch = window.fetch;
  window.fetch = async (input, init) => {
    const url = (input instanceof Request) ? input.url : input;

    try {
      const sebHeaders = await sendMessageToServiceWorker({ type: 'GET_SEB_HEADERS', url });

      if (sebHeaders && sebHeaders.headers) {
        console.log("[SEBulator] Modifying headers for fetch:", sebHeaders.headers);
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
    version: 'SEBulator/1.2 (based on SEB 3.5)',
    security: {
      browserExamKey: '',
      configKey: '',
      appVersion: 'SEBulator/1.2',
      updateKeys: (callback) => {
        console.log("[SEBulator] window.SafeExamBrowser.security.updateKeys() called.");

        sendMessageToServiceWorker({ type: 'UPDATE_JS_KEYS', url: window.location.href })
          .then(response => {
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
          })
          .catch(error => {
              console.error("[SEBulator] Error sending UPDATE_JS_KEYS message:", error);
          });
      }
    }
  };

  Object.defineProperty(window, 'SafeExamBrowser', {
    value: SEB_API,
    writable: false,
    configurable: true
  });

  console.log("[SEBulator] `window.SafeExamBrowser` API is now available.");
}
