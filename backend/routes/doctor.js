const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middlewares/auth');
const doctorController = require('../controllers/doctorController');

//apply auth middleware to all routes
router.use(authMiddleware);

//appointments Management
router.get('/appointments', doctorController.getDoctorAppointments);
router.put('/appointments/:appointmentId/status', doctorController.updateAppointmentStatus);
router.get('/appointments/today', doctorController.getTodaysAppointments);

//availability Management
const availabilityController = require('../controllers/availabilityController');
router.post('/availability-slots', availabilityController.addAvailabilitySlots);
router.get('/availability-slots', availabilityController.getDoctorSlots);
router.delete('/availability-slots/:id', availabilityController.deleteSlot);

//legacy Availability (Day of week based)
router.post('/availability', doctorController.setAvailability);
router.get('/availability', doctorController.getMyAvailability);

//disease Observations
router.post('/disease-observations', doctorController.recordDiseaseObservation);
router.get('/disease-observations', doctorController.getMyDiseaseObservations);

//statistics and Analytics
router.get('/statistics/diseases', doctorController.getDiseaseStatistics);
router.get('/statistics/symptoms', doctorController.getCommonSymptoms);

//patient Medical Records (Scanning)
router.get('/patient/:patientId/medical-records', doctorController.getPatientMedicalRecords);

module.exports = router;
