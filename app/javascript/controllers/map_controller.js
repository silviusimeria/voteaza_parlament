import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

export default class extends Controller {
    static targets = ["map", "countyPanel"]

    connect() {
        this.initializeMap()
        this.selectedLayer = null
        this.countyLayers = new Map()

        // Improved URL handling for direct candidate access
        if (window.location.pathname.includes('/candidat/')) {
            const paths = window.location.pathname.split('/')
            const candidateSlug = paths[paths.length - 1]
            const partySlug = paths[paths.length - 3]
            const countySlug = paths[paths.length - 5]

            // Wait for county data to load and then handle candidate selection
            document.addEventListener('turbo:render', () => {
                // First ensure county is selected
                const county = this.counties?.find(c => c.slug === countySlug)
                if (county) {
                    const layer = this.countyLayers.get(county.slug)
                    if (layer) {
                        this.selectCounty(county, layer)
                    }
                }

                // Then setup candidate after a short delay to ensure DOM is ready
                setTimeout(() => {
                    const candidateElement = document.querySelector(`[data-candidate-slug="${candidateSlug}"]`)
                    if (candidateElement) {
                        const controller = this.application.getControllerForElementAndIdentifier(
                            candidateElement,
                            'candidate'
                        )
                        if (controller) {
                            controller.activateCandidate()
                        }
                    }
                }, 100)
            }, { once: true })
        }
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
                fetch('/data/ro_judete_poligon.geojson').then(r => r.json())
            ]);

            this.counties = data.counties;

            if (!window.location.pathname.includes('/judet/')) {
                const diasporaCounty = data.counties.find(c => c.code === 'D');
                if (diasporaCounty) {
                    this.showCountyData(diasporaCounty);
                    const url = `/judet/${diasporaCounty.slug}`;
                    window.history.pushState({}, '', url);
                }
            }

            const layer = L.geoJson(geoJson, {
                style: this.getCountyStyle,
                onEachFeature: (feature, layer) => {
                    const county = data.counties.find(c =>
                        c.code === feature.properties.mnemonic
                    );

                    if (county) {
                        this.countyLayers.set(county.slug, layer);
                        this.setupCountyInteractions(county, layer);
                    }
                }
            }).addTo(this.map);

            this.map.fitBounds(layer.getBounds(), {
                padding: [20, 20]
            });

            this.handleInitialUrl();
            window.addEventListener('popstate', () => this.handleInitialUrl());
        } catch (error) {
            console.error("Error loading map data:", error);
        }
    }

    handleInitialUrl() {
        const path = window.location.pathname;
        const countyMatch = path.match(/\/judet\/([^\/]+)/);
        if (countyMatch) {
            const countySlug = countyMatch[1];
            const county = this.counties.find(c => c.slug === countySlug);
            if (county) {
                const layer = this.countyLayers.get(county.slug);
                if (layer) {
                    if (this.selectedLayer) {
                        this.selectedLayer.setStyle(this.getCountyStyle());
                    }
                    this.selectedLayer = layer;
                    layer.setStyle({
                        weight: 2,
                        fillOpacity: 0.9,
                        fillColor: '#3b82f6'
                    });
                    this.showCountyData(county);
                }
            }
        }
    }

    updateUrl(county) {
        const url = `/judet/${county.slug}`;
        window.history.pushState({}, '', url);
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

    selectCounty(county, layer) {
        if (this.selectedLayer) {
            this.selectedLayer.setStyle(this.getCountyStyle());
        }

        this.selectedLayer = layer;
        layer.setStyle({
            weight: 2,
            fillOpacity: 0.9,
            fillColor: '#3b82f6'
        });

        const url = `/judet/${county.slug}`;
        window.history.pushState({}, '', url);
        this.showCountyData(county);
    }

    setupCountyInteractions(county, layer) {
        layer.on({
            mouseover: this.highlightCounty.bind(this),
            mouseout: (e) => {
                if (this.selectedLayer !== layer) {
                    layer.setStyle(this.getCountyStyle());
                }
            },
            click: () => this.selectCounty(county, layer)
        });

        layer.bindTooltip(county.name, {
            permanent: true,
            direction: 'center',
            className: 'county-label',
            offset: [0, 0]
        });
    }

    showCountyData(county) {
        if (!county) return;

        // Don't fetch if we're already on a more specific URL
        const currentPath = window.location.pathname;
        if ((currentPath.includes('/partid/') || currentPath.includes('/candidat/')) &&
            currentPath.includes(`/judet/${county.slug}`)) {
            return;
        }

        fetch(`/judet/${county.slug}`, {
            headers: {
                'Accept': 'text/vnd.turbo-stream.html'
            }
        })
            .then(response => response.text())
            .then(html => {
                Turbo.renderStreamMessage(html)
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