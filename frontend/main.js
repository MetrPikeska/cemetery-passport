const API_URL = 'http://localhost:3000/api';

document.addEventListener('DOMContentLoaded', () => {
    const map = L.map('map').setView([49.88231, 18.20934], 16);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(map);

    let gravesLayer; // Keep a reference to the graves layer
    const sectionsDatalist = document.getElementById('sections-list');
    const geojsonDropArea = document.getElementById('geojson-drop-area');
    const geojsonFileInput = document.getElementById('geojson-file-input');

    // Function to fetch and visualize graves
    async function fetchAndVisualizeGraves() {
        try {
            const response = await fetch(`${API_URL}/graves`);
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            const data = await response.json();

            // Clear existing graves layer if it exists
            if (gravesLayer) {
                map.removeLayer(gravesLayer);
            }

            gravesLayer = L.geoJson(data, {
                onEachFeature: function (feature, layer) {
                    if (feature.properties) {
                        const props = feature.properties;
                        const popupContent = `
                            <b>Číslo Hrobu:</b> ${props.grave_number}<br>
                            <b>Sekce:</b> ${props.section}<br>
                            <b>Typ:</b> ${props.type || 'N/A'}<br>
                            <b>Stav:</b> ${props.condition || 'N/A'}<br>
                            <a href="grave.html?id=${props.id}">Zobrazit Detaily</a>
                        `;
                        layer.bindPopup(popupContent);
                        layer.bindTooltip(props.grave_number, { permanent: true, direction: 'center', className: 'grave-label' }).openTooltip();
                    }
                },
                style: function(feature) {
                    return {
                        fillColor: '#808080',
                        color: '#333',
                        weight: 1,
                        opacity: 1,
                        fillOpacity: 0.6
                    };
                }
            });
            gravesLayer.addTo(map);
            updateGravesList(data.features); // Update the list of graves
        } catch (error) {
            console.error('Error fetching graves:', error);
        }
    }

    // Function to fetch and populate section datalist
    async function fetchAndPopulateSections() {
        try {
            const response = await fetch(`${API_URL}/graves/sections`);
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            const sections = await response.json();
            sectionsDatalist.innerHTML = ''; // Clear existing options
            sections.forEach(section => {
                const option = document.createElement('option');
                option.value = section;
                sectionsDatalist.appendChild(option);
            });
        } catch (error) {
            console.error('Error fetching sections:', error);
        }
    }

    // Initial fetch and visualization
    fetchAndVisualizeGraves();
    fetchAndPopulateSections();

    // Add scale bar
    L.control.scale().addTo(map);

    // Add layer control (can be improved later if more layers are added)
    const baseLayers = {
        "OpenStreetMap": L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        })
    };
    L.control.layers(baseLayers, {}).addTo(map); // No overlay layers initially in control

    // Handle form visibility toggle
    const toggleFormsBtn = document.getElementById('toggle-forms-btn');
    const formsContainer = document.getElementById('forms-container');
    toggleFormsBtn.addEventListener('click', () => {
        const isHidden = formsContainer.style.display === 'none';
        formsContainer.style.display = isHidden ? 'block' : 'none';
        if (!isHidden) { // If closing, clear any edit forms
            const editForm = document.getElementById('edit-grave-form');
            if (editForm) editForm.remove();
        }
    });

    // Handle Add Grave Form Submission
    const addGraveForm = document.getElementById('add-grave-form');
    addGraveForm.addEventListener('submit', async (event) => {
        event.preventDefault();

        const section = document.getElementById('section').value;
        const grave_number = document.getElementById('grave_number').value;
        const type = document.getElementById('type').value;
        const condition = document.getElementById('condition').value;
        const latitude = parseFloat(document.getElementById('latitude').value);
        const longitude = parseFloat(document.getElementById('longitude').value);

        if (isNaN(latitude) || isNaN(longitude)) {
            alert('Latitude and Longitude must be valid numbers.');
            return;
        }

        const newGrave = {
            section,
            grave_number,
            type,
            condition,
            geom: {
                type: 'Point',
                coordinates: [longitude, latitude] // GeoJSON coordinates are [longitude, latitude]
            }
        };

        try {
            const response = await fetch(`${API_URL}/graves`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(newGrave)
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(`HTTP error! status: ${response.status}, message: ${errorData.error}`);
            }

            alert('Hrob úspěšně přidán!');
            addGraveForm.reset();
            fetchAndVisualizeGraves(); // Refresh map and list
        } catch (error) {
            console.error('Error adding grave:', error);
            alert(`Chyba při přidávání hrobu: ${error.message}`);
        }
    });

    // --- GeoJSON Drag & Drop / File Input Handler ---
    ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
        geojsonDropArea.addEventListener(eventName, preventDefaults, false);
        document.body.addEventListener(eventName, preventDefaults, false); // Prevent default for the whole document
    });

    ['dragenter', 'dragover'].forEach(eventName => {
        geojsonDropArea.addEventListener(eventName, () => geojsonDropArea.classList.add('highlight'), false);
    });

    ['dragleave', 'drop'].forEach(eventName => {
        geojsonDropArea.addEventListener(eventName, () => geojsonDropArea.classList.remove('highlight'), false);
    });

    geojsonDropArea.addEventListener('drop', handleDrop, false);
    geojsonFileInput.addEventListener('change', handleFileSelect, false);

    function preventDefaults(e) {
        e.preventDefault();
        e.stopPropagation();
    }

    function handleFileSelect(e) {
        const files = e.target.files;
        if (files.length > 0) {
            handleFiles(files);
        }
    }

    function handleDrop(e) {
        const dt = e.dataTransfer;
        const files = dt.files;
        handleFiles(files);
    }

    function handleFiles(files) {
        if (files.length === 0) {
            alert('Žádný soubor nebyl vybrán nebo přetažen.');
            return;
        }
        const file = files[0];
        const reader = new FileReader();
        reader.onload = function(event) {
            try {
                const geojson = JSON.parse(event.target.result);
                populateFormWithGeoJSON(geojson);
            } catch (e) {
                alert('Chyba při čtení GeoJSON souboru: ' + e.message);
                console.error('Error parsing GeoJSON:', e);
            }
        };
        reader.readAsText(file);
    }

    function populateFormWithGeoJSON(geojson) {
        if (geojson.type === 'Feature' && geojson.geometry && geojson.geometry.type === 'Point' && geojson.geometry.coordinates) {
            document.getElementById('latitude').value = geojson.geometry.coordinates[1];
            document.getElementById('longitude').value = geojson.geometry.coordinates[0];
            if (geojson.properties) {
                document.getElementById('section').value = geojson.properties.section || '';
                document.getElementById('grave_number').value = geojson.properties.grave_number || '';
                document.getElementById('type').value = geojson.properties.type || '';
                document.getElementById('condition').value = geojson.properties.condition || '';
            }
            alert('GeoJSON data úspěšně načtena do formuláře!');
        } else if (geojson.type === 'FeatureCollection' && geojson.features && geojson.features.length > 0) {
            // If it's a FeatureCollection, take the first Feature as an example
            populateFormWithGeoJSON(geojson.features[0]);
        }
        else {
            alert('Soubor GeoJSON neobsahuje platnou geometrii bodu nebo kolekci prvků s body.');
        }
    }

    // Function to update the list of graves for editing/deleting
    function updateGravesList(graves) {
        const gravesList = document.getElementById('graves-list');
        gravesList.innerHTML = ''; // Clear existing list

        graves.forEach(grave => {
            const listItem = document.createElement('li');
            listItem.innerHTML = `
                ${grave.properties.grave_number} (Sekce: ${grave.properties.section})
                <button class="edit-btn" data-id="${grave.properties.id}">Upravit</button>
                <button class="delete-btn" data-id="${grave.properties.id}">Smazat</button>
            `;
            gravesList.appendChild(listItem);
        });

        // Add event listeners for edit and delete buttons
        gravesList.querySelectorAll('.edit-btn').forEach(button => {
            button.addEventListener('click', (event) => {
                const graveId = event.target.dataset.id;
                renderEditForm(graveId);
            });
        });

        gravesList.querySelectorAll('.delete-btn').forEach(button => {
            button.addEventListener('click', (event) => {
                const graveId = event.target.dataset.id;
                if (confirm('Opravdu chcete smazat tento hrob?')) {
                    deleteGrave(graveId);
                }
            });
        });
    }

    // Function to render the edit form
    async function renderEditForm(graveId) {
        const existingForm = document.getElementById('edit-grave-form');
        if (existingForm) {
            existingForm.remove(); // Remove any existing edit form
        }

        try {
            const response = await fetch(`${API_URL}/graves/${graveId}`);
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            const grave = await response.json();

            const formsContainer = document.getElementById('forms-container');
            const editForm = document.createElement('form');
            editForm.id = 'edit-grave-form';
            editForm.innerHTML = `
                <h2>Upravit Hrob (ID: ${grave.id})</h2>
                <label for="edit_section">Sekce:</label>
                <input type="text" id="edit_section" name="section" value="${grave.section}" required><br>
                <label for="edit_grave_number">Číslo Hrobu:</label>
                <input type="text" id="edit_grave_number" name="grave_number" value="${grave.grave_number}" required><br>
                <label for="edit_type">Typ:</label>
                <input type="text" id="edit_type" name="type" value="${grave.type || ''}"><br>
                <label for="edit_condition">Stav:</label>
                <input type="text" id="edit_condition" name="condition" value="${grave.condition || ''}"><br>
                <label for="edit_latitude">Latitude:</label>
                <input type="number" id="edit_latitude" name="latitude" step="any" value="${grave.geometry.coordinates[1]}" required><br>
                <label for="edit_longitude">Longitude:</label>
                <input type="number" id="edit_longitude" name="longitude" step="any" value="${grave.geometry.coordinates[0]}" required><br>
                <button type="submit">Uložit Změny</button>
                <button type="button" id="cancel-edit-btn">Zrušit</button>
            `;
            formsContainer.appendChild(editForm);

            // Scroll to the edit form
            editForm.scrollIntoView({ behavior: 'smooth' });

            editForm.addEventListener('submit', async (event) => {
                event.preventDefault();

                const updatedGrave = {
                    section: document.getElementById('edit_section').value,
                    grave_number: document.getElementById('edit_grave_number').value,
                    type: document.getElementById('edit_type').value,
                    condition: document.getElementById('edit_condition').value,
                    geom: {
                        type: 'Point',
                        coordinates: [
                            parseFloat(document.getElementById('edit_longitude').value),
                            parseFloat(document.getElementById('edit_latitude').value)
                        ]
                    }
                };

                try {
                    const putResponse = await fetch(`${API_URL}/graves/${graveId}`, {
                        method: 'PUT',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify(updatedGrave)
                    });

                    if (!putResponse.ok) {
                        const errorData = await putResponse.json();
                        throw new Error(`HTTP error! status: ${putResponse.status}, message: ${errorData.error}`);
                    }

                    alert('Hrob úspěšně aktualizován!');
                    editForm.remove(); // Remove form after successful update
                    fetchAndVisualizeGraves(); // Refresh map and list
                } catch (error) {
                    console.error('Error updating grave:', error);
                    alert(`Chyba při aktualizaci hrobu: ${error.message}`);
                }
            });

            document.getElementById('cancel-edit-btn').addEventListener('click', () => {
                editForm.remove();
            });

        } catch (error) {
            console.error(`Error fetching grave for editing (ID: ${graveId}):`, error);
            alert('Chyba při načítání dat hrobu pro úpravy.');
        }
    }

    // Function to delete a grave
    async function deleteGrave(graveId) {
        try {
            const response = await fetch(`${API_URL}/graves/${graveId}`, {
                method: 'DELETE'
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            alert('Hrob úspěšně smazán!');
            fetchAndVisualizeGraves(); // Refresh map and list
        } catch (error) {
            console.error('Error deleting grave:', error);
            alert('Chyba při mazání hrobu.');
        }
    }
});
