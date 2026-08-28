// Replace the following URL to Heroku URL
const BASE_URL = "http://localhost:3000";

function listenClick() {
  const button = document.getElementById("load-items");

  button.addEventListener("click", async () => {
    const url = `${BASE_URL}/api/v1/items`;
    const lists = document.querySelector(".extension-lists");

    const loadData = async () => {
      const response = await fetch(url);
      const data = await response.json();

      lists.innerHTML = "";

      data.forEach((item) => {
        lists.insertAdjacentHTML(
          "beforeend",
          `<div data-id="${item.id}" class="item-btn">
            ${item.title}
            <button class="autofill-btn">Auto-fill</button>
          </div>`
        );
      });
    };

    const fetchOneItem = async (target) => {
      const response = await fetch(
        `${BASE_URL}/api/v1/items/${target.dataset.id}`
      );

      const item_data = await response.json();

      // Get the current tab
      const [tab] = await chrome.tabs.query({
        active: true,
        currentWindow: true
      });

      // Send item data to content.js
      chrome.tabs.sendMessage(tab.id, {
        type: "FILL_FORM",
        title: item_data.title_ja,
        description: item_data.description_ja,
        photo_urls: item_data.photo_urls
      });
    };

    lists.addEventListener("click", (event) => {
      const button = event.target.closest(".item-btn");

      if (button) {
        fetchOneItem(button);
      }
    });

    await loadData();
  });
}

listenClick();
