import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

export default class extends Controller {
    static targets = ["map", "countyPanel"]

    connect() {
        this.initializeMap()
        this.selectedLayer = null
    }

    initializeMap() {
        this.map = L.map(this.mapTarget, {
            zoomControl: true,
            dragging: true,
            touchZoom: true,
            scrollWheelZoom: false,
            zoomSnap: 0.1,
            minZoom: 3,
            maxBoundsViscosity: 1.0,
            maxBounds: [
                [-90, -180],
                [90, 180]
            ],
            keyboard: false,
            boxZoom: false,
            doubleClickZoom: false
        }).setView([45.9432, 24.9668], 7);

        this.mapTarget.style.outline = 'none';

        const style = document.createElement('style');
        style.textContent = `
            .leaflet-container {
                outline: 0;
            }
            .leaflet-interactive {
                outline: none;
            }
        `;
        document.head.appendChild(style);

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: 'Sursă date: <a href="https://www.roaep.ro/" rel="noopener">Autoritatea Electorală Permanentă</a> | GeoJSON: <a href="https://geo-spatial.org/vechi/download/romania-seturi-vectoriale" rel="noopener">geo-spatial.org</a>`',
            maxZoom: 19
        }).addTo(this.map);

        this.loadMapData();
    }

    async loadMapData() {
        try {
            const [data, geoJson] = await Promise.all([
                fetch('/api/v1/map').then(r => r.json()),
                fetch('/ro_judete_poligon.geojson').then(r => r.json())
            ]);

            // Add this line to show Diaspora first
            const diasporaCounty = data.counties.find(c => c.code === 'D');
            if (diasporaCounty) {
                this.showCountyData(diasporaCounty);
            }

            const layer = L.geoJson(geoJson, {
                style: this.getCountyStyle,
                onEachFeature: (feature, layer) => {
                    const county = data.counties.find(c =>
                        c.code === feature.properties.mnemonic
                    );

                    if (county) {
                        this.setupCountyInteractions(county, layer);
                    }
                }
            }).addTo(this.map);

            this.map.fitBounds(layer.getBounds(), {
                padding: [20, 20]
            });
        } catch (error) {
            console.error("Error loading map data:", error);
        }
    }

    getCountyStyle() {
        return {
            weight: 1,
            opacity: 1,
            fillOpacity: 0.8,
            color: 'white',
            fillColor: '#1e40af'
        }
    }

    setupCountyInteractions(county, layer) {
        layer.on({
            mouseover: this.highlightCounty.bind(this),
            mouseout: (e) => {
                // Only reset style if this isn't the selected layer
                if (this.selectedLayer !== layer) {
                    layer.setStyle(this.getCountyStyle());
                }
            },
            click: () => {
                // Reset previous selection if exists
                if (this.selectedLayer) {
                    this.selectedLayer.setStyle(this.getCountyStyle());
                }

                // Update selected layer and its style
                this.selectedLayer = layer;
                layer.setStyle({
                    weight: 2,
                    fillOpacity: 0.9,
                    fillColor: '#3b82f6' // Different color for selected state
                });

                this.showCountyData(county);
            }
        });

        layer.bindTooltip(county.name, {
            sticky: true,
            direction: 'top'
        });
    }

    highlightCounty(e) {
        const layer = e.target;
        // Don't highlight if this is the selected layer
        if (this.selectedLayer !== layer) {
            layer.setStyle({
                weight: 2,
                fillOpacity: 0.75
            });
            layer.bringToFront();
        }
    }

    showCountyData(county) {
        if (!county) return;

        // Fetch the HTML for the county panel
        fetch(`/counties/${county.code}/panel`)
            .then(response => response.text())
            .then(html => {
                this.countyPanelTarget.innerHTML = html;
                document.getElementById('county-info').classList.remove('hidden');
            })
            .catch(error => console.error("Error loading county data:", error));
    }

    togglePartySection(event) {
        const button = event.currentTarget;
        const content = button.nextElementSibling;
        const arrow = button.querySelector('.party-arrow');

        content.classList.toggle('hidden');
        arrow.classList.toggle('rotate-180');
    }
}