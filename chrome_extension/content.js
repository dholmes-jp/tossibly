console.log("🔥 Tossibly content.js loaded!");

chrome.runtime.onMessage.addListener((message) => {
  if (message.type === "FILL_FORM") {
    console.log("Received:", message);

    const titleInput = document.querySelector("#article_title");
    const descriptionInput = document.querySelector("#article_text");
    const prefectureSelect = document.querySelector("#article_prefecture_id");
    const citySelect = document.querySelector("#article_city_id");
    const priceSelect = document.querySelector("#article_price");

    // Always select Tokyo
    if (prefectureSelect) {
      console.log("prefecture select:", prefectureSelect);
      console.log("prefecture options:", prefectureSelect.options.length);
      console.log("prefecture value before:", prefectureSelect.value);

      prefectureSelect.value = "13";

      prefectureSelect.dispatchEvent(
        new Event("change", { bubbles: true })
      );

      setTimeout(() => {
        // const citySelect = document.querySelector('#article_city');
        citySelect.value = '265'; // Replace with your target city value
        citySelect.dispatchEvent(new Event('change', { bubbles: true }));
      }, 1000);
      console.log("City select:", citySelect);
      console.log("City options:", citySelect.options.length);
      console.log("City value before:", citySelect.value);
      // Always select Meguro
      // if (citySelect) {
        // citySelect.value = "265";
        // citySelect.dispatchEvent(
        //   new Event("change", { bubbles: true })
        // );
      // }
    }

    // Always price is 0
    if (priceSelect) {
      priceSelect.value = "0";

      priceSelect.dispatchEvent(
        new Event("change", { bubbles: true })
      );
    }

    // Fill title
    if (titleInput) {
      titleInput.value = message.title;

      titleInput.dispatchEvent(
        new Event("input", { bubbles: true })
      );

      titleInput.dispatchEvent(
        new Event("change", { bubbles: true })
      );
    }

    // Fill description
    if (descriptionInput) {
      descriptionInput.value = message.description;

      descriptionInput.dispatchEvent(
        new Event("input", { bubbles: true })
      );

      descriptionInput.dispatchEvent(
        new Event("change", { bubbles: true })
      );
    }
  }
});
