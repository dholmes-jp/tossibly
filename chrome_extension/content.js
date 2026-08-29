const AUTOFILL_KEY = "tossibly_autofill";
chrome.runtime.onMessage.addListener((message) => {
  if (message.type !== "FILL_FORM") return;
    // Save item data before reloading
  sessionStorage.setItem(
    AUTOFILL_KEY,
    JSON.stringify(message)
  );

  // Completely reset the Jimoty page
  window.location.reload();
});

// Check if there is an item waiting to be auto-filled
const savedMessage = sessionStorage.getItem(AUTOFILL_KEY);

if (savedMessage) {
  // Remove it first so the page does not reload/fill repeatedly
  sessionStorage.removeItem(AUTOFILL_KEY);

  const message = JSON.parse(savedMessage);

  fillForm(message);
}

async function fillForm(message) {
  const titleInput = document.querySelector("#article_title");
  const descriptionInput = document.querySelector("#article_text");
  const prefectureSelect = document.querySelector("#article_prefecture_id");
  const priceSelect = document.querySelector("#article_price");

  // Categories | 2nd
  const categorySelect = document.querySelector("#article_category_id");
  if (categorySelect) {
    categorySelect.value = message.jimoty_category_value;
    categorySelect.dispatchEvent(
      new Event("change", { bubbles: true })
    );
  }

  await new Promise((resolve) => setTimeout(resolve, 300));

  // Categories | 3rd
  const largeGenreSelect = document.querySelector("#article_large_genre_id");
  if (largeGenreSelect) {
    largeGenreSelect.value = message.jimoty_large_genre_value;
    largeGenreSelect.dispatchEvent(
      new Event("change", { bubbles: true })
    );
  }

  await new Promise((resolve) => setTimeout(resolve, 300));

  // Categories | 4th
  const mediumGenreSelect = document.querySelector("#article_medium_genre_id");
  if (mediumGenreSelect) {
    mediumGenreSelect.value = message.jimoty_medium_genre_value;
    mediumGenreSelect.dispatchEvent(
      new Event("change", { bubbles: true })
    );
  }

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

  await new Promise((resolve) => setTimeout(resolve, 1000));

  // Meguro
  const citySelect = document.querySelector("#article_city_id");
  if (citySelect) {
    citySelect.value = "265";
    citySelect.dispatchEvent(
      new Event("change", { bubbles: true })
    );
  }

  // Price
  if (priceSelect) {
    priceSelect.value = message.price;
    priceSelect.dispatchEvent(
      new Event("input", { bubbles: true })
    );
    priceSelect.dispatchEvent(
      new Event("change", { bubbles: true })
    );
  }

  // Images
  if (message.photo_urls?.length > 0) {
    await handleImageInput(message.photo_urls);
  }
}

async function handleImageInput(remoteImageURLs) {
  const input = document.querySelector("#upload_tag");

  if (!input) {
    return;
  }

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

// Submit button from chrome extension
chrome.runtime.onMessage.addListener((message) => {
  if (message.type !== "SUBMIT_FORM") return;

  const submitButton = document.querySelector(
    "#article_submit_button"
  );

  if (submitButton) {
    submitButton.click();
  }
});
