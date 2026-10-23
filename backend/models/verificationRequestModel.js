const db = require('../config/db');

async function createVerificationRequest({
  userId,
  roleRequested,
  documentType,
  documentUrl,
  ocrRawData,
  extractedFields,
}) {
  const { rows } = await db.query(
    `insert into public.verification_requests
      (user_id, role_requested, document_type, document_url, ocr_raw_data, extracted_fields)
     values ($1,$2,$3,$4,$5,$6)
     returning *`,
    [userId, roleRequested, documentType, documentUrl, ocrRawData, extractedFields]
  );
  return rows[0];
}

async function updateVerificationStatus(id, { status, aiConfidence, adminNotes, reviewedBy }) {
  const { rows } = await db.query(
    `update public.verification_requests
     set verification_status = $2,
         ai_confidence = $3,
         admin_notes = $4,
         reviewed_by = $5,
         reviewed_at = now()
     where id = $1
     returning *`,
    [id, status, aiConfidence, adminNotes, reviewedBy]
  );
  return rows[0] || null;
}

module.exports = {
  createVerificationRequest,
  updateVerificationStatus,
};

