// import { Controller } from "@hotwired/stimulus"
//
// export default class extends Controller {
//     static values = {
//         partySlug: String,
//         candidateSlug: String
//     }
//
//     connect() {
//         const path = window.location.pathname
//         if (path.includes('/candidat/')) {
//             // Only activate full UI if coming from initial page load or search
//             if (document.referrer === '' || path !== window.location.pathname) {
//                 this.activateCandidate()
//             }
//         }
//     }
//
//     select(event) {
//         event.preventDefault()
//         const url = event.currentTarget.getAttribute('href')
//
//         // Just update URL and show popup when clicking candidate
//         window.history.pushState({}, '', url)
//         this.showCandidatePopup()
//     }
//
//     activateCandidate() {
//         this.scrollToPartyAndOpenDropdown()
//         this.highlightSelectedCandidate()
//         this.showCandidatePopup()
//     }
//
//     showCandidatePopup() {
//         // First fetch the popup content if needed
//         fetch(window.location.pathname, {
//             headers: {
//                 'Accept': 'text/vnd.turbo-stream.html'
//             }
//         })
//             .then(response => response.text())
//             .then(html => {
//                 const popup = document.getElementById('candidate-popup')
//                 if (popup && popup.classList.contains('hidden')) {
//                     Turbo.renderStreamMessage(html)
//                     popup.classList.remove('hidden')
//                     document.body.classList.add('overflow-hidden')
//                 }
//             })
//     }
//
//
//     scrollToPartyAndOpenDropdown() {
//         console.log("=== Panel Operation Start ===")
//         console.log("Looking for party section:", this.partySlugValue)
//
//         const partySection = document.querySelector(`[data-party-slug="${this.partySlugValue}"]`)
//         console.log("Found party section:", !!partySection)
//
//         if (partySection) {
//             const dropdownController = this.application.getControllerForElementAndIdentifier(
//                 partySection,
//                 'dropdown'
//             )
//             console.log("Found dropdown controller:", !!dropdownController)
//
//             if (dropdownController) {
//                 console.log("Opening dropdown")
//                 dropdownController.open()
//                 console.log("Dropdown opened")
//             }
//         }
//     }
//
//     highlightSelectedCandidate() {
//         // Clear existing highlights
//         document.querySelectorAll('[data-candidate-slug]').forEach(el => {
//             el.classList.remove('bg-blue-50')
//         })
//
//         // Add new highlight
//         const candidateElement = document.querySelector(`[data-candidate-slug="${this.candidateSlugValue}"]`)
//         if (candidateElement) {
//             candidateElement.classList.add('bg-blue-50')
//         }
//     }
// }