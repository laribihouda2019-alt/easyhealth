const verificationModel = require('../models/verificationRequestModel');
const profileService = require('./profileService');
const aiVerificationService = require('./aiVerificationService');

async function createVerificationRequest(payload) {
  const request = await verificationModel.createVerificationRequest(payload);

  aiVerificationService
    .analyzeVerificationRequest(request)
    .catch((err) => console.error('AI verification error', err));

  return request;
}

async function reviewVerificationRequest(id, { status, adminId, adminNotes }) {
  const aiData = await aiVerificationService.suggestApproval(id);

  const updated = await verificationModel.updateVerificationStatus(id, {
    status,
    aiConfidence: aiData?.confidence ?? null,
    adminNotes: adminNotes ?? aiData?.explanation ?? null,
    reviewedBy: adminId,
  });

  if (updated && status === 'approved') {
    await profileService.setApproval(updated.user_id, true);
  }

  return updated;
}

module.exports = {
  createVerificationRequest,
  reviewVerificationRequest,
};


