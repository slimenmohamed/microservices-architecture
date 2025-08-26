import swaggerJSDoc from 'swagger-jsdoc';

const options = {
  definition: {
    openapi: '3.0.3',
    info: {
      title: 'Notification Service API',
      version: '1.0.0',
    },
    servers: [{ url: '/' }],
    components: {
      schemas: {
        Notification: {
          type: 'object',
          properties: {
            id: { type: 'integer' },
            subject: { type: 'string' },
            message: { type: 'string' },
            recipientId: { type: 'integer' },
            created_at: { type: 'string', format: 'date-time' },
          },
          example: { id: 1, subject: 'Hello', message: 'World', recipientId: 1, created_at: '2025-08-12T12:00:00Z' },
        },
        CreateNotificationInput: {
          type: 'object',
          required: ['subject', 'message'],
          properties: {
            subject: { type: 'string' },
            message: { type: 'string' },
            recipientId: { type: 'integer' },
          },
          example: { subject: 'Greetings', message: 'Hi there', recipientId: 1 },
        },
        Error: {
          type: 'object',
          properties: {
            code: { type: 'integer' },
            message: { type: 'string' },
            correlationId: { type: 'string' },
            details: { type: 'array', items: { type: 'object' } },
          },
          example: { code: 400, message: 'validation error', correlationId: 'abc-123', details: [] },
        },
      },
      responses: {
        NotFound: {
          description: 'Not found',
          content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
        },
        ValidationError: {
          description: 'Bad request - validation error',
          content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
        },
        RecipientNotFound: {
          description: 'Recipient not found',
          content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
        },
        ServiceUnavailable: {
          description: 'Upstream service unavailable',
          content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } },
        },
      },
    },
  },
  apis: ['./src/routes/*.js'],
};

export const swaggerSpec = swaggerJSDoc(options);
