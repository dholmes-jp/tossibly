import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  async analyze() {
    const formData = new FormData()
    for (const file of this.inputTarget.files) formData.append("photos[]", file)

    const response = await fetch("/items/identify", {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "text/vnd.turbo-stream.html",
      },
      body: formData,
    })

    Turbo.renderStreamMessage(await response.text())
  }
}
