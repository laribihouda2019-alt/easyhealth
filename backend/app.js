const express = require('express');
const cors = require('cors');
const path = require('path');
const helmet = require('helmet');
const { notFoundHandler, errorHandler } = require('./middlewares/errorMiddleware');
const { corsMiddleware } = require('./config/cors');
const ENV = require('./config/env');

const app = express();

app.set('trust proxy', 1);

app.use(helmet({
  crossOriginResourcePolicy: false, //Allow cross-origin for images/files
}));

app.use(corsMiddleware);

app.use(express.json({ limit: '5mb' }));
app.use(express.urlencoded({ extended: true }));

//Serve static files from the uploads folder with CORS headers
app.use('/uploads', cors(), express.static(path.join(__dirname, 'uploads')));
app.use('/uploads/medical_requests', cors(), express.static(path.join(__dirname, 'uploads/medical_requests')));

app.use('/api', require('./routes/api'));

app.use(notFoundHandler);
app.use(errorHandler);

if (ENV.NODE_ENV !== 'production') {
  console.log('CORS allowed origins:', ENV.CORS_ORIGINS);
}

module.exports = app;


