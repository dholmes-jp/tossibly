import { Controller } from "@hotwired/stimulus"

// Drives the "Compare your options" tabs on the item decision (show) page.
// Each .btn-platform button carries data-item-decision-tab-param; clicking one
// expands the matching full-width panel below .decision-card, highlights its
// .action-path card, and scrolls the panel into view. Clicking the same button
// again (or a .detail-close control) collapses it.
export default class extends Controller {
  static targets = ["wrap", "panel", "card"]

  connect() {
    this.openTab = null
  }

  select(event) {
    const tab = event.params.tab

    if (this.openTab === tab) {
      this.close()
      return
    }

    const wasOpen = this.openTab !== null
    this.openTab = tab

    this.panelTargets.forEach((panel) => {
      panel.hidden = panel.dataset.tab !== tab
    })

    this.cardTargets.forEach((card) => {
      card.classList.toggle("is-active", card.dataset.tab === tab)
    })

    this.wrapTarget.classList.add("is-open")
    this.scrollToPanel(wasOpen)
  }

  // Bring the panel into view. When opening from a fully-closed state the wrap
  // animates its height up from zero, so scrolling immediately would just target
  // a zero-height sliver near the bottom of the page. Wait for the expand
  // transition to finish first (with a timeout fallback). When a panel is
  // already open, or motion is reduced, scroll right away.
  scrollToPanel(wasOpen) {
    const behavior = this.scrollBehavior

    if (wasOpen || behavior === "auto") {
      this.wrapTarget.scrollIntoView({ behavior, block: "start" })
      return
    }

    let done = false
    const scroll = () => {
      if (done) return
      done = true
      this.wrapTarget.removeEventListener("transitionend", onEnd)
      this.wrapTarget.scrollIntoView({ behavior, block: "start" })
    }
    const onEnd = (event) => {
      if (event.target === this.wrapTarget && event.propertyName === "grid-template-rows") scroll()
    }

    this.wrapTarget.addEventListener("transitionend", onEnd)
    setTimeout(scroll, 450)
  }

  close() {
    this.openTab = null
    this.wrapTarget.classList.remove("is-open")
    this.cardTargets.forEach((card) => card.classList.remove("is-active"))
  }

  get scrollBehavior() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth"
  }
}
