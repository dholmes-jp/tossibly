import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["paths", "viewButton"]

  expandJimoty() { this.setState("jimoty") }

  expandDispose() { this.setState("dispose") }

  showBoth() { this.setState("both") }

  setState(state) {
    if (!this.hasPathsTarget) return

    this.pathsTarget.dataset.state = state

    this.viewButtonTargets.forEach((button) => {
      const on = button.dataset.state === state
      button.classList.toggle("is-on", on)
      button.setAttribute("aria-pressed", on ? "true" : "false")
    })
  }
}
