const appointmentService = require('../services/appointmentService');
const { sendToUser } = require('../services/socketService');
const { createNotification } = require('./notificationController');

async function createAppointment(req, res, next) {
  try {
    const {
      doctorId,
      appointmentType,
      scheduledAt,
      durationMinutes,
      location,
      meetingUrl,
      notes,
    } = req.body;

    const appointment = await appointmentService.bookAppointment({
      patientId: req.user.id,
      doctorId,
      appointmentType,
      scheduledAt,
      durationMinutes,
      location,
      meetingUrl,
      notes,
    });

    //notify Doctor of new appointment
    await createNotification(
        doctorId,
        'Nouveau rendez-vous',
        'Un nouveau rendez-vous a été réservé',
        'appointment',
        appointment.id.toString()
    );

    res.status(201).json(appointment);
  } catch (err) {
    next(err);
  }
}

async function updateAppointmentStatus(req, res, next) {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const updated = await appointmentService.changeAppointmentStatus(id, status);
    
    //notify Patient of status update if it exists
    if (updated && updated.patient_id) {
        await createNotification(
            updated.patient_id,
            'Statut du rendez-vous',
            `Le statut de votre rendez-vous est maintenant: ${status}`,
            'appointment_status',
            updated.id.toString()
        );
    }

    res.json(updated);
  } catch (err) {
    next(err);
  }
}

async function getMyAppointments(req, res, next) {
  try {
    const appointments = await appointmentService.getUserAppointments(req.user.id);
    res.json(appointments);
  } catch (err) {
    next(err);
  }
}

async function getAppointmentById(req, res, next) {
  try {
    const { id } = req.params;
    const appointment = await appointmentService.getAppointmentById(id);
    res.json(appointment);
  } catch (err) {
    next(err);
  }
}

async function updateAppointment(req, res, next) {
  try {
    const { id } = req.params;
    const { scheduledAt, durationMinutes, location, meetingUrl, notes } = req.body;
    const updated = await appointmentService.updateAppointment(id, {
      scheduledAt,
      durationMinutes,
      location,
      meetingUrl,
      notes,
    });
    res.json(updated);
  } catch (err) {
    next(err);
  }
}

async function getUpcomingAppointments(req, res, next) {
  try {
    const appointments = await appointmentService.getUpcomingAppointments(req.user.id);
    res.json(appointments);
  } catch (err) {
    next(err);
  }
}

async function getDoctorSchedule(req, res, next) {
  try {
    const { doctorId } = req.params;
    const { startDate, endDate } = req.query;
    const appointments = await appointmentService.getDoctorSchedule(doctorId, startDate, endDate);
    res.json(appointments);
  } catch (err) {
    next(err);
  }
}

module.exports = {
  createAppointment,
  updateAppointmentStatus,
  getMyAppointments,
  getAppointmentById,
  updateAppointment,
  getUpcomingAppointments,
  getDoctorSchedule,
};

