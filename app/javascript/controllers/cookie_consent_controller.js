import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["banner"]

    initialize() {
        // Set default state for banner
        this.bannerTarget.classList.add('hidden')
    }

    connect() {
        // Check if we already have consent
        const hasConsent = localStorage.getItem('cookieConsent')

        if (!hasConsent) {
            // Only show if we don't have consent
            this.bannerTarget.classList.remove('hidden')
        }
    }

    accept(event) {
        event.preventDefault()

        // Save the consent with a timestamp
        localStorage.setItem('cookieConsent', new Date().toISOString())

        // Hide the banner
        this.bannerTarget.classList.add('hidden')
    }
}