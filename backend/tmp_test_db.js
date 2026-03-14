import 'dotenv/config';
import pg from 'pg';

const { Pool } = pg;
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  connectionTimeoutMillis: 5000,
});

async function test() {
  console.log('Testing connection to:', process.env.DATABASE_URL?.split('@')[1]);
  try {
    const client = await pool.connect();
    console.log('✅ Connection successful!');
    const res = await client.query('SELECT NOW()');
    console.log('Current time from DB:', res.rows[0]);
    client.release();
  } catch (err) {
    console.error('❌ Connection failed:', err.message);
  } finally {
    await pool.end();
  }
}

test();
