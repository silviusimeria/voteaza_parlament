import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["content", "arrow"]

    connect() {
        this.close()
    }

    toggle() {
        if (this.contentTarget.classList.contains("hidden")) {
            this.open()
        } else {
            this.close()
        }
    }

    open() {
        this.contentTarget.classList.remove("hidden")
        this.arrowTarget.classList.add("rotate-180")
    }

    close() {
        this.contentTarget.classList.add("hidden")
        this.arrowTarget.classList.remove("rotate-180")
    }
}