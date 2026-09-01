import { Controller } from "@hotwired/stimulus"

// Skip-case scan result ("Nothing to decide here"). "Set Reminder" is a pure
// placeholder for this pass — no route, no model, no network — so it just drops
// an inline note. It'll be wired up once a real reminders system exists.
export default class extends Controller {
  static targets = ["toast"]

  setReminder() {
    this.toastTarget.textContent = "**Reminders are not built yet. This button is a placeholder for now.**"
  }
}
