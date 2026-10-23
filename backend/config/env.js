const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const ENV = {
  NODE_ENV: process.env.NODE_ENV || 'development',

  PORT: Number(process.env.PORT) || 4000, //num port serveur 

  DATABASE_URL: process.env.DATABASE_URL,
  DB_SSL:
    process.env.DB_SSL === 'false'
      ? false
      : { rejectUnauthorized: process.env.DB_SSL_REJECT_UNAUTHORIZED !== 'false' },  //url base de donnees
  DB_MAX_CONNECTIONS: Number(process.env.DB_MAX_CONNECTIONS) || 10,
  DB_IDLE_TIMEOUT_MS: Number(process.env.DB_IDLE_TIMEOUT_MS) || 30000,
  DB_CONNECTION_TIMEOUT_MS: Number(process.env.DB_CONNECTION_TIMEOUT_MS) || 5000,
  DB_QUERY_TIMEOUT_MS: Number(process.env.DB_QUERY_TIMEOUT_MS) || 10000,

  CORS_ORIGINS: (process.env.CORS_ORIGINS || '')
    .split(',')
    .map((o) => o.trim()) //liste des domaine autorises a acceder a api 
    .filter(Boolean),

  ENABLE_HTTPS: process.env.ENABLE_HTTPS === 'true',
  HTTPS_KEY_PATH: process.env.HTTPS_KEY_PATH,
  HTTPS_CERT_PATH: process.env.HTTPS_CERT_PATH,

  //chargily Pay V2
  CHARGILY_PUBLIC_KEY: process.env.CHARGILY_PUBLIC_KEY,
  CHARGILY_SECRET_KEY: process.env.CHARGILY_SECRET_KEY,

  //frontend URL for payment redirects
  FRONTEND_URL: process.env.FRONTEND_URL || 'http://localhost:8080',
};

module.exports = ENV;

