// popup.js

const statusElement = document.getElementById('status');
const toggleButton = document.getElementById('toggleButton');

// ポップアップが開かれたときに現在の状態を反映
document.addEventListener('DOMContentLoaded', () => {
  chrome.storage.session.get(['isSebModeActive'], (result) => {
    updateUI(result.isSebModeActive);
  });
});

// ボタンのクリックイベント
toggleButton.addEventListener('click', () => {
  chrome.storage.session.get(['isSebModeActive'], (result) => {
    const newStatus = !result.isSebModeActive;
    chrome.storage.session.set({ isSebModeActive: newStatus }, () => {
      updateUI(newStatus);
      console.log(`SEB Mode toggled to: ${newStatus}`);
    });
  });
});

// UIを更新する関数
function updateUI(isActive) {
  if (isActive) {
    statusElement.textContent = 'Active';
    statusElement.style.color = 'green';
    toggleButton.textContent = 'Deactivate SEB Mode';
  } else {
    statusElement.textContent = 'Inactive';
    statusElement.style.color = 'red';
    toggleButton.textContent = 'Activate SEB Mode';
  }
}
