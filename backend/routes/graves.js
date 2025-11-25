const express = require('express');
const router = express.Router();
const pool = require('../db/pool');

// GET all graves as GeoJSON
router.get('/', async (req, res) => {
    console.log('[Graves Router] Fetching all graves...');
    try {
        const result = await pool.query(
            `SELECT
                g.id,
                g.section,
                g.grave_number,
                g.type,
                g.condition,
                ST_AsGeoJSON(g.geom)::json AS geometry,
                ARRAY_AGG(d.name) FILTER (WHERE d.name IS NOT NULL) AS deceased_names
             FROM graves g
             LEFT JOIN deceased d ON g.id = d.grave_id
             GROUP BY g.id`
        );

        const geojson = {
            type: 'FeatureCollection',
            features: result.rows.map(grave => ({
                type: 'Feature',
                geometry: grave.geometry,
                properties: {
                    id: grave.id,
                    section: grave.section,
                    grave_number: grave.grave_number,
                    type: grave.type,
                    condition: grave.condition,
                    deceased_names: grave.deceased_names
                }
            }))
        };
        res.json(geojson);
    } catch (err) {
        console.error('Error fetching graves:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// GET single grave including deceased and photos
router.get('/:id', async (req, res) => {
    const { id } = req.params;
    try {
        const graveResult = await pool.query(
            `SELECT
                id,
                section,
                grave_number,
                type,
                condition,
                ST_AsGeoJSON(geom)::json AS geometry
             FROM graves
             WHERE id = $1`,
            [id]
        );

        if (graveResult.rows.length === 0) {
            return res.status(404).json({ error: 'Grave not found' });
        }

        const grave = graveResult.rows[0];

        const deceasedResult = await pool.query(
            'SELECT id, name, birth_year, death_year FROM deceased WHERE grave_id = $1',
            [id]
        );

        const photosResult = await pool.query(
            'SELECT id, url FROM photos WHERE grave_id = $1',
            [id]
        );

        res.json({
            id: grave.id,
            section: grave.section,
            grave_number: grave.grave_number,
            type: grave.type,
            condition: grave.condition,
            geometry: grave.geometry,
            deceased: deceasedResult.rows,
            photos: photosResult.rows
        });

    } catch (err) {
        console.error(`Error fetching grave with id ${id}:`, err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// POST create a new grave
router.post('/', async (req, res) => {
    const { section, grave_number, type, condition, geom } = req.body;
    try {
        const result = await pool.query(
            `INSERT INTO graves (section, grave_number, type, condition, geom)
             VALUES ($1, $2, $3, $4, ST_GeomFromGeoJSON($5))
             RETURNING id, section, grave_number, type, condition, ST_AsGeoJSON(geom)::json AS geometry`,
            [section, grave_number, type, condition, geom]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error('Error creating grave:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// PUT update an existing grave
router.put('/:id', async (req, res) => {
    const { id } = req.params;
    const { section, grave_number, type, condition, geom } = req.body;
    try {
        const result = await pool.query(
            `UPDATE graves
             SET section = $1, grave_number = $2, type = $3, condition = $4, geom = ST_GeomFromGeoJSON($5)
             WHERE id = $6
             RETURNING id, section, grave_number, type, condition, ST_AsGeoJSON(geom)::json AS geometry`,
            [section, grave_number, type, condition, geom, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Grave not found' });
        }
        res.json(result.rows[0]);
    } catch (err) {
        console.error(`Error updating grave with id ${id}:`, err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// DELETE a grave
router.delete('/:id', async (req, res) => {
    const { id } = req.params;
    try {
        const result = await pool.query(
            'DELETE FROM graves WHERE id = $1 RETURNING id',
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Grave not found' });
        }
        res.status(204).send(); // No content for successful deletion
    } catch (err) {
        console.error(`Error deleting grave with id ${id}:`, err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

module.exports = router;
