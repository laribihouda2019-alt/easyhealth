const appointmentModel = require('../models/appointmentModel');

async function bookAppointment(payload) {
  const { doctorId, scheduledAt, durationMinutes } = payload;
  if (!scheduledAt) throw new Error('scheduledAt is required');

  const startTime = new Date(scheduledAt);
  const endTime = new Date(startTime.getTime() + (durationMinutes || 30) * 60000);

  const hasOverlap = await appointmentModel.checkOverlappingAppointments(
    doctorId,
    startTime.toISOString(),
    endTime.toISOString()
  );

  if (hasOverlap) {
    const error = new Error('Ce créneau horaire est déjà réservé.');
    error.status = 409;
    throw error;
  }

  return appointmentModel.createAppointment(payload);
}

async function changeAppointmentStatus(id, status) {
  return appointmentModel.updateAppointmentStatus(id, status);
}

module.exports = {
  bookAppointment,
  changeAppointmentStatus,
};


