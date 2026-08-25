import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "placeholder", "loading", "details"]

  async analyze() {
    const file = this.inputTarget.files[0]
    if (!file) return

    this.showPreview(file)
    this.loadingTarget.classList.remove("d-none")

    const formData = new FormData()
    for (const f of this.inputTarget.files) formData.append("photos[]", f)

    const response = await fetch("/items/identify", {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "text/vnd.turbo-stream.html",
      },
      body: formData,
    })

    Turbo.renderStreamMessage(await response.text())

    this.loadingTarget.classList.add("d-none")
    this.detailsTarget.classList.remove("d-none")
  }

  showPreview(file) {
    this.previewTarget.src = URL.createObjectURL(file)
    this.previewTarget.classList.remove("d-none")
    this.placeholderTarget.classList.add("d-none")
  }
}
