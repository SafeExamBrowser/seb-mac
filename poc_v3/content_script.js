// content_script.js

console.log("SEBulator V3 content script injected.");

// 元の window.fetch を保存
const originalFetch = window.fetch;

// window.fetch を上書き（モンキーパッチ）
window.fetch = async (input, init) => {
  console.log("[Content Script] Intercepted fetch request:", input);

  // Service Worker にヘッダ情報を問い合わせる
  const sebHeaders = await chrome.runtime.sendMessage({
    type: 'GET_SEB_HEADERS',
    url: (input instanceof Request) ? input.url : input
  });

  // SEBモードがアクティブで、有効なヘッダが返ってきた場合
  if (sebHeaders && sebHeaders.headers) {
    console.log("[Content Script] Received SEB headers. Modifying request.", sebHeaders.headers);

    // 既存のヘッダとマージする
    const originalHeaders = init?.headers || (input instanceof Request ? input.headers : {});
    const headers = new Headers(originalHeaders);

    for (const [key, value] of Object.entries(sebHeaders.headers)) {
      headers.set(key, value);
    }

    // 新しいリクエスト情報を作成
    let newInit = { ...init, headers };

    // Requestオブジェクトの場合は作り直す
    if (input instanceof Request) {
        // ボディは一度しか読み取れないため、クローンして新しいRequestオブジェクトを作成
        const newRequest = new Request(input, newInit);
        console.log("[Content Script] Calling original fetch with modified Request object.");
        return originalFetch(newRequest);
    } else {
        console.log("[Content Script] Calling original fetch with modified init object.");
        return originalFetch(input, newInit);
    }

  } else {
    // SEBモードでない場合は、元のリクエストをそのまま実行
    console.log("[Content Script] Not in SEB mode. Calling original fetch.");
    return originalFetch(input, init);
  }
};
