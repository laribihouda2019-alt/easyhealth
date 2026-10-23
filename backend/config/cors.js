const cors = require('cors');
const ENV = require('./env');

function buildCorsOptions() {
  const allowedOrigins = ENV.CORS_ORIGINS;
  const isDev = ENV.NODE_ENV !== 'production';

  return {
    origin(origin, callback) {
      //allow request with no origin(mobile apps,Postman,...)
      if (!origin) {
        return callback(null, true);
      }

      //allow all localhost and 127.0.0.1 origins regardless of port
      if (isDev && (
        origin.startsWith('http://localhost') ||
        origin.startsWith('http://127.0.0.1') ||
        origin.startsWith('https://localhost') || //for local service workers 
        origin.startsWith('chrome-extension://') ||
        origin.startsWith('devtools://')
      )) {
        return callback(null, true); //all preced accepte
      }

      //check against explicit allowed origins
      if (allowedOrigins.includes(origin)) {
        return callback(null, true);
      }

      //log rejected origin for debugging
      console.log('CORS rejected origin:', origin);
      return callback(new Error('Not allowed by CORS'), false);
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  };
}

const corsMiddleware = cors(buildCorsOptions());

module.exports = {
  corsMiddleware,
};

