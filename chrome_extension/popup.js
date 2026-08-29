// Replace the following URL to Heroku URL
const BASE_URL = "http://localhost:3000";
// const BASE_URL = "https://tossibly-519656c75f63.herokuapp.com";

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
          `<div class="item">
            <p>${item.title}</p>
            <button class="autofill-btn" data-id="${item.id}">Auto-fill</button>
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
        price: item_data.confirmed_price,
        photo_urls: item_data.photo_urls,
        jimoty_category_value: item_data.jimoty_category_value,
        jimoty_large_genre_value: item_data.jimoty_large_genre_value,
        jimoty_medium_genre_value: item_data.jimoty_medium_genre_value
      });
    };

    lists.addEventListener("click", (event) => {
      const button = event.target.closest(".autofill-btn");

      if (button) {
        fetchOneItem(button);
      }
    });

    await loadData();
  });
}

listenClick();
