function listenClick() {
  const button = document.getElementById("load-items");

  button.addEventListener("click", async () => {
    const [tab] = await chrome.tabs.query({
      active: true,
      currentWindow: true
    });

    chrome.scripting.executeScript({
      target: { tabId: tab.id },
      files: ["scripts/send-data.js"]
    });

    const url = "http://localhost:3000/api/v1/items";
    const lists = document.querySelector(".extension-lists");

    const fetchOneItem = async (target) => {
      const response = await fetch(
        `http://localhost:3000/api/v1/items/${target.dataset.id}`
      );

      const item_data = await response.json();
      lists.innerHTML = "";
      lists.insertAdjacentHTML(
        "beforeend",
        `<div data-id="${item_data.id}" class="item_data-btn">
          <p>${item_data.title}</p>
          <p>${item_data.title_ja}</p>
          <p>${item_data.category}</p>
          <p>${item_data.description_ja}</p>
        </div>`
      );
    };

    // One listener for the whole list
    lists.addEventListener("click", (event) => {
      const button = event.target.closest(".item-btn");

      if (button) {
        fetchOneItem(button);
      }
    });

    const loadData = async () => {
      const response = await fetch(url);
      const data = await response.json();
      lists.innerHTML = "";
      data.forEach((item) => {
        lists.insertAdjacentHTML(
          "beforeend",
          `<div data-id="${item.id}" class="item-btn">
            ${item.title}
          </div>`
        );
      });
    };

    loadData();
  });
}

listenClick();
