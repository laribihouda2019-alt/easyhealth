const http = require('http');
const https = require('https');
const fs = require('fs');
const app = require('./app');
const ENV = require('./config/env');

let server;

if (ENV.ENABLE_HTTPS && ENV.HTTPS_KEY_PATH && ENV.HTTPS_CERT_PATH) {
  try {
    const key = fs.readFileSync(ENV.HTTPS_KEY_PATH);
    const cert = fs.readFileSync(ENV.HTTPS_CERT_PATH);
    server = https.createServer({ key, cert }, app);
    console.log('Starting HTTPS server...');
  } catch (err) {
    console.error('Failed to start HTTPS server, falling back to HTTP:', err.message);
    server = http.createServer(app);
  }
} else {
  server = http.createServer(app);
}

const { initCronJobs } = require('./services/cronService');
const { initSocket } = require('./services/socketService');

server.setTimeout(120000);
server.headersTimeout = 65000;
server.keepAliveTimeout = 60000;

//Initialize Socket.io
initSocket(server);

//Initialize Cron Jobs
initCronJobs();

server.listen(ENV.PORT, '0.0.0.0', () => {
  console.log(`EasyHealth API listening on port ${ENV.PORT} (${ENV.ENABLE_HTTPS ? 'HTTPS' : 'HTTP'})`);
});


