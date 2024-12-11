import { Controller } from "@hotwired/stimulus"
import * as d3 from "d3"

export default class extends Controller {
    static targets = [
        "seatsContainer",
        "selectedSeatInfo",
        "selectedSeatDetails",
        "tooltipName",
        "tooltipParty",
        "tooltipCounty",
        "container"
    ]
    static values = { seats: Array, chamber: String }

    partyColors = {
        'PARTIDUL SOCIAL DEMOCRAT': '#ff0000',
        'PARTIDUL NAȚIONAL LIBERAL': '#f4d03f',
        'UNIUNEA SALVAȚI ROMÂNIA': '#21618c',
        'ALIANȚA PENTRU UNIREA ROMÂNILOR': '#ffea00',
        'PARTIDUL S.O.S. ROMÂNIA': '#1d22bf',
        'UNIUNEA DEMOCRATĂ MAGHIARĂ DIN ROMÂNIA': '#27ae60',
        'PARTIDUL OAMENILOR TINERI': '#e67e22'
    }

    connect() {
        console.log("Seats:", this.seatsValue)
        this.initializeHemicycle()
    }

    initializeHemicycle() {
        const config = this.getConfiguration()

        // Clear any existing content
        this.seatsContainerTarget.innerHTML = ''

        // Calculate seat positions
        const totalSeats = this.seatsValue.length
        console.log("Total seats:", totalSeats)

        const positions = this.calculateSeatPositionsCool(config, totalSeats)
        console.log("Calculated positions:", positions)

        // Group seats by party for proper ordering
        const groupedSeats = this.groupSeatsByParty()
        console.log("Grouped seats:", groupedSeats)

        // Create seats
        this.createSeats(groupedSeats, positions, config)
    }

    getConfiguration() {
        const isSenate = this.chamberValue === 'senate'
        const totalSeats = this.seatsValue.length

        return {
            width: 1000,
            height: 400,
            centerX: 500,
            centerY: 450, // Moved down to make room for upward orientation
            rows: isSenate ? 15 : 23,
            innerRadius: isSenate ? 250 : 250,
            radiusIncrement: isSenate ? 35 : 30,
            startAngle: Math.PI,  // Changed angles for upward orientation
            endAngle: Math.PI * 2,    // Changed angles for upward orientation
            iconSize: isSenate ? 25 : 20,
            seatsPerRow: Math.ceil(totalSeats / (isSenate ? 8 : 12))
        }
    }

    calculateSeatPositionsCool(config, totalSeats) {
        const positions = []
        const rows = config.rows
        const partyGroups = this.getPartyGroups()
        const sortedParties = Object.entries(partyGroups)
            .sort(([, a], [, b]) => b.length - a.length)

        // Calculate seats per row for even distribution
        const seatsPerRow = Array(rows).fill(0).map((_, i) => {
            const rowRadius = config.innerRadius + (i * config.radiusIncrement)
            const rowCircumference = rowRadius * (config.endAngle - config.startAngle)
            return Math.floor(rowCircumference / (config.iconSize * 1.2))
        })

        // Calculate total seats available
        const totalAvailableSeats = seatsPerRow.reduce((a, b) => a + b, 0)

        // Distribute seats by party
        let currentSeatIndex = 0
        sortedParties.forEach(([partyName, partySeats]) => {
            const partySize = partySeats.length
            const partySeatIndices = []

            // Calculate seat indices for this party
            for (let i = 0; i < partySize; i++) {
                partySeatIndices.push((currentSeatIndex + i) % totalAvailableSeats)
            }
            currentSeatIndex += partySize

            // Place seats
            partySeatIndices.forEach(seatIndex => {
                // Find which row this seat belongs to
                let rowIndex = 0
                let seatInRow = seatIndex
                while (seatInRow >= seatsPerRow[rowIndex]) {
                    seatInRow -= seatsPerRow[rowIndex]
                    rowIndex++
                }

                const radius = config.innerRadius + (rowIndex * config.radiusIncrement)
                const angle = config.startAngle +
                    (seatInRow / (seatsPerRow[rowIndex] - 1)) *
                    (config.endAngle - config.startAngle)

                positions.push({
                    x: config.centerX + radius * Math.cos(angle),
                    y: config.centerY + radius * Math.sin(angle),
                    angle: (angle * 180 / Math.PI) + 90,
                    partyName: partyName
                })
            })
        })

        return positions
    }

    calculateSeatPositions(config, totalSeats) {
        const positions = []
        const partyGroups = this.getPartyGroups()
        const sortedParties = Object.entries(partyGroups)
            .sort(([, a], [, b]) => b.length - a.length)

        // Calculate total arc length
        const arcLength = config.endAngle - config.startAngle
        let currentAngle = config.startAngle

        // For each party, allocate a section of the arc proportional to their seats
        sortedParties.forEach(([partyName, partySeats]) => {
            const partyArcLength = arcLength * (partySeats.length / totalSeats)
            let partySeatsAllocated = 0

            // Distribute party's seats across rows
            for (let row = 0; row < config.rows && partySeatsAllocated < partySeats.length; row++) {
                const radius = config.innerRadius + (row * config.radiusIncrement)

                // Calculate how many seats we can fit in this row for this party
                const seatsInThisRow = Math.min(
                    Math.ceil(partySeats.length / config.rows),
                    partySeats.length - partySeatsAllocated
                )

                // Place seats in this row
                for (let seat = 0; seat < seatsInThisRow; seat++) {
                    const seatAngle = currentAngle + (seat / seatsInThisRow) * partyArcLength

                    positions.push({
                        x: config.centerX + radius * Math.cos(seatAngle),
                        y: config.centerY + radius * Math.sin(seatAngle),
                        angle: (seatAngle * 180 / Math.PI) + 90,
                        partyName: partyName
                    })
                    partySeatsAllocated++
                }
            }

            // Move the current angle forward for the next party
            currentAngle += partyArcLength
        })

        return positions
    }

