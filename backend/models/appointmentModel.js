const db = require('../config/db');

async function checkOverlappingAppointments(doctorId, startTime, endTime) {
  const { rows } = await db.query(
    `SELECT id FROM public.real_appointments
     WHERE doctor_id = $1
       AND status != 'cancelled'
       AND (
         (scheduled_at < $3 AND scheduled_at + (duration_minutes || ' minutes')::interval > $2)
       )`,
    [doctorId, startTime, endTime]
  );
  return rows.length > 0;
}

async function createAppointment({
  patientId,
  doctorId,
  appointmentType,
  scheduledAt,
  durationMinutes,
  location,
  meetingUrl,
  notes,
}) {
  const { rows } = await db.query(
    `insert into public.real_appointments
      (patient_id, doctor_id, appointment_type, scheduled_at, duration_minutes, location, meeting_url, notes)
     values ($1,$2,$3,$4,$5,$6,$7,$8)
     returning *`,
    [patientId, doctorId, appointmentType, scheduledAt, durationMinutes, location, meetingUrl, notes]
  );
  return rows[0];
}

async function updateAppointmentStatus(id, status) {
  const { rows } = await db.query(
    'update public.real_appointments set status = $2 where id = $1 returning *',
    [id, status]
  );
  return rows[0] || null;
}

module.exports = {
  createAppointment,
  updateAppointmentStatus,
  checkOverlappingAppointments,
};

