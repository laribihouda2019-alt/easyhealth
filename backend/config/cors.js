const cors = require('cors');
const ENV = require('./env');

// Production Vercel frontend URLs - always allowed
const PRODUCTION_ORIGINS = [
  'https://web-three-omega-76.vercel.app',
  'https://web-7g9bp9355-easyhealth1.vercel.app',
  'https://easyhealth-frontend.vercel.app',
];

function buildCorsOptions() {
  const allowedOrigins = [
    ...PRODUCTION_ORIGINS,
    ...ENV.CORS_ORIGINS,
  ];
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
        origin.startsWith('https://localhost') ||
        origin.startsWith('chrome-extension://') ||
        origin.startsWith('devtools://')
      )) {
        return callback(null, true);
      }

      // Allow all vercel.app subdomains for demo robustness
      if (origin.endsWith('.vercel.app')) {
        return callback(null, true);
      }

      // Allow onrender.com for service-to-service calls
      if (origin.endsWith('.onrender.com')) {
        return callback(null, true);
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

