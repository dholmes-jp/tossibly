import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["description", "form"]

  edit() {
    this.descriptionTarget.hidden = true
    this.formTarget.hidden = false
  }
}
