import { Controller } from "@hotwired/stimulus"

// Full-screen "checking the best way forward" overlay shown while the
// "Create listing" form submits. turbo:submit-start fires only for real form
// submissions Turbo Drive intercepts, so the identify step's manual fetch()
// never triggers it. turbo:load clears the overlay on the next full visit
// (item show page, or a re-rendered new page on validation error); pageshow
// covers the bfcache back-button case so the spinner is never left stuck.
export default class extends Controller {
  static targets = ["overlay"]

  connect() {
    this.show = this.show.bind(this)
    this.hide = this.hide.bind(this)
    document.addEventListener("turbo:submit-start", this.show)
    document.addEventListener("turbo:load", this.hide)
    document.addEventListener("pageshow", this.hide)
  }

  disconnect() {
    document.removeEventListener("turbo:submit-start", this.show)
    document.removeEventListener("turbo:load", this.hide)
    document.removeEventListener("pageshow", this.hide)
  }

  show() { this.overlayTarget.classList.remove("d-none") }
  hide() { this.overlayTarget.classList.add("d-none") }
}
