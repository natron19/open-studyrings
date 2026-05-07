import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timer = setTimeout(() => {
      location.reload()
    }, 3000)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
