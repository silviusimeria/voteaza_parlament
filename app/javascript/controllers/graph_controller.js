import { Controller } from "@hotwired/stimulus"
import cytoscape from 'cytoscape'

export default class extends Controller {
  static targets = ["container"]
  static values = {
    initialData: Object,
    url: String
  }

  connect() {
    this.initializeGraph()
  }

  disconnect() {
    if (this.cy) {
      this.cy.destroy()
    }
  }

  initializeGraph() {
    const graphStyle = [
      {
        selector: 'node',
        style: {
          'label': 'data(label)',
          'text-valign': 'center',
          'color': '#000',
          'background-color': '#e5e7eb',
          'text-wrap': 'wrap',
          'text-max-width': '100px'
        }
      },
      {
        selector: 'node[?isMain]',
        style: {
          'background-color': '#3b82f6',
          'color': '#fff'
        }
      },
      {
        selector: 'edge',
        style: {
          'label': 'data(label)',
          'curve-style': 'bezier',
          'target-arrow-shape': 'triangle',
          'text-rotation': 'autorotate',
          'line-color': '#94a3b8',
          'target-arrow-color': '#94a3b8'
        }
      }
    ]

    this.cy = cytoscape({
      container: this.containerTarget,
      elements: {
        nodes: this.initialDataValue.nodes,
        edges: this.initialDataValue.edges
      },
      style: graphStyle,
      layout: {
        name: 'cose',
        padding: 50,
        animate: false
      }
    })

    // Center on the main node
    const mainNode = this.cy.$('node[?isMain]')
    if (mainNode.length > 0) {
      this.cy.center(mainNode)
      this.cy.zoom({
        level: 1,
        position: mainNode.position()
      })
    }
  }
}