    getPartyGroups() {
        const groups = {}
        this.seatsValue.forEach(seat => {
            if (!groups[seat.party_name]) {
                groups[seat.party_name] = []
            }
            groups[seat.party_name].push(seat)
        })
        return groups
    }

    calculateHorizontalSeatPositions(config, totalSeats) {
        const positions = []

        // Calculate total arc length and spacing
        const arcLength = config.endAngle - config.startAngle

        // Calculate seats per row - more seats in outer rows
        let seatsAllocated = 0
        for (let row = 0; row < config.rows && seatsAllocated < totalSeats; row++) {
            const radius = config.innerRadius + (row * config.radiusIncrement)
            const circumference = 2 * Math.PI * radius
            const rowArcLength = arcLength * radius

            // More seats in outer rows
            const rowSeats = Math.min(
                Math.floor(rowArcLength / (config.iconSize * 1.5)),
                totalSeats - seatsAllocated
            )

            // Calculate positions for this row
            for (let seat = 0; seat < rowSeats; seat++) {
                const angle = config.startAngle + (seat / (rowSeats - 1 || 1)) * arcLength
                positions.push({
                    x: config.centerX + radius * Math.cos(angle),
                    y: config.centerY + radius * Math.sin(angle),
                    angle: (angle * 180 / Math.PI) + 90 // Adjusted rotation for upward orientation
                })
            }

            seatsAllocated += rowSeats
        }

        return positions
    }

    groupSeatsByParty() {
        // Create a map of parties and their seats
        const partyGroups = {}
        this.seatsValue.forEach(seat => {
            if (!partyGroups[seat.party_name]) {
                partyGroups[seat.party_name] = []
            }
            partyGroups[seat.party_name].push(seat)
        })

        // Sort parties by number of seats (descending)
        return Object.entries(partyGroups)
            .sort(([, a], [, b]) => b.length - a.length)
            .flatMap(([, seats]) => seats)
    }

    createSeats(seats, positions, config) {
        if (!seats.length || !positions.length) {
            console.error("No seats or positions to render")
            return
        }

        const validPositions = positions.slice(0, seats.length)
        const svg = d3.select(this.seatsContainerTarget)

        svg.selectAll(".seat")
            .data(seats)
            .join("text")
            .attr("class", "seat transition-all duration-200 ease-in-out hover:opacity-75")
            .style("cursor", "pointer")
            .attr("font-family", "FontAwesome")
            .attr("font-size", config.iconSize)
            .attr("fill", d => d.party_color || this.partyColors[d.party_name] || "#999")
            .attr("text-anchor", "middle")
            .attr("dominant-baseline", "middle")
            .attr("x", (d, i) => validPositions[i]?.x || 0)
            .attr("y", (d, i) => validPositions[i]?.y || 0)
            .attr("transform", (d, i) => {
                const pos = validPositions[i]
                return pos ? `rotate(${pos.angle},${pos.x},${pos.y})` : ''
            })
            .text("\uf007")
            .on("mouseover", (event, d) => this.showSeatInfo(event, d))
            .on("mouseout", () => this.hideSeatInfo())
            .on("click", (event, d) => this.handleSeatClick(d))
    }

    showSeatInfo(event, seat) {
        this.selectedSeatInfoTarget.classList.add('hidden')
        this.selectedSeatDetailsTarget.classList.remove('hidden')
        this.tooltipNameTarget.textContent = seat.name
        this.tooltipPartyTarget.textContent = seat.party_name
        this.tooltipCountyTarget.textContent = seat.county_name

        // Optional: Highlight the selected seat
        event.target.setAttribute("opacity", "0.75")
    }

    hideSeatInfo() {
        // Don't hide immediately to allow for clicking
        // this.selectedSeatInfoTarget.classList.remove('hidden')
        // this.selectedSeatDetailsTarget.classList.add('hidden')

        // Remove any highlight
        d3.selectAll(".seat").attr("opacity", "1")
    }

    handleSeatClick(seat) {
        if (seat.slug) {
            window.location.href = `/persoana/${seat.slug}`
        }
    }

    showTooltip(event, seat) {
        const tooltip = this.tooltipTarget
        const bounds = event.target.getBoundingClientRect()
        const containerBounds = this.containerTarget.getBoundingClientRect()

        this.tooltipNameTarget.textContent = seat.name
        this.tooltipPartyTarget.textContent = seat.party_name
        this.tooltipCountyTarget.textContent = seat.county_name

        const tooltipX = bounds.x - containerBounds.x
        const tooltipY = bounds.y - containerBounds.y - bounds.height

        tooltip.style.left = `${tooltipX}px`
        tooltip.style.top = `${tooltipY}px`
        tooltip.classList.remove("hidden")
    }

    hideTooltip() {
        this.tooltipTarget.classList.add("hidden")
    }

}