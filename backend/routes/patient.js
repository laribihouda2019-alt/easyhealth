const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middlewares/auth');
const patientController = require('../controllers/patientController');

//apply auth middleware to all routes
router.use(authMiddleware);

//aI Symptom Analysis
router.post('/ai/analyze-symptoms', patientController.analyzeSymptoms);

//real Appointments
router.get('/appointments/availability/:doctorId', patientController.getDoctorAvailability);
router.post('/appointments', patientController.createRealAppointment);
router.get('/appointments', patientController.getMyAppointments);

//medication Management
router.post('/medications', patientController.addMedicationSchedule);
router.get('/medications', patientController.getMyMedications);
router.get('/medications/reminders/today', patientController.getTodaysReminders);
router.put('/medications/reminders/:reminderId/taken', patientController.markMedicationTaken);

module.exports = router;
