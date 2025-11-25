const express = require('express');
const cors = require('cors');
const gravesRouter = require('./routes/graves');
const deceasedRouter = require('./routes/deceased');

const app = express();

app.use(cors());
app.use(express.json());

app.use((req, res, next) => {
    console.log(`[Backend App] Incoming request: ${req.method} ${req.url}`);
    next();
});

app.use('/api/graves', gravesRouter);
app.use('/api/deceased', deceasedRouter);

const path = require('path');

app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, '../frontend', 'index.html'));
});

app.get('/grave.html', (req, res) => {
    res.sendFile(path.join(__dirname, '../frontend', 'grave.html'));
});

// Serve static assets from the frontend directory
app.use(express.static(path.join(__dirname, '../frontend')));

module.exports = app;
