import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timer = setTimeout(() => {
      location.reload()
    }, 5000)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
