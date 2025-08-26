import mysql from 'mysql2/promise';

const cfg = {
  host: process.env.DB_HOST || 'localhost',
  port: +(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'notifdb',
  connectionLimit: 10,
};

let pool;
export function getPool() {
  if (!pool) pool = mysql.createPool(cfg);
  return pool;
}

export async function ensureSchema() {
  // Retry until DB is reachable
  const maxAttempts = 30;
  const delayMs = 2000;
  let attempt = 0;
  while (true) {
    try {
      const conn = await getPool().getConnection();
      try {
        // Create with desired schema (subject, message, created_at)
        await conn.query(`CREATE TABLE IF NOT EXISTS notifications (
          id INT AUTO_INCREMENT PRIMARY KEY,
          subject VARCHAR(255) NOT NULL,
          message TEXT NOT NULL,
          recipientId INT NULL,
          created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;`);

        // Inspect existing columns and migrate if needed (compatible across MySQL 8 variants)
        const [cols] = await conn.query(
          `SELECT COLUMN_NAME FROM information_schema.COLUMNS 
           WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'notifications'`
        );
        const names = new Set(cols.map(c => c.COLUMN_NAME));
        const alters = [];
        if (!names.has('subject')) {
          alters.push("ADD COLUMN subject VARCHAR(255) NOT NULL DEFAULT '' AFTER id");
        }
        // Ensure message type is TEXT NOT NULL (best-effort)
        if (names.has('message')) {
          alters.push('MODIFY COLUMN message TEXT NOT NULL');
        }
        if (!names.has('recipientId')) {
          alters.push('ADD COLUMN recipientId INT NULL AFTER message');
        }
        if (names.has('userId')) {
          alters.push('DROP COLUMN userId');
        }
        if (names.has('status')) {
          alters.push('DROP COLUMN status');
        }
        if (!names.has('created_at')) {
          alters.push('ADD COLUMN created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP AFTER message');
        }
        if (alters.length) {
          const sql = 'ALTER TABLE notifications ' + alters.join(', ');
          await conn.query(sql);
        }
        // Ensure index on recipientId for faster lookups
        const [idxRows] = await conn.query(
          `SELECT COUNT(1) AS cnt FROM information_schema.statistics
           WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'notifications' AND INDEX_NAME = 'idx_notifications_recipientId'`
        );
        if ((idxRows[0]?.cnt || 0) === 0) {
          await conn.query('CREATE INDEX idx_notifications_recipientId ON notifications (recipientId)');
        }
        return; // success
      } finally {
        conn.release();
      }
    } catch (err) {
      attempt++;
      if (attempt >= maxAttempts) {
        console.error('Failed to connect to MySQL after retries:', err);
        throw err;
      }
      console.log(`MySQL not ready, retrying in ${delayMs}ms (attempt ${attempt}/${maxAttempts})...`);
      await new Promise(r => setTimeout(r, delayMs));
    }
  }
}

