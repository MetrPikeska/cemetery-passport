const app = require('./app');
const pool = require('./db/pool');

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(`Backend server running on port ${PORT}`);
});

// Test database connection
pool.query('SELECT NOW()', (err, res) => {
    if (err) {
        console.error('Error connecting to the database', err.stack);
    } else {
        console.log('Database connected successfully:', res.rows[0].now);
    }
});
