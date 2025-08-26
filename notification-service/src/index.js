import express from 'express';
import { getPool, ensureSchema } from './db.js';
import notificationsRouter from './routes/notifications.js';
import healthRouter from './routes/health.js';
import swaggerUi from 'swagger-ui-express';
import { swaggerSpec } from './openapi.js';
import { v4 as uuidv4 } from 'uuid';

const app = express();
app.use(express.json({ limit: '1mb' }));


// Correlation ID middleware
app.use((req, res, next) => {
  const headerKey = 'x-correlation-id';
  let cid = req.header(headerKey);
  if (!cid) cid = uuidv4();
  res.setHeader(headerKey, cid);
  req.correlationId = cid;
  next();
});

// Health and readiness
app.use('/', healthRouter);

// Swagger UI
app.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
// Raw OpenAPI JSON
app.get('/docs.json', (_req, res) => res.json(swaggerSpec));

// Routes
app.use('/notifications', notificationsRouter);


const port = process.env.PORT || 3000;

let server;
(async () => {
  await ensureSchema();
  server = app.listen(port, () => console.log(`notification-service listening on ${port}`));
})();

// Centralized error handler
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  const status = err.status || 500;
  const payload = {
    code: status,
    message: err.message || 'Internal Server Error',
    correlationId: req?.correlationId,
    details: err.details || undefined,
  };
  if (status >= 500) console.error('Unhandled error', { err });
  res.status(status).json(payload);
});

// Graceful shutdown
async function shutdown(signal) {
  try {
    console.log(`Received ${signal}, shutting down...`);
    if (server) {
      await new Promise((resolve) => server.close(resolve));
    }
    try {
      await getPool().end();
    } catch (e) {}
    process.exit(0);
  } catch (e) {
    console.error('Error during shutdown', e);
    process.exit(1);
  }
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
process.on('unhandledRejection', (reason) => {
  console.error('Unhandled Rejection', reason);
});
