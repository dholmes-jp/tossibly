import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["followups", "listableField"]

  show() {
    this.followupsTarget.classList.remove("d-none")
    this.followupsTarget.scrollIntoView({ behavior: "smooth", block: "start" })
  }

  // The "Set Reminder" bypass button submits the form as-is; flip the hidden
  // listable field to false first so the item is saved for disposal, not listing.
  skipToReminder() {
    if (this.hasListableFieldTarget) this.listableFieldTarget.value = "false"
  }
}
