import { Controller } from "@hotwired/stimulus"

// Toggles the `hidden` class on the element whose id is passed as a param,
// or on any descendant registered with data-toggle-target="panel".
export default class extends Controller {
  static targets = ["panel"]

  toggle(event) {
    const targetId = event.params.target
    if (targetId) {
      const el = document.getElementById(targetId)
      if (el) el.classList.toggle("hidden")
      return
    }
    this.panelTargets.forEach(p => p.classList.toggle("hidden"))
  }
}
