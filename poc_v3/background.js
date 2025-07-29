// background.js (Service Worker)

// 拡張機能がインストールされたときの初期設定
chrome.runtime.onInstalled.addListener(() => {
  console.log("SEBulator V3 PoC Service Worker installed.");
  // 初期状態としてSEBモードを無効に設定
  chrome.storage.session.set({ isSebModeActive: false });
});

// コンテンツスクリプトからのメッセージを受信するリスナー
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  // GET_SEB_HEADERS メッセージの処理
  if (request.type === 'GET_SEB_HEADERS') {
    // 現在のSEBモードの状態をストレージから取得
    chrome.storage.session.get(['isSebModeActive'], (result) => {
      if (result.isSebModeActive) {
        console.log(`[Service Worker] Received fetch from tab ${sender.tab.id} for URL: ${request.url}`);

        // --- 本来のロジック ---
        // ここで chrome.storage.session から browserExamKey と configKey を取得し、
        // request.url と組み合わせて動的なハッシュを計算する。
        // --------------------

        // PoCのため、ダミーの静的なヘッダを生成
        const dummyRequestHash = 'poc_request_hash_' + Date.now();
        const dummyConfigKeyHash = 'poc_config_key_hash_' + Date.now();
        const dummyUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.3 Safari/605.1.15 SEB/3.5 (PoC V3)";

        const headers = {
          'X-SafeExamBrowser-RequestHash': dummyRequestHash,
          'X-SafeExamBrowser-ConfigKeyHash': dummyConfigKeyHash,
          'User-Agent': dummyUserAgent,
        };

        console.log("[Service Worker] Sending dummy headers:", headers);
        // 計算した（今回はダミーの）ヘッダをコンテンツスクリプトに返す
        sendResponse({ headers });
      } else {
        // SEBモードがアクティブでない場合はヘッダを返さない
        sendResponse({ headers: null });
      }
    });

    // 非同期で sendResponse を呼び出すため true を返す
    return true;
  }
});
