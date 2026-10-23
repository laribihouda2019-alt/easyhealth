const verificationService = require('../services/verificationService');

async function createVerificationRequest(req, res, next) {
  try {
    const { roleRequested, documentType, documentUrl, ocrRawData, extractedFields } = req.body;

    const request = await verificationService.createVerificationRequest({
      userId: req.user.id,
      roleRequested,
      documentType,
      documentUrl,
      ocrRawData,
      extractedFields,
    });

    res.status(201).json(request);
  } catch (err) {
    next(err);
  }
}

async function reviewVerificationRequest(req, res, next) {
  try {
    const { id } = req.params;
    const { status, adminNotes } = req.body;

    const updated = await verificationService.reviewVerificationRequest(id, {
      status,
      adminId: req.user.id,
      adminNotes,
    });

    res.json(updated);
  } catch (err) {
    next(err);
  }
}

async function getMyVerificationRequests(req, res, next) {
  try {
    const requests = await verificationService.getUserVerificationRequests(req.user.id);
    res.json(requests);
  } catch (err) {
    next(err);
  }
}

async function getVerificationRequestById(req, res, next) {
  try {
    const { id } = req.params;
    const request = await verificationService.getVerificationRequestById(id);
    res.json(request);
  } catch (err) {
    next(err);
  }
}

async function getPendingVerificationRequests(req, res, next) {
  try {
    const requests = await verificationService.getPendingVerificationRequests();
    res.json(requests);
  } catch (err) {
    next(err);
  }
}

async function getVerificationRequestsByStatus(req, res, next) {
  try {
    const { status } = req.params;
    const requests = await verificationService.getVerificationRequestsByStatus(status);
    res.json(requests);
  } catch (err) {
    next(err);
  }
}

async function updateAIAnalysis(req, res, next) {
  try {
    const { id } = req.params;
    const { ocrRawData, extractedFields, aiConfidence } = req.body;
    
    const updated = await verificationService.updateAIAnalysis(id, req.user.id, {
      ocrRawData,
      extractedFields,
      aiConfidence,
    });
    
    res.json(updated);
  } catch (err) {
    next(err);
  }
}

async function getVerificationRequestsByRole(req, res, next) {
  try {
    const { role } = req.params;
    const requests = await verificationService.getVerificationRequestsByRole(role);
    res.json(requests);
  } catch (err) {
    next(err);
  }
}

async function checkPendingVerification(req, res, next) {
  try {
    const request = await verificationService.checkPendingVerification(req.user.id);
    res.json(request);
  } catch (err) {
    next(err);
  }
}

async function getVerificationStatistics(req, res, next) {
  try {
    const stats = await verificationService.getVerificationStatistics();
    res.json(stats);
  } catch (err) {
    next(err);
  }
}

module.exports = {
  createVerificationRequest,
  reviewVerificationRequest,
  getMyVerificationRequests,
  getVerificationRequestById,
  getPendingVerificationRequests,
  getVerificationRequestsByStatus,
  updateAIAnalysis,
  getVerificationRequestsByRole,
  checkPendingVerification,
  getVerificationStatistics,
};

