const express = require('express');
const router = express.Router();

//import controllers
const authController = require('../controllers/authController');
const profileController = require('../controllers/profileController');
const appointmentController = require('../controllers/appointmentController');
const messageController = require('../controllers/messageController');
const enhancedMessageController = require('../controllers/enhancedMessageController');
const symptomController = require('../controllers/symptomController');
const medicationController = require('../controllers/medicationController');
const verificationController = require('../controllers/verificationController');
const paymentController = require('../controllers/paymentController');
const healthAlertController = require('../controllers/healthAlertController');
const analyticsController = require('../controllers/analyticsController');

//import new controllers
const patientController = require('../controllers/patientController');
const doctorController = require('../controllers/doctorController');
const aiAdminController = require('../controllers/aiAdminController');
const diseaseObservatoryController = require('../controllers/diseaseObservatoryController');
const medicalRouterController = require('../controllers/medicalRouterController');
const videoCallController = require('../controllers/videoCallController');
const orderController = require('../controllers/orderController');
const medicalRecordController = require('../controllers/medicalRecordController');
const labController = require('../controllers/labController');
const pharmacyController = require('../controllers/pharmacyController');
const notificationController = require('../controllers/notificationController');
const availabilityController = require('../controllers/availabilityController');
const uploadController = require('../controllers/uploadController');
const socialSecurityRoutes = require('./socialSecurityRoutes');

//import middleware
const { authMiddleware } = require('../middlewares/auth');

//AUTH ROUTES
router.post('/auth/register', authController.registerUser);
router.post('/auth/login', authController.loginUser);
router.post('/auth/logout', authController.logout);
router.post('/auth/forgot-password', authController.forgotPassword);
router.post('/auth/reset-password', authController.resetPassword);

//PROFILE ROUTES
router.get('/profile/me', authMiddleware, authController.getMyProfile);
router.get('/profile/stats', authMiddleware, profileController.getProfileStats);
router.put('/profile/me', authMiddleware, profileController.updateProfile);
router.post('/profile/avatar', authMiddleware, uploadController.upload.single('avatar'), uploadController.uploadAvatar);
router.get('/profiles/role/:role', authMiddleware, authController.getProfilesByRole);
router.get('/profiles/search', authMiddleware, profileController.searchProfiles);
router.put('/profiles/:userId/approve', authMiddleware, profileController.approveProfile);
router.get('/profiles/:userId', authMiddleware, profileController.getProfileById);
router.get('/availability/:doctorId', authMiddleware, availabilityController.getAvailableDoctorSlots);

//CONVENIENCE ROUTES for Pharmacies and Laboratories
router.get('/pharmacies', authMiddleware, (req, res, next) => {
    req.params.role = 'pharmacy';
    authController.getProfilesByRole(req, res, next);
});
router.get('/laboratories', authMiddleware, (req, res, next) => {
    req.params.role = 'lab';
    authController.getProfilesByRole(req, res, next);
});

//APPOINTMENT ROUTES (Legacy)
router.post('/appointments', authMiddleware, appointmentController.createAppointment);
router.get('/appointments/me', authMiddleware, appointmentController.getMyAppointments);
router.get('/appointments/:id', authMiddleware, appointmentController.getAppointmentById);
router.put('/appointments/:id', authMiddleware, appointmentController.updateAppointment);
router.put('/appointments/:id/status', authMiddleware, appointmentController.updateAppointmentStatus);
router.get('/appointments/upcoming/me', authMiddleware, appointmentController.getUpcomingAppointments);
router.get('/appointments/doctor/:doctorId/schedule', authMiddleware, appointmentController.getDoctorSchedule);

// MESSAGE ROUTES (Original)
router.post('/messages', authMiddleware, messageController.sendMessage);
router.get('/messages/conversation/:userId', authMiddleware, messageController.getConversation);
router.get('/messages/me', authMiddleware, messageController.getMyMessages);
router.get('/messages/unread', authMiddleware, messageController.getUnreadMessages);
router.put('/messages/:messageId/read', authMiddleware, messageController.markMessageAsRead);
router.put('/messages/conversation/:userId/read', authMiddleware, messageController.markConversationAsRead);
router.get('/messages/appointment/:appointmentId', authMiddleware, messageController.getAppointmentMessages);
router.delete('/messages/:messageId', authMiddleware, messageController.deleteMessage);

//ENHANCED MESSAGE ROUTES (With images and delivery)
router.post('/enhanced-messages/send', authMiddleware, enhancedMessageController.upload.single('image'), enhancedMessageController.sendMessage);
router.get('/enhanced-messages/conversation/:otherUserId', authMiddleware, enhancedMessageController.getConversation);
router.get('/enhanced-messages/my-conversations', authMiddleware, enhancedMessageController.getMyConversations);
router.put('/enhanced-messages/:messageId/delivery-status', authMiddleware, enhancedMessageController.updateDeliveryStatus);
router.put('/enhanced-messages/:messageId/read', authMiddleware, enhancedMessageController.markAsRead);

