import { Controller } from "@hotwired/stimulus"

const MAX_PHOTOS = 2

export default class extends Controller {
  static targets = [
    "input", "addBar", "addBarLabel", "filmstrip", "count",
    "continueButton", "loading", "details"
  ]

  connect() {
    this.photos = []
  }

  openPicker() {
    if (this.photos.length >= MAX_PHOTOS) return
    this.inputTarget.click()
  }

  filesSelected() {
    const room = MAX_PHOTOS - this.photos.length
    const picked = Array.from(this.inputTarget.files).slice(0, room)

    for (const file of picked) {
      this.photos.push({ file, url: URL.createObjectURL(file) })
    }

    this.syncInput()
    this.render()
  }

  removePhoto(event) {
    const index = Number(event.currentTarget.dataset.index)
    const [removed] = this.photos.splice(index, 1)
    if (removed) URL.revokeObjectURL(removed.url)

    this.syncInput()
    this.render()
  }

  syncInput() {
    const dt = new DataTransfer()
    this.photos.forEach(({ file }) => dt.items.add(file))
    this.inputTarget.files = dt.files
  }

  render() {
    this.filmstripTarget.innerHTML = ""

    this.photos.forEach(({ url }, index) => {
      const tile = document.createElement("div")
      tile.className = "photo-filmstrip-tile"
      tile.innerHTML = `
        <img src="${url}" alt="Selected photo ${index + 1}">
        <button type="button" class="photo-filmstrip-remove" data-index="${index}" data-action="photo-analyzer#removePhoto">
          <i class="fas fa-times"></i>
        </button>
      `
      this.filmstripTarget.appendChild(tile)
    })

    this.countTarget.textContent = `${this.photos.length} of ${MAX_PHOTOS} photos`

    const atCap = this.photos.length >= MAX_PHOTOS
    this.addBarTarget.disabled = atCap
    this.addBarTarget.classList.toggle("disabled", atCap)
    this.addBarLabelTarget.textContent = atCap ? `Max ${MAX_PHOTOS} photos added` : "Add Photos"

    this.continueButtonTarget.disabled = this.photos.length === 0
  }

  async analyze() {
    if (this.photos.length === 0) return

    this.loadingTarget.classList.remove("d-none")

    const formData = new FormData()
    for (const { file } of this.photos) formData.append("photos[]", file)

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
}
