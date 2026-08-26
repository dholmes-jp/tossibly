function fetchData() {
  const title = document.title;
  const url = window.location.href;

  return {
    title: title,
    url: url
  };
}

function sendData(data) {
  const url = "https://chat.api.lewagon.com/engineering/messages";

  fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      author: "Tossibly chrome extension",
      content: `I've found something cool: ${data.title} on ${data.url}`
    })
  });
}

sendData(fetchData());
