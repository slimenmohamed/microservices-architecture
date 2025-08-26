import { Router } from 'express';
import { getPool } from '../db.js';

const router = Router();

router.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

router.get('/ready', async (_req, res) => {
  try {
    const conn = await getPool().getConnection();
    try {
      await conn.query('SELECT 1');
      res.json({ status: 'ready' });
    } finally {
      conn.release();
    }
  } catch (e) {
    res.status(503).json({ status: 'not_ready', error: e.message });
  }
});

export default router;
