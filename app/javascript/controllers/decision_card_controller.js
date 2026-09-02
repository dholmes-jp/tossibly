import { Controller } from "@hotwired/stimulus"

// Item decision page: "More details" panels and the "Edit draft" dialog.
// Usage: data-controller="decision-card" on the card wrapper.
//   data-action="decision-card#toggle" data-decision-card-panel-param="list"
//   data-decision-card-target="panel" data-panel="list"
//   data-decision-card-target="dialog" on the <dialog>
export default class extends Controller {
  static targets = ["panel", "dialog"]

  toggle(event) {
    const name = event.params.panel
    const panel = this.panelTargets.find((p) => p.dataset.panel === name)
    if (!panel) return

    panel.hidden = !panel.hidden

    // Update every button that toggles this panel ("More details" <-> "Hide details")
    this.element
      .querySelectorAll(`[data-decision-card-panel-param="${name}"]`)
      .forEach((button) => {
        if (button.classList.contains("decide-btn--secondary")) {
          button.textContent = panel.hidden ? "More details" : "Hide details"
        }
      })
  }

  // "Choose X": make sure that card's details are open and in view.
  // (Card colours follow the suggestion, not the choice — see _decision.scss.)
  choose(event) {
    const name = event.params.panel
    const panel = this.panelTargets.find((p) => p.dataset.panel === name)
    if (!panel) return

    if (panel.hidden) this.toggle(event)
    panel.scrollIntoView({ behavior: "smooth", block: "nearest" })
  }

  openEditor() {
    if (this.hasDialogTarget) this.dialogTarget.showModal()
  }

  closeEditor() {
    if (this.hasDialogTarget) this.dialogTarget.close()
  }

  // Click on the dimmed backdrop closes the dialog
  backdrop(event) {
    if (event.target === this.dialogTarget) this.closeEditor()
  }
}
