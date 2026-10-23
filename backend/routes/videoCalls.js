const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middlewares/auth');
const videoCallController = require('../controllers/videoCallController');

//apply auth middleware to all routes
router.use(authMiddleware);

//video Call Management
router.post('/initiate', videoCallController.initiateVideoCall);
router.put('/:callId/accept', videoCallController.acceptVideoCall);
router.put('/:callId/reject', videoCallController.rejectVideoCall);
router.put('/:callId/end', videoCallController.endVideoCall);
router.get('/:callId', videoCallController.getVideoCall);
router.get('/', videoCallController.getUserVideoCalls);
router.get('/active', videoCallController.getActiveVideoCalls);

//video Call Technical
router.get('/:callId/token', videoCallController.generateVideoCallToken);
router.put('/:callId/quality', videoCallController.updateCallQuality);

module.exports = router;
