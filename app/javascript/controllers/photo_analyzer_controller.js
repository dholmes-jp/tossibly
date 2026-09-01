import { Controller } from "@hotwired/stimulus"

const MAX_PHOTOS = 2

export default class extends Controller {
  static targets = [
    "input", "addBar", "addBarLabel", "filmstrip", "count",
    "continueButton", "loading", "details",
    "conditionRadio", "functionalInput"
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

    // NEW: drop the first photo into the scanning state and bring it on screen
    const scanPhoto = this.loadingTarget.querySelector(".scan-scanning__photo")
    if (scanPhoto && this.photos[0]) scanPhoto.src = this.photos[0].url

    this.loadingTarget.classList.remove("d-none")
    this.loadingTarget.scrollIntoView({ behavior: "smooth", block: "center" }) // NEW

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

    // The condition pills / functionalInput target only exist in the ask-case
    // (_follow_up_questions). The skip-case (_single_path_result) renders neither,
    // so guard before touching them or applyCondition() throws on a missing target.
    if (this.hasFunctionalInputTarget) {
      const conditionGuess = document.querySelector('input[name="item[condition_guess]"]')?.value
      this.selectConditionFromGuess(conditionGuess)
    }

    this.loadingTarget.classList.add("d-none")
    this.detailsTarget.classList.remove("d-none")
  }

  conditionChanged(event) {
    this.applyCondition(event.currentTarget.value)
  }

  selectConditionFromGuess(guess) {
    const g = (guess || "").toLowerCase()
    let condition = "Good"

    if (g.includes("like new")) condition = "Like new"
    else if (g.includes("new")) condition = "New"
    else if (g.includes("good")) condition = "Good"
    else if (g.includes("fair") || g.includes("worn")) condition = "Fair"
    else if (g.includes("not working") || g.includes("broken")) condition = "Not working"

    this.applyCondition(condition)
  }

  applyCondition(value) {
    this.conditionRadioTargets.forEach((radio) => {
      const selected = radio.value === value
      radio.checked = selected
      radio.closest(".condition-pill").classList.toggle("active", selected)
    })

    this.functionalInputTarget.value = value === "Not working" ? "false" : "true"
  }
}
