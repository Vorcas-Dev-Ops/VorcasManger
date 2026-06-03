import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;

const sslConfig = (process.env.DB_SSL || 'disable').trim().toLowerCase() === 'disable' ? false : { rejectUnauthorized: false };
console.log('Database SSL Config:', sslConfig);

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME || 'vorcas_db',
  user: process.env.DB_USERNAME || 'postgres',
  password: process.env.DB_PASSWORD || '',
  ssl: sslConfig,
});

// Test connection
pool.on('error', (err) => {
  console.error('Unexpected error on idle database client', err);
});

// Set session timezone to IST for every new connection
pool.on('connect', (client) => {
    client.query("SET timezone = 'Asia/Kolkata'")
        .catch(err => console.error('Error setting session timezone:', err));
});

export default pool;

