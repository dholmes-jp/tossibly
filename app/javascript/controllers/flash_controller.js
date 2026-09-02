import { Controller } from "@hotwired/stimulus"

// Auto-dismisses the flash toast: visible for 4 s, then a short fade-out
// (the .flash--leaving transition in components/_alert.scss) before removal.
export default class extends Controller {
  static values = { duration: { type: Number, default: 4000 } }

  connect() {
    this.hideTimer = setTimeout(() => {
      this.element.classList.add("flash--leaving")
      this.removeTimer = setTimeout(() => this.element.remove(), 400)
    }, this.durationValue)
  }

  disconnect() {
    clearTimeout(this.hideTimer)
    clearTimeout(this.removeTimer)
  }
}
