const express = require('express');
const router = express.Router();
const prescriptionController = require('../controllers/prescriptionController');
const { authMiddleware } = require('../middlewares/auth');

//all prescription routes require authentication
router.use(authMiddleware);

//create a new prescription(Doctor only)
router.post('/', prescriptionController.createPrescription);

//get my prescriptions(Patient or Doctor)
router.get('/me', prescriptionController.getMyPrescriptions);

//get specific prescription details
router.get('/:id', prescriptionController.getPrescriptionById);

//verify prescription by code(for Pharmacists)
router.get('/verify/:code', prescriptionController.getPrescriptionByCode);

module.exports = router;
