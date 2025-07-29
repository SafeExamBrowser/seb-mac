// SEBulator/options.js

const statusElement = document.getElementById('status');
const currentConfigElement = document.getElementById('currentConfig');
const fileInput = document.getElementById('fileInput');
const loadButton = document.getElementById('loadButton');
const passwordSection = document.getElementById('password-section');
const passwordInput = document.getElementById('passwordInput');
const errorMessageElement = document.getElementById('errorMessage');

let currentTabId;
let selectedFile;

// ページが読み込まれたときに現在のタブの状態を表示
document.addEventListener('DOMContentLoaded', async () => {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  if (tab) {
    currentTabId = tab.id;
    updateStatusForTab(currentTabId);
  } else {
    statusElement.textContent = "No active tab found.";
    statusElement.style.color = 'orange';
  }
});

// タブが切り替わったときに表示を更新
chrome.tabs.onActivated.addListener(async (activeInfo) => {
    currentTabId = activeInfo.tabId;
    updateStatusForTab(currentTabId);
});

// ファイルが選択されたときのイベント
fileInput.addEventListener('change', (event) => {
    selectedFile = event.target.files[0];
    if (selectedFile) {
        // パスワードセクションを一旦隠す
        passwordSection.style.display = 'none';
        passwordInput.value = '';
        errorMessageElement.textContent = '';
        console.log(`File selected: ${selectedFile.name}`);
    }
});


// ファイル読み込みボタンのイベント
loadButton.addEventListener('click', () => {
    if (!currentTabId) {
        alert("Please focus a tab to activate SEB mode on.");
        return;
    }
    if (!selectedFile) {
        alert("No file selected.");
        return;
    }

    const reader = new FileReader();
    reader.onload = async (e) => {
        const fileContentBuffer = e.target.result;
        const fileContentArray = Array.from(new Uint8Array(fileContentBuffer));

        console.log(`[Options Page] Sending file ${selectedFile.name} to background script for tab ${currentTabId}.`);

        const response = await chrome.runtime.sendMessage({
            type: 'LOAD_SEB_FILE',
            tabId: currentTabId,
            fileName: selectedFile.name,
            fileContent: fileContentArray,
            password: passwordInput.value || null
        });

        handleLoadResponse(response);
    };
    reader.readAsArrayBuffer(selectedFile);
});

// backgroundからの応答を処理する関数
function handleLoadResponse(response) {
    if (response.success) {
        errorMessageElement.textContent = '';
        passwordSection.style.display = 'none';
        updateStatusForTab(currentTabId);
    } else {
        errorMessageElement.textContent = `Error: ${response.error}`;
        if (response.needsPassword) {
            passwordSection.style.display = 'block';
            passwordInput.focus();
            errorMessageElement.textContent = 'This file is encrypted. Please provide a password.';
        }
    }
}


// 指定されたタブIDの状態をUIに反映させる関数
async function updateStatusForTab(tabId) {
    const { activeTabs } = await chrome.storage.session.get('activeTabs');
    const tabState = activeTabs ? activeTabs[tabId] : null;

    if (tabState && tabState.sebConfig) {
        statusElement.textContent = `Active on Tab ${tabId}`;
        statusElement.style.color = 'green';
        currentConfigElement.textContent = `Config: ${tabState.fileName || 'Unknown Config'}`;
        loadButton.disabled = true;
        fileInput.disabled = true;
        passwordSection.style.display = 'none';
    } else {
        statusElement.textContent = `Inactive on Tab ${tabId}`;
        statusElement.style.color = 'red';
        currentConfigElement.textContent = "No config loaded for this tab.";
        loadButton.disabled = false;
        fileInput.disabled = false;
    }
}
