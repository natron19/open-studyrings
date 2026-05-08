import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "loading"]
  static values = { ringPath: String }

  start() {
    this.formTarget.hidden = true
    this.loadingTarget.hidden = false
  }

  cancel() {
    Turbo.visit(this.ringPathValue)
  }
}
