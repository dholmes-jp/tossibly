import { Controller } from "@hotwired/stimulus"

// Generic show/hide toggle for a trigger + panel pair — e.g. the
// "+ Add schedule" button that reveals the schedule form on the calendar
// page. The panel starts hidden/shown based on whatever `hidden` attribute
// the server rendered (open if the form has errors to show), and toggling
// just flips it from there.
export default class extends Controller {
  static targets = ["panel"]

  toggle() {
    this.panelTarget.hidden = !this.panelTarget.hidden
  }
}
