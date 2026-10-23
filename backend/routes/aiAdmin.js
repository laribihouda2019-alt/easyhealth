const express = require('express');
const router = express.Router();
const { authMiddleware, requireRole } = require('../middlewares/auth');
const aiAdminController = require('../controllers/aiAdminController');

//apply auth middleware to all routes
router.use(authMiddleware);

//require admin role for all routes
router.use(requireRole('admin'));

//disease Statistics and Analytics
router.get('/statistics/diseases', aiAdminController.getDiseaseStatistics);
router.get('/statistics/trends', aiAdminController.generateDiseaseTrends);
router.get('/statistics/regional', aiAdminController.getRegionalDistribution);
router.get('/statistics/insights', aiAdminController.getHealthInsights);

//epidemic Alerts
router.get('/epidemic-alerts', aiAdminController.getEpidemicAlerts);
router.put('/epidemic-alerts/:alertId', aiAdminController.updateEpidemicAlert);

//aI Analysis
router.post('/analysis/mass', aiAdminController.performMassAnalysis);
router.get('/prediction/disease', aiAdminController.getDiseasePrediction);

module.exports = router;
