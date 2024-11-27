import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["content", "arrow"]

    toggle() {
        this.contentTarget.classList.toggle("hidden")
        this.arrowTarget.classList.toggle("rotate-180")
    }
}