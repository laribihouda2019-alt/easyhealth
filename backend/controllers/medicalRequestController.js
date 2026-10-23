const db = require('../config/db');
const { ROLES } = require('../config/constants');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

//configure multer for medical documents
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const dir = 'uploads/medical_requests';
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    cb(null, dir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, 'doc-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ storage: storage });

//patient creates a medical request
 
async function createRequest(req, res, next) {
  try {
    const patientId = req.user.id;
    const { requestType, description } = req.body;
    
    //req.files should contain 'prescription' and 'supportingDocs'
    const prescriptionFile = req.files['prescription'] ? req.files['prescription'][0] : null;
    const supportingFiles = req.files['supportingDocs'] || [];
    
    if (!prescriptionFile) {
      return res.status(400).json({ error: 'Prescription is required' });
    }
    
    const prescriptionUrl = `/uploads/medical_requests/${prescriptionFile.filename}`;
    const supportingUrls = supportingFiles.map(file => `/uploads/medical_requests/${file.filename}`);
    
    const { rows } = await db.query(
      `INSERT INTO public.medical_requests (patient_id, request_type, description, prescription_url, supporting_docs_url)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [patientId, requestType, description, prescriptionUrl, supportingUrls]
    );
    
    res.status(201).json({ success: true, data: rows[0] });
  } catch (err) {
    next(err);
  }
}

//patient gets their own requests
 
async function getMyRequests(req, res, next) {
  try {
    const patientId = req.user.id;
    const { rows } = await db.query(
      `SELECT r.*, p.full_name as patient_name 
       FROM public.medical_requests r
       JOIN public.profiles p ON r.patient_id = p.id
       WHERE r.patient_id = $1
       ORDER BY r.created_at DESC`,
      [patientId]
    );
    res.json({ success: true, data: rows });
  } catch (err) {
    next(err);
  }
}

//controller gets all pending requests
 
async function getPendingRequests(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT r.*, p.full_name as patient_name, p.email as patient_email
       FROM public.medical_requests r
       JOIN public.profiles p ON r.patient_id = p.id
       WHERE r.status = 'pending'
       ORDER BY r.created_at ASC`
    );
    res.json({ success: true, data: rows });
  } catch (err) {
    next(err);
  }
}

//controller reviews a request
 
async function reviewRequest(req, res, next) {
  try {
    const controllerId = req.user.id;
    const { requestId } = req.params;
    const { status, comment } = req.body;
    
    if (!['approved', 'rejected'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status. Must be approved or rejected.' });
    }
    
    const { rows } = await db.query(
      `UPDATE public.medical_requests 
       SET status = $1, controller_id = $2, controller_comment = $3, updated_at = NOW()
       WHERE id = $4
       RETURNING *`,
      [status, controllerId, comment, requestId]
    );
    
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Request not found' });
    }
    
    res.json({ success: true, data: rows[0] });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  upload,
  createRequest,
  getMyRequests,
  getPendingRequests,
  reviewRequest
};