//SYMPTOM ROUTES
router.post('/symptoms', authMiddleware, symptomController.logSymptom);
router.get('/symptoms/me', authMiddleware, symptomController.getMySymptoms);
router.get('/symptoms/:id', authMiddleware, symptomController.getSymptomById);
router.put('/symptoms/:id', authMiddleware, symptomController.updateSymptom);
router.delete('/symptoms/:id', authMiddleware, symptomController.deleteSymptom);
router.get('/symptoms/date-range', authMiddleware, symptomController.getSymptomsByDateRange);
router.get('/symptoms/recent', authMiddleware, symptomController.getRecentSymptoms);
router.get('/symptoms/search', authMiddleware, symptomController.searchSymptoms);
router.get('/symptoms/statistics', authMiddleware, symptomController.getSymptomStatistics);
router.get('/symptoms/common', authMiddleware, symptomController.getCommonSymptoms);

//MEDICATION ROUTES (Legacy)
router.post('/medications', authMiddleware, medicationController.addMedication);
router.get('/medications', authMiddleware, medicationController.getMyMedications);
router.get('/medications/me', authMiddleware, medicationController.getMyMedications);
router.get('/medications/:id', authMiddleware, medicationController.getMedicationById);
router.put('/medications/:id', authMiddleware, medicationController.updateMedication);
router.put('/medications/:id/deactivate', authMiddleware, medicationController.deactivateMedication);
router.get('/medications/today', authMiddleware, medicationController.getTodaysMedications);
router.get('/medications/due-at', authMiddleware, medicationController.getMedicationsDueAtTime);
router.get('/medications/date-range', authMiddleware, medicationController.getMedicationsByDateRange);
router.get('/medications/search', authMiddleware, medicationController.searchMedications);
router.get('/medications/statistics', authMiddleware, medicationController.getMedicationStatistics);

//VERIFICATION ROUTES
router.post('/verification/requests', authMiddleware, verificationController.createVerificationRequest);
router.get('/verification/requests/me', authMiddleware, verificationController.getMyVerificationRequests);
router.get('/verification/requests/:id', authMiddleware, verificationController.getVerificationRequestById);
router.get('/verification/requests/pending', authMiddleware, verificationController.getPendingVerificationRequests);
router.get('/verification/requests/status/:status', authMiddleware, verificationController.getVerificationRequestsByStatus);
router.put('/verification/requests/:id/review', authMiddleware, verificationController.reviewVerificationRequest);
router.put('/verification/requests/:id/ai-analysis', authMiddleware, verificationController.updateAIAnalysis);
router.get('/verification/requests/role/:role', authMiddleware, verificationController.getVerificationRequestsByRole);
router.get('/verification/requests/pending/me', authMiddleware, verificationController.checkPendingVerification);
router.get('/verification/statistics', authMiddleware, verificationController.getVerificationStatistics);

//PAYMENT ROUTES
router.post('/payments', authMiddleware, paymentController.createPayment);
router.get('/payments/me', authMiddleware, paymentController.getMyPayments);
router.get('/payments/:id', authMiddleware, paymentController.getPaymentById);
router.put('/payments/:id/status', authMiddleware, paymentController.updatePaymentStatus);
router.get('/payments/status/:status', authMiddleware, paymentController.getPaymentsByStatus);
router.get('/payments/appointment/:appointmentId', authMiddleware, paymentController.getAppointmentPayments);
router.get('/payments/statistics', authMiddleware, paymentController.getPaymentStatistics);
router.get('/payments/revenue', authMiddleware, paymentController.getRevenueStatistics);
router.post('/payments/webhook/chargily', paymentController.handleChargilyWebhook);

//HEALTH ALERT ROUTES
router.post('/health-alerts', authMiddleware, healthAlertController.createHealthAlert);
router.get('/health-alerts/me', authMiddleware, healthAlertController.getMyHealthAlerts);
router.get('/health-alerts/unread', authMiddleware, healthAlertController.getUnreadHealthAlerts);
router.put('/health-alerts/:id/read', authMiddleware, healthAlertController.markAlertAsRead);
router.put('/health-alerts/read-all', authMiddleware, healthAlertController.markAllAlertsAsRead);
router.delete('/health-alerts/:id', authMiddleware, healthAlertController.deleteHealthAlert);
router.get('/health-alerts/type/:alertType', authMiddleware, healthAlertController.getAlertsByType);
router.get('/health-alerts/date-range', authMiddleware, healthAlertController.getAlertsByDateRange);
router.get('/health-alerts/ai-generated', authMiddleware, healthAlertController.getAiGeneratedAlerts);
router.get('/health-alerts/statistics', authMiddleware, healthAlertController.getHealthAlertStatistics);
router.get('/health-alerts/type-statistics', authMiddleware, healthAlertController.getAlertTypeStatistics);

