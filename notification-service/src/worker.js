import { consume, initQueue } from './queue.js';

async function main() {
  await initQueue();
  console.log('notification-worker: waiting for notifications.created events...');
  await consume('notifications.created', async (event) => {
    // Example side-effect: just log. In real world, send email/SMS, push, etc.
    console.log('notification-worker consumed event:', JSON.stringify(event));
  });
}

main().catch((e) => {
  console.error('notification-worker failed to start', e);
  process.exit(1);
});
