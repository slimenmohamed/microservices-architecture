import amqplib from 'amqplib';

const RABBITMQ_URL = process.env.RABBITMQ_URL || 'amqp://rabbitmq:5672';
const EXCHANGE = process.env.NOTIF_EXCHANGE || 'notifications';

let connection;
let channel;

export async function initQueue() {
  if (channel) return channel;
  connection = await amqplib.connect(RABBITMQ_URL);
  channel = await connection.createChannel();
  await channel.assertExchange(EXCHANGE, 'topic', { durable: true });
  return channel;
}

export async function publishEvent(routingKey, message) {
  if (!channel) await initQueue();
  const payload = Buffer.from(JSON.stringify(message));
  channel.publish(EXCHANGE, routingKey, payload, { contentType: 'application/json', persistent: true });
}

export async function consume(routingKey, handler) {
  if (!channel) await initQueue();
  const { queue } = await channel.assertQueue('', { exclusive: true });
  await channel.bindQueue(queue, EXCHANGE, routingKey);
  await channel.consume(queue, async (msg) => {
    if (!msg) return;
    try {
      const content = JSON.parse(msg.content.toString());
      await handler(content, msg);
      channel.ack(msg);
    } catch (e) {
      console.error('Consumer handler error:', e);
      channel.nack(msg, false, false);
    }
  });
}

export async function closeQueue() {
  try { await channel?.close(); } catch {}
  try { await connection?.close(); } catch {}
}
