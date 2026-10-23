const db = require('../config/db');

async function getProfileById(id) {
  const { rows } = await db.query(
    'select id, full_name, email, phone, role, is_approved, metadata, avatar_url, COALESCE(wilaya, metadata->>\'wilaya\') as wilaya, COALESCE(commune, metadata->>\'commune\') as commune, COALESCE(address, metadata->>\'address\') as address, consultation_fee, specialty, logo_url from public.profiles where id = $1',
    [id]
  );
  return rows[0] || null;
}

async function updateProfile(id, { full_name, email, phone, avatar_url, metadata, wilaya, commune, consultation_fee, specialty, logo_url }) {
  const { rows } = await db.query(
    `UPDATE public.profiles 
     SET full_name = COALESCE($1, full_name), 
         email = COALESCE($2, email), 
         phone = COALESCE($3, phone), 
         avatar_url = COALESCE($4, avatar_url), 
         metadata = COALESCE($5, metadata),
         wilaya = COALESCE($6, wilaya),
         commune = COALESCE($7, commune),
         consultation_fee = COALESCE($8, consultation_fee),
         specialty = COALESCE($9, specialty),
         logo_url = COALESCE($10, logo_url),
         updated_at = NOW()
     WHERE id = $11 
     RETURNING *`,
    [full_name, email, phone, avatar_url, metadata, wilaya, commune, consultation_fee, specialty, logo_url, id]
  );
  return rows[0] || null;
}

async function getProfilesByRole(role) {
  const { rows } = await db.query(
    'SELECT id, full_name, email, phone, role, is_approved, avatar_url, metadata, COALESCE(wilaya, metadata->>\'wilaya\') as wilaya, COALESCE(commune, metadata->>\'commune\') as commune, COALESCE(address, metadata->>\'address\') as address FROM public.profiles WHERE role = $1',
    [role]
  );
  return rows;
}

async function searchProfiles(query, commune) {
  let sql = `SELECT id, full_name, role, avatar_url, metadata, COALESCE(wilaya, metadata->>\'wilaya\') as wilaya, COALESCE(commune, metadata->>\'commune\') as commune, COALESCE(address, metadata->>\'address\') as address 
             FROM public.profiles 
             WHERE is_approved = true`;
  const params = [];

  if (query) {
    params.push(`%${query}%`);
    sql += ` AND (full_name ILIKE $${params.length} OR email ILIKE $${params.length})`;
  }

  if (commune) {
    params.push(commune);
    sql += ` AND (commune = $${params.length} OR metadata->>'commune' = $${params.length})`;
  }

  const { rows } = await db.query(sql, params);
  return rows;
}

async function updateApprovalStatus(id, isApproved) {
  const { rows } = await db.query(
    'update public.profiles set is_approved = $2, updated_at = NOW() where id = $1 returning id, role, is_approved',
    [id, isApproved]
  );
  return rows[0] || null;
}

async function getProfileStats(id, role) {
  if (role === 'doctor') {
    const { rows } = await db.query(
      'SELECT COUNT(*) as count FROM public.health_reports WHERE doctor_id = $1',
      [id]
    );
    return { reportsCount: parseInt(rows[0].count) };
  } else if (role === 'patient') {
    const { rows } = await db.query(
      'SELECT COUNT(*) as count FROM public.ai_symptom_analyses WHERE patient_id = $1',
      [id]
    );
    return { aiConsultationsCount: parseInt(rows[0].count) };
  }
  return {};
}

module.exports = {
  getProfileById,
  updateProfile,
  getProfilesByRole,
  searchProfiles,
  updateApprovalStatus,
  getProfileStats,
};
