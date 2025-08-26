import { Router } from 'express';
import { body, param, validationResult } from 'express-validator';
import { getPool } from '../db.js';
import fetch from 'node-fetch';
import { randomUUID } from 'crypto';
import { publishEvent } from '../queue.js';

const router = Router();

/**
 * @swagger
 * /notifications:
 *   get:
 *     summary: List notifications
 *     tags: [Notifications]
 *     responses:
 *       200:
 *         description: OK
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Notification'
 */
router.get('/', async (_req, res) => {
  const [rows] = await getPool().query('SELECT id, subject, message, recipientId, created_at FROM notifications ORDER BY id DESC');
  res.json(rows);
});

/**
 * @swagger
 * /notifications/{id}:
 *   get:
 *     summary: Get a notification by id
 *     tags: [Notifications]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         description: OK
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Notification'
 *       404:
 *         $ref: '#/components/responses/NotFound'
 */
router.get('/:id', async (req, res) => {
  const [rows] = await getPool().query('SELECT id, subject, message, recipientId, created_at FROM notifications WHERE id = ?', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ message: 'Not found' });
  res.json(rows[0]);
});

/**
 * @swagger
 * /notifications:
 *   post:
 *     summary: Create a notification
 *     tags: [Notifications]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/CreateNotificationInput'
 *           examples:
 *             sample:
 *               value: { subject: 'Hello', message: 'World', recipientId: 1 }
 *     responses:
 *       201:
 *         description: Created
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Notification'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       422:
 *         $ref: '#/components/responses/RecipientNotFound'
 *       503:
 *         $ref: '#/components/responses/ServiceUnavailable'
 */
router.post(
  '/',
  [
    body('subject').isString().trim().notEmpty().withMessage('subject is required'),
    body('message').isString().trim().notEmpty().withMessage('message is required'),
    body('recipientId').optional({ nullable: true }).isInt({ gt: 0 }).withMessage('recipientId must be a positive integer'),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ code: 400, message: 'validation error', details: errors.array() });
    }
    const { subject, message, recipientId } = req.body || {};

  // Optional: validate recipient via user-service if recipientId provided
  // To avoid deadlock when the request originates from user-service (which uses PHP built-in server),
  // skip validation if x-origin header indicates user-service.
  const origin = String(req.headers['x-origin'] || '').toLowerCase();
  const shouldValidate = origin !== 'user-service';
  if (shouldValidate && recipientId !== undefined && recipientId !== null) {
    try {
      const controller = new AbortController();
      const t = setTimeout(() => controller.abort(), 3000);
      const correlationId = req.headers['x-correlation-id'] || randomUUID();
      const resp = await fetch(`http://user-service:8000/users/${recipientId}`, {
        method: 'GET',
        headers: { 'x-correlation-id': String(correlationId) },
        signal: controller.signal,
      });
      clearTimeout(t);
      if (resp.status === 404) {
        return res.status(422).json({ code: 422, message: 'recipient not found', recipientId });
      }
      if (!resp.ok) {
        return res.status(503).json({ code: 503, message: 'user-service unavailable' });
      }
    } catch (e) {
      return res.status(503).json({ code: 503, message: 'user-service timeout or error' });
    }
  }

  const [result] = await getPool().query(
    'INSERT INTO notifications (subject, message, recipientId) VALUES (?, ?, ?)',
    [subject, message, recipientId ?? null]
  );
  const [rows] = await getPool().query('SELECT id, subject, message, recipientId, created_at FROM notifications WHERE id = ?', [result.insertId]);
  const created = rows[0];
  // Best-effort publish to RabbitMQ (optional)
  try {
    await publishEvent('notifications.created', {
      id: created.id,
      subject: created.subject,
      message: created.message,
      recipientId: created.recipientId,
      created_at: created.created_at,
      correlationId: req.headers['x-correlation-id'] || undefined,
    });
  } catch (e) {
    // Non-fatal: log and continue
    console.warn('RabbitMQ publish failed (optional):', e?.message || e);
  }
  res.status(201).json(created);
});

/**
 * @swagger
 * /notifications/{id}:
 *   put:
 *     summary: Update a notification
 *     tags: [Notifications]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               subject: { type: string }
 *               message: { type: string }
 *     responses:
 *       200:
 *         description: OK
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Notification'
 *       400:
 *         $ref: '#/components/responses/ValidationError'
 *       404:
 *         $ref: '#/components/responses/NotFound'
 */
router.put(
  '/:id',
  [
    param('id').isInt({ gt: 0 }).withMessage('id must be a positive integer'),
    body('subject').optional({ nullable: true }).isString().trim().notEmpty().withMessage('subject must be non-empty'),
    body('message').optional({ nullable: true }).isString().trim().notEmpty().withMessage('message must be non-empty'),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ code: 400, message: 'validation error', details: errors.array() });
    }
    const { subject, message } = req.body || {};
    // If nothing to update
    if (subject === undefined && message === undefined) {
      return res.status(400).json({ code: 400, message: 'Nothing to update' });
    }
    const [result] = await getPool().query(
      'UPDATE notifications SET subject = COALESCE(?, subject), message = COALESCE(?, message) WHERE id = ?',
      [subject ?? null, message ?? null, req.params.id]
    );
    if (result.affectedRows === 0) return res.status(404).json({ code: 404, message: 'Not found' });
    const [rows] = await getPool().query('SELECT id, subject, message, recipientId, created_at FROM notifications WHERE id = ?', [req.params.id]);
    res.json(rows[0]);
  }
);

/**
 * @swagger
 * /notifications/{id}:
 *   delete:
 *     summary: Delete a notification
 *     tags: [Notifications]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       204: { description: No Content }
 *       404:
 *         $ref: '#/components/responses/NotFound'
 */
router.delete(
  '/:id',
  [param('id').isInt({ gt: 0 }).withMessage('id must be a positive integer')],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ code: 400, message: 'validation error', details: errors.array() });
    }
    const [result] = await getPool().query('DELETE FROM notifications WHERE id = ?', [req.params.id]);
    if (result.affectedRows === 0) return res.status(404).json({ code: 404, message: 'Not found' });
    res.status(204).send();
  }
);

export default router;
