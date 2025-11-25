const { Pool } = require('pg');

const pool = new Pool({
    user: 'postgres',      // Replace with your PostgreSQL username
    host: 'localhost',
    database: 'cemetery_passport', // Replace with your database name
    password: 'master',  // Replace with your PostgreSQL password
    port: 5432,                 // Default PostgreSQL port
});

module.exports = pool;
