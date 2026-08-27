import { Controller } from "@hotwired/stimulus"

// Landing page only: navbar starts hidden, slides in once the user scrolls.
export default class extends Controller {
  static values = { threshold: { type: Number, default: 120 } }

  connect() {
    this.update()
  }

  update() {
    const hidden = window.scrollY < this.thresholdValue
    this.element.classList.toggle("navbar--hidden", hidden)
  }
}
