import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    close() {
        this.element.closest('[data-turbo-frame]').src = ''
    }
}