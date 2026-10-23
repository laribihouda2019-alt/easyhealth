const express = require('express');
const router = express.Router();
const agoraController = require('../controllers/agoraController');
const { authMiddleware } = require('../middlewares/auth');

//using authMiddleware to ensure secure token generation
router.get('/token', authMiddleware, agoraController.generateToken);
router.post('/token', authMiddleware, agoraController.generateToken);

module.exports = router;