//ANALYTICS ROUTES (Admin only)
router.post('/analytics/diagnoses', authMiddleware, analyticsController.createAnonymizedDiagnosis);
router.get('/analytics/diagnoses', authMiddleware, analyticsController.getAllAnonymizedDiagnoses);
router.get('/analytics/diagnoses/condition/:condition', authMiddleware, analyticsController.getDiagnosesByCondition);
router.get('/analytics/diagnoses/age/:ageRange', authMiddleware, analyticsController.getDiagnosesByAgeRange);
router.get('/analytics/diagnoses/location', authMiddleware, analyticsController.getDiagnosesByLocation);
router.get('/analytics/diagnoses/symptoms', authMiddleware, analyticsController.getDiagnosesBySymptoms);
router.get('/analytics/diagnoses/source/:source', authMiddleware, analyticsController.getDiagnosesBySource);
router.get('/analytics/statistics/conditions', authMiddleware, analyticsController.getConditionStatistics);
router.get('/analytics/statistics/age-conditions', authMiddleware, analyticsController.getAgeConditionStatistics);
router.get('/analytics/statistics/common-symptoms', authMiddleware, analyticsController.getCommonSymptoms);
router.get('/analytics/statistics/regional', authMiddleware, analyticsController.getRegionalStatistics);
router.get('/analytics/statistics/outcomes', authMiddleware, analyticsController.getOutcomeStatistics);
router.get('/analytics/summary', authMiddleware, analyticsController.getSummary);

//ORDER ROUTES
router.post('/medication-orders', authMiddleware, orderController.upload.single('prescription'), orderController.createMedicationOrder);
router.get('/medication-orders/me', authMiddleware, orderController.getMyOrders);
router.get('/pharmacy/orders', authMiddleware, orderController.getPharmacyOrders);
router.put('/medication-orders/:id/status', authMiddleware, orderController.updateOrderStatus);

router.post('/lab-requests', authMiddleware, orderController.createLabRequest);
router.get('/lab-requests/me', authMiddleware, orderController.getMyLabRequests);
router.get('/lab/requests', authMiddleware, orderController.getLabRequests);

//MEDICAL RECORDS ROUTES
router.post('/medical-records', authMiddleware, medicalRecordController.upload.single('record'), medicalRecordController.createRecord);
router.get('/medical-records/me', authMiddleware, medicalRecordController.getMyRecords);
router.delete('/medical-records/:id', authMiddleware, medicalRecordController.deleteRecord);

//LAB ROUTES
router.get('/lab/:labId/services', authMiddleware, labController.getLabServices);
router.post('/lab/services', authMiddleware, labController.addLabService);
router.post('/lab/upload-result', authMiddleware, labController.upload.single('result'), labController.uploadTestResult);
router.get('/lab/results/:requestId', authMiddleware, labController.getTestResults);
router.put('/lab/requests/:requestId/status', authMiddleware, labController.updateRequestStatus);

//PHARMACY ROUTES
router.get('/pharmacy/:pharmacyId/inventory', authMiddleware, pharmacyController.getInventory);
router.post('/pharmacy/inventory', authMiddleware, pharmacyController.addInventoryItem);
router.put('/pharmacy/inventory/:itemId', authMiddleware, pharmacyController.updateInventoryItem);

//SYSTEM NOTIFICATIONS ROUTES
router.get('/notifications/me', authMiddleware, notificationController.getMyNotifications);
router.put('/notifications/:id/read', authMiddleware, notificationController.markAsRead);
router.put('/notifications/read-all', authMiddleware, notificationController.markAllAsRead);

//MEDICAL ROUTER ROUTES
router.post('/medical-router/recommend', authMiddleware, medicalRouterController.recommendSpecialty);

//DISEASE OBSERVATORY ROUTES
router.post('/disease-observatory/report', authMiddleware, diseaseObservatoryController.submitReport);
router.get('/disease-observatory/trends', diseaseObservatoryController.getTrends); // Public basic view
router.get('/disease-observatory/symptom-trends', authMiddleware, diseaseObservatoryController.getSymptomTrends); // For doctors
router.get('/disease-observatory/detailed-alerts', diseaseObservatoryController.getDetailedAlerts); // For patient detail screen
router.get('/disease-observatory/history', authMiddleware, diseaseObservatoryController.getHistory); // For doctor dashboard
router.post('/disease-observatory/increment/:id', authMiddleware, diseaseObservatoryController.incrementReport); // Quick clone
router.get('/disease-observatory/symptom-distribution', authMiddleware, diseaseObservatoryController.getSymptomDistribution); // Top symptoms
router.get('/disease-observatory/ai-preventive-advice', diseaseObservatoryController.getAIAdvice); // AI advice for patients

//NEW ADVANCED ROUTES

//Import route modules
const patientRoutes = require('./patient');
const doctorRoutes = require('./doctor');
const aiAdminRoutes = require('./aiAdmin');
const videoCallRoutes = require('./videoCalls');
const agoraRoutes = require('./agoraRoutes');

//Use route modules
router.use('/patient', patientRoutes);
router.use('/doctor', doctorRoutes);
router.use('/ai-admin', aiAdminRoutes);
router.use('/video-calls', videoCallRoutes);
router.use('/agora', agoraRoutes);
router.use('/payments', require('./paymentRoutes'));
router.use('/prescriptions', require('./prescriptionRoutes'));
router.use('/social-security', socialSecurityRoutes);

module.exports = router;
