import { Controller } from "@hotwired/stimulus"

// Slide-in sidebar drawer. On mobile (`< md` width), the sidebar starts
// off-screen; tapping the hamburger opens it, tapping the backdrop or
// the close button hides it again. On `md+` the drawer state is ignored
// because the sidebar is statically positioned.
export default class extends Controller {
  static targets = ["panel", "backdrop"]

  open()  { this.#set(true) }
  close() { this.#set(false) }

  #set(open) {
    this.panelTarget.classList.toggle("-translate-x-full", !open)
    this.backdropTarget.classList.toggle("hidden", !open)
    document.body.classList.toggle("overflow-hidden", open)
  }
}
