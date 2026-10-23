const db = require('../config/db');
const { ROLES } = require('../config/constants');

//submit a Chifa card reactivation request(Patient)
 
async function submitRequest(req, res) {
  try {
    const { id: patientId } = req.user;
    const { notes } = req.body;
    
    //we assume provide a list of URLs in the body or handle via middleware later
    const { documentUrls } = req.body;

    if (!documentUrls || !Array.isArray(documentUrls) || documentUrls.length === 0) {
      return res.status(400).json({ error: 'Documents required' });
    }

    const query = `
      INSERT INTO public.social_security_requests (patient_id, document_urls, notes)
      VALUES ($1, $2, $3)
      RETURNING *
    `;

    const result = await db.query(query, [patientId, documentUrls, notes]);

    res.status(201).json({
      success: true,
      message: 'Request submitted successfully',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Submit SS Request error:', error);
    res.status(500).json({ error: 'Failed to submit request', details: error.message });
  }
}

//get current patient's requests
 
async function getPatientRequests(req, res) {
  try {
    const { id: patientId } = req.user;

    const result = await db.query(
      'SELECT * FROM public.social_security_requests WHERE patient_id = $1 ORDER BY created_at DESC',
      [patientId]
    );

    res.status(200).json({ success: true, data: result.rows });
  } catch (error) {
    console.error('Get Patient Requests error:', error);
    res.status(500).json({ error: 'Failed to fetch requests' });
  }
}

//get all requests(SS Agent)
 
async function getAllRequests(req, res) {
  try {
    const query = `
      SELECT r.*, p.full_name as patient_name, p.email as patient_email
      FROM public.social_security_requests r
      JOIN public.profiles p ON r.patient_id = p.id
      ORDER BY r.created_at DESC
    `;
    
    const result = await db.query(query);
    res.status(200).json({ success: true, data: result.rows });
  } catch (error) {
    console.error('Get All Requests error:', error);
    res.status(500).json({ error: 'Failed to fetch requests' });
  }
}

//update request status(SS Agent)
 
async function updateRequestStatus(req, res) {
  try {
    const { id } = req.params;
    const { status, rejectionReason } = req.body;

    if (!['Acceptée', 'Rejetée'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }

    const query = `
      UPDATE public.social_security_requests
      SET status = $1, rejection_reason = $2, updated_at = NOW()
      WHERE id = $3
      RETURNING *
    `;

    const result = await db.query(query, [status, rejectionReason, id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Request not found' });
    }

    res.status(200).json({
      success: true,
      message: `Request ${status.toLowerCase()}`,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Update Request Status error:', error);
    res.status(500).json({ error: 'Failed to update request' });
  }
}

//get quick statistics(SS Agent)
 
async function getStats(req, res) {
  try {
    const pendingQuery = "SELECT count(*) FROM public.social_security_requests WHERE status = 'En cours'";
    const totalQuery = "SELECT count(*) FROM public.social_security_requests";

    const [pendingRes, totalRes] = await Promise.all([
      db.query(pendingQuery),
      db.query(totalQuery)
    ]);

    res.status(200).json({
      success: true,
      stats: {
        pendingRequests: parseInt(pendingRes.rows[0].count),
        totalRequests: parseInt(totalRes.rows[0].count)
      }
    });
  } catch (error) {
    console.error('Get SS Stats error:', error);
    res.status(500).json({ error: 'Failed to fetch statistics' });
  }
}

module.exports = {
  submitRequest,
  getPatientRequests,
  getAllRequests,
  updateRequestStatus,
  getStats
};
