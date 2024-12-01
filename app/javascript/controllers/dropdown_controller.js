import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["content", "arrow"]

    connect() {
        // Check URL for active party
        const path = window.location.pathname
        const matches = path.match(/\/partid\/([^\/]+)/)
        const activePartySlug = matches ? matches[1] : null

        // If this is the active party's dropdown, open it
        if (activePartySlug && this.element.dataset.partySlug === activePartySlug) {
            this.open()
        } else {
            this.close()
        }
    }


    toggle() {
        if (this.contentTarget.classList.contains("hidden")) {
            this.open()
        } else {
            this.close()
        }
    }

    open() {
        // Close all other dropdowns first
        document.querySelectorAll('[data-controller="dropdown"]').forEach(dropdown => {
            if (dropdown !== this.element) {
                const controller = this.application.getControllerForElementAndIdentifier(dropdown, 'dropdown')
                if (controller) {
                    controller.close()
                }
            }
        })

        this.contentTarget.classList.remove("hidden")
        this.arrowTarget.classList.add("rotate-180")
    }

    close() {
        this.contentTarget.classList.add("hidden")
        this.arrowTarget.classList.remove("rotate-180")
    }
}