import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["content", "arrow"]

    connect() {
        // Initialize in a closed state
        this.close()
    }

    toggle() {
        if (this.contentTarget.style.display === "none" || this.contentTarget.style.display === "") {
            this.open()
        } else {
            this.close()
        }
    }

    open() {
        this.contentTarget.style.display = "block"
        this.arrowTarget.classList.add("rotate-180")
    }

    close() {
        this.contentTarget.style.display = "none"
        this.arrowTarget.classList.remove("rotate-180")
    }
}