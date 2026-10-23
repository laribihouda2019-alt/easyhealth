const express = require('express');
const router = express.Router();
const socialSecurityController = require('../controllers/socialSecurityController');
const ssUploadController = require('../controllers/ssUploadController');
const { authMiddleware, requireRole } = require('../middlewares/auth');
const uploadController = require('../controllers/uploadController');
const { ROLES } = require('../config/constants');

const medicalRequestController = require('../controllers/medicalRequestController');

//PATIENT ROUTES
router.post(
  '/upload-documents',
  authMiddleware,
  requireRole(ROLES.PATIENT),
  ssUploadController.upload.array('documents', 5),
  ssUploadController.uploadDocuments
);

router.post(
  '/requests', 
  authMiddleware, 
  requireRole(ROLES.PATIENT), 
  socialSecurityController.submitRequest
);

router.get(
  '/requests/my', 
  authMiddleware, 
  requireRole(ROLES.PATIENT), 
  socialSecurityController.getPatientRequests
);

//MEDICAL REQUESTS(Medical Approval Workflow)
router.post(
  '/medical-requests',
  authMiddleware,
  requireRole(ROLES.PATIENT),
  medicalRequestController.upload.fields([
    { name: 'prescription', maxCount: 1 },
    { name: 'supportingDocs', maxCount: 5 }
  ]),
  medicalRequestController.createRequest
);

router.get(
  '/medical-requests/my',
  authMiddleware,
  requireRole(ROLES.PATIENT),
  medicalRequestController.getMyRequests
);

//MEDICAL CONTROLLER ROUTES
router.get(
  '/medical-requests/pending',
  authMiddleware,
  requireRole(ROLES.MEDICAL_CONTROLLER, ROLES.ADMIN),
  medicalRequestController.getPendingRequests
);

router.put(
  '/medical-requests/:requestId/review',
  authMiddleware,
  requireRole(ROLES.MEDICAL_CONTROLLER, ROLES.ADMIN),
  medicalRequestController.reviewRequest
);

//SOCIAL SECURITY AGENT ROUTES
router.get(
  '/requests/all', 
  authMiddleware, 
  requireRole(ROLES.SOCIAL_SECURITY, ROLES.ADMIN), 
  socialSecurityController.getAllRequests
);

router.put(
  '/requests/:id/status', 
  authMiddleware, 
  requireRole(ROLES.SOCIAL_SECURITY, ROLES.ADMIN), 
  socialSecurityController.updateRequestStatus
);

router.get(
  '/stats', 
  authMiddleware, 
  requireRole(ROLES.SOCIAL_SECURITY, ROLES.ADMIN), 
  socialSecurityController.getStats
);

module.exports = router;
