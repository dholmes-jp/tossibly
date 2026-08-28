chrome.runtime.onMessage.addListener((message) => {
  if (message.type !== "FILL_FORM") return;

  const titleInput = document.querySelector("#article_title");
  const descriptionInput = document.querySelector("#article_text");
  const prefectureSelect = document.querySelector("#article_prefecture_id");
  const citySelect = document.querySelector("#article_city_id");
  const priceSelect = document.querySelector("#article_price");

  // Title
  if (titleInput) {
    titleInput.value = message.title;

    titleInput.dispatchEvent(
      new Event("input", { bubbles: true })
    );

    titleInput.dispatchEvent(
      new Event("change", { bubbles: true })
    );
  }

  // Description
  if (descriptionInput) {
    descriptionInput.value = message.description;

    descriptionInput.dispatchEvent(
      new Event("input", { bubbles: true })
    );

    descriptionInput.dispatchEvent(
      new Event("change", { bubbles: true })
    );
  }

  // Tokyo
  if (prefectureSelect) {
    prefectureSelect.value = "13";

    prefectureSelect.dispatchEvent(
      new Event("change", { bubbles: true })
    );
  }

  // Meguro
  setTimeout(() => {
    if (citySelect) {
      citySelect.value = "265";

      citySelect.dispatchEvent(
        new Event("change", { bubbles: true })
      );
    }
  }, 1000);

  // Price
  if (priceSelect) {
    priceSelect.value = "0";

    priceSelect.dispatchEvent(
      new Event("change", { bubbles: true })
    );
  }

  // Images
  if (message.photo_urls?.length > 0) {
    handleImageInput(message.photo_urls);
  }
});

async function handleImageInput(remoteImageURLs) {
  const input = document.querySelector("#upload_tag");
  if (!input) {
    return;
  }
  // const deleteButtons = document.querySelectorAll(".delete_link");
  // deleteButtons.forEach((btn) => {
    // btn.click();
    // btn.previousElementSibling.style.display = "none";
    // btn.previousElementSibling.previousElementSibling.style.display = "none";
  // });

  await new Promise((resolve) => setTimeout(resolve, 300));
  const dt = new DataTransfer();
  for (const remoteImageURL of remoteImageURLs) {
    const file = await createFile(remoteImageURL);
    dt.items.add(file);
  }
  input.files = dt.files;
  input.dispatchEvent(
    new Event("change", {
      bubbles: true
    })
  );
  // document.querySelectorAll(".async_image_tag.square").forEach((img) => {
    // console.log(img.classList);
    // img.remove()
  // })
}

async function createFile(url) {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Failed to fetch image: ${response.status}`);
  }
  const data = await response.blob();
  return new File(
    [data],
    "item-photo.jpg",
    {
      type: data.type || "image/jpeg"
    }
  );
}
