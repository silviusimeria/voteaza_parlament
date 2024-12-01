// app/javascript/controllers/search_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["input", "results"]

    connect() {
        this.timeout = null
    }

    handleKeydown(event) {
        if (event.key === "Escape") {
            this.hideResults()
        }
    }

    search() {
        clearTimeout(this.timeout)
        const query = this.inputTarget.value.trim()

        if (query.length < 2) {
            this.hideResults()
            return
        }

        this.timeout = setTimeout(() => this.performSearch(query), 300)
    }


    async performSearch(query) {
        try {
            const response = await fetch(`/api/v1/search?q=${encodeURIComponent(query)}`, {
                headers: { "Accept": "text/html" }
            })

            if (response.ok) {
                this.resultsTarget.innerHTML = await response.text()
                this.showResults()
            }
        } catch (error) {
            console.error("Search failed:", error)
        }
    }

    selectResult(event) {
        event.preventDefault()
        const url = event.currentTarget.getAttribute('href')

        // Update URL
        window.history.pushState({}, '', url)

        // Fetch using Turbo
        fetch(url, {
            headers: {
                'Accept': 'text/vnd.turbo-stream.html'
            }
        })
            .then(response => response.text())
            .then(html => {
                Turbo.renderStreamMessage(html)
                // After Turbo renders, activate the candidate UI
                requestAnimationFrame(() => {
                    const candidateElement = document.querySelector(
                        `[data-candidate-slug="${event.currentTarget.dataset.candidateSlug}"]`
                    )
                    if (candidateElement) {
                        const controller = this.application.getControllerForElementAndIdentifier(
                            candidateElement,
                            'candidate'
                        )
                        if (controller) {
                            controller.activateCandidate()
                        }
                    }
                })
            })
            .catch(error => console.error('Error:', error))
    }

    showResults() {
        this.resultsTarget.classList.remove("hidden")
    }

    hideResults() {
        this.resultsTarget.classList.add("hidden")
    }
}