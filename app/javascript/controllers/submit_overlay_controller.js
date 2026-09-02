import { Controller } from "@hotwired/stimulus"

// Full-screen "checking the best way forward" overlay shown while the
// "Save to Items" form submits. turbo:submit-start fires only for real form
// submissions Turbo Drive intercepts, so the identify step's manual fetch()
// never triggers it. items#create's success path is now a turbo_stream response
// (no navigation — the URL stays /items/new), so turbo:load never fires after a
// successful save; turbo:submit-end fires after both success and failure, right
// as the response has been processed, and is the correct moment to drop the
// overlay either way. turbo:load still clears it on the validation-failure path
// (render :new is a real HTML render); pageshow covers the bfcache back-button
// case so the spinner is never left stuck.
export default class extends Controller {
  static targets = ["overlay"]

  connect() {
    this.show = this.show.bind(this)
    this.hide = this.hide.bind(this)
    document.addEventListener("turbo:submit-start", this.show)
    document.addEventListener("turbo:submit-end", this.hide)
    document.addEventListener("turbo:load", this.hide)
    document.addEventListener("pageshow", this.hide)
  }

  disconnect() {
    document.removeEventListener("turbo:submit-start", this.show)
    document.removeEventListener("turbo:submit-end", this.hide)
    document.removeEventListener("turbo:load", this.hide)
    document.removeEventListener("pageshow", this.hide)
  }

  // Wired to the Set Reminder buttons: those are fast, no-AI disposal saves, so
  // the "checking the best way forward" copy is misleading for them. Runs on
  // click, before the native submit and turbo:submit-start, so the next show()
  // no-ops itself once.
  skip() { this.suppressNext = true }

  show() {
    if (this.suppressNext) {
      this.suppressNext = false
      return
    }
    this.overlayTarget.classList.remove("d-none")
  }

  hide() { this.overlayTarget.classList.add("d-none") }
}
