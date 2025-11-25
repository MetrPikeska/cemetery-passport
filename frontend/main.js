const API_URL = 'http://localhost:3000/api';

document.addEventListener('DOMContentLoaded', () => {
    // Initialize map
    const map = L.map('map').setView([49.88231, 18.20934], 16); // Centered around user-provided coordinates
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(map);

    // Fetch and visualize graves
    fetch(`${API_URL}/graves`)
        .then(response => {
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            return response.json();
        })
        .then(data => {
            const gravesLayer = L.geoJson(data, {
                onEachFeature: function (feature, layer) {
                    if (feature.properties) {
                        const props = feature.properties;
                        const popupContent = `
                            <b>Grave Number:</b> ${props.grave_number}<br>
                            <b>Section:</b> ${props.section}<br>
                            <b>Type:</b> ${props.type || 'N/A'}<br>
                            <b>Condition:</b> ${props.condition || 'N/A'}<br>
                            <a href="grave.html?id=${props.id}">View Details</a>
                        `;
                        layer.bindPopup(popupContent);

                        // Add a permanent label with the grave number
                        layer.bindTooltip(props.grave_number, { permanent: true, direction: 'center', className: 'grave-label' }).openTooltip();
                    }
                },
                style: function(feature) {
                    return {
                        fillColor: '#808080', // Grey by default
                        color: '#333',
                        weight: 1,
                        opacity: 1,
                        fillOpacity: 0.6
                    };
                }
            });

            // Add scale bar
            L.control.scale().addTo(map);

            // Add layer control
            const baseLayers = {
                "OpenStreetMap": L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                })
            };
            baseLayers["OpenStreetMap"].addTo(map); // Add default base layer

            const overlayLayers = {
                "Graves": gravesLayer
            };
            L.control.layers(baseLayers, overlayLayers).addTo(map);

            gravesLayer.addTo(map); // Add graves layer by default
        })
        .catch(error => console.error('Error fetching graves:', error));
});
