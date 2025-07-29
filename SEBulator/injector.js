// SEBulator/injector.js
// This script runs in the ISOLATED world and acts as the central hub.

console.log("[SEBulator Injector] Running in ISOLATED world.");

// 1. Inject the MAIN world script (`content_script.js`)
// This ensures it runs with access to the page's `window` object.
const s = document.createElement('script');
s.src = chrome.runtime.getURL('content_script.js');
s.onload = function() {
    this.remove();
};
(document.head || document.documentElement).appendChild(s);
console.log("[SEBulator Injector] Injected main world script.");


// 2. Listen for messages from the MAIN world script
window.addEventListener('message', (event) => {
  // We only accept messages from the window object itself
  if (event.source !== window || !event.data.type?.startsWith('SEB_MAIN_TO_ISO')) {
    return;
  }

  const message = event.data;
  console.log(`[SEBulator Injector] Relaying message from MAIN to BG:`, message);

  // 3. Relay the message to the background script (Service Worker)
  chrome.runtime.sendMessage({
      type: message.type.replace('SEB_MAIN_TO_ISO_', ''), // 'GET_SEB_HEADERS'など元のタイプに戻す
      requestId: message.requestId,
      payload: message.payload
  }, (response) => {
    if (chrome.runtime.lastError) {
      console.error("[SEBulator Injector] Error sending message to background:", chrome.runtime.lastError.message);
      // Relay error back to the MAIN world
      window.postMessage({
        type: `SEB_ISO_TO_MAIN_RESPONSE_${message.requestId}`,
        error: chrome.runtime.lastError.message
      }, window.location.origin);
      return;
    }

    // 4. Relay the response from the background script back to the MAIN world
    console.log(`[SEBulator Injector] Relaying response from BG to MAIN:`, response);
    window.postMessage({
      type: `SEB_ISO_TO_MAIN_RESPONSE_${message.requestId}`,
      response: response
    }, window.location.origin);
  });
});
