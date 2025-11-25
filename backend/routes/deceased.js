const express = require('express');
const router = express.Router();
const pool = require('../db/pool');

// GET single deceased record
router.get('/:id', async (req, res) => {
    const { id } = req.params;
    try {
        const result = await pool.query(
            'SELECT id, name, birth_year, death_year, grave_id FROM deceased WHERE id = $1',
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Deceased record not found' });
        }

        res.json(result.rows[0]);
    } catch (err) {
        console.error(`Error fetching deceased with id ${id}:`, err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

module.exports = router;
