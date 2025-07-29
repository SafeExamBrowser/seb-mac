// SEBulator/popup.js

const statusElement = document.getElementById('status');
const configElement = document.getElementById('currentConfig');
const optionsButton = document.getElementById('optionsButton');

let currentTabId;

// ポップアップが開かれたときに現在のタブの状態をポーリングしてUIを更新
document.addEventListener('DOMContentLoaded', async () => {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    if (tab) {
        currentTabId = tab.id;
        updateUIForTab(currentTabId);
    } else {
        statusElement.textContent = 'No active tab.';
        statusElement.style.color = 'orange';
    }
});

// 設定ページを開くボタンのリスナー
optionsButton.addEventListener('click', () => {
  chrome.runtime.openOptionsPage();
});

// ストレージの変更を監視してUIをリアルタイムに更新
chrome.storage.onChanged.addListener((changes, area) => {
    if (area === 'session' && changes.activeTabs && currentTabId) {
        console.log("Storage changed, updating UI.");
        updateUIForTab(currentTabId);
    }
});

// 指定されたタブIDの状態をUIに反映させる関数
async function updateUIForTab(tabId) {
    const { activeTabs } = await chrome.storage.session.get('activeTabs');
    const tabState = activeTabs ? activeTabs[tabId] : null;

    if (tabState && tabState.sebConfig) {
        statusElement.textContent = 'Active';
        statusElement.style.color = 'green';
        configElement.textContent = `Config: ${tabState.fileName || 'Dummy Config'}`;
    } else {
        statusElement.textContent = 'Inactive';
        statusElement.style.color = 'red';
        configElement.textContent = 'No config loaded.';
    }
}
