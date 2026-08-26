chrome.action.onClicked.addListener((tab) => {
  chrome.scripting.executeScript({
    target: { tabId: tab.id },
    func: changeBackgroundColor
  });
});

function changeBackgroundColor() {
  document.body.style.backgroundColor = "#C3413B";
}
