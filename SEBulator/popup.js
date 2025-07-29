// SEBulator/popup.js

const statusElement = document.getElementById('status');
const toggleButton = document.getElementById('toggleButton');
const fileInput = document.getElementById('fileInput');
const loadButton = document.getElementById('loadButton');
const currentConfig = document.getElementById('currentConfig');

let currentTabId;

// ポップアップが開かれたときに現在のタブ情報を取得し、UIを更新
document.addEventListener('DOMContentLoaded', async () => {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  currentTabId = tab.id;

  const { activeTabs } = await chrome.storage.session.get('activeTabs');
  const tabState = activeTabs ? activeTabs[currentTabId] : null;
  updateUI(tabState);
});

// モード切替ボタンのクリックイベント
toggleButton.addEventListener('click', async () => {
    const { activeTabs } = await chrome.storage.session.get('activeTabs');
    const isActive = !!activeTabs[currentTabId];

    if (isActive) {
        // Deactivate
        await chrome.runtime.sendMessage({ type: 'DEACTIVATE_SEB_MODE', tabId: currentTabId });
        updateUI(null);
    } else {
        // Activate with dummy data
        await chrome.runtime.sendMessage({ type: 'ACTIVATE_SEB_MODE', tabId: currentTabId });
        const { activeTabs: updatedTabs } = await chrome.storage.session.get('activeTabs');
        updateUI(updatedTabs[currentTabId]);
    }
});

// ファイル読み込みボタンのイベント
loadButton.addEventListener('click', () => {
    const file = fileInput.files[0];
    if (file) {
        const reader = new FileReader();
        reader.onload = async (e) => {
            const fileContent = e.target.result;
            // ArrayBufferをbackgroundに送る
            await chrome.runtime.sendMessage({
                type: 'LOAD_SEB_FILE',
                tabId: currentTabId,
                fileName: file.name,
                fileContent: Array.from(new Uint8Array(fileContent)) // JSONにシリアライズ可能な形式に
            });
            // UIを更新
            const { activeTabs } = await chrome.storage.session.get('activeTabs');
            updateUI(activeTabs[currentTabId]);
        };
        reader.readAsArrayBuffer(file);
    } else {
        currentConfig.textContent = "No file selected.";
    }
});


// UIを更新する関数
function updateUI(tabState) {
  if (tabState && tabState.sebConfig) {
    statusElement.textContent = 'Active';
    statusElement.style.color = 'green';
    toggleButton.textContent = 'Deactivate SEB Mode';
    currentConfig.textContent = `Config: ${tabState.fileName || 'Dummy Config'}`;
    loadButton.disabled = true;
    fileInput.disabled = true;
  } else {
    statusElement.textContent = 'Inactive';
    statusElement.style.color = 'red';
    toggleButton.textContent = 'Activate (Dummy)';
    currentConfig.textContent = "No config loaded.";
    loadButton.disabled = false;
    fileInput.disabled = false;
  }
}
