import { Controller } from "@hotwired/stimulus"

// Attached to a <form>. On each `input->autosave#save`, debounces and
// submits the form via Turbo (so the server-side turbo_stream response
// applies without a full-page reload).
export default class extends Controller {
  static values = { delay: { type: Number, default: 300 } }

  disconnect() { clearTimeout(this.timer) }

  save() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.element.requestSubmit(), this.delayValue)
  }
}
