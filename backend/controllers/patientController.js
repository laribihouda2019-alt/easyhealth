const db = require('../config/db');
const { v4: uuidv4 } = require('uuid');
const { sendToUser } = require('../services/socketService');

//patient describes symptoms to AI, AI analyzes and recommends specialist

async function analyzeSymptoms(req, res, next) {
  try {
    const { symptomsDescription } = req.body;
    const patientId = req.user.id;

    if (!symptomsDescription) {
      return res.status(400).json({ error: 'Symptoms description is required' });
    }

    //simulate AI analysis (in real app, this would call AI service)
    const aiAnalysis = await performAIAnalysis(symptomsDescription);

    //save analysis to database
    const result = await db.query(
      `INSERT INTO ai_symptom_analyses 
       (patient_id, symptoms_description, ai_analysis, recommended_specialization, confidence_score)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [
        patientId,
        symptomsDescription,
        JSON.stringify(aiAnalysis),
        aiAnalysis.recommendedSpecialization,
        aiAnalysis.confidenceScore
      ]
    );

    //find recommended doctors
    let recommendedDoctors = [];
    if (aiAnalysis.recommendedSpecialization) {
      const doctorsQuery = await db.query(
        `SELECT id, full_name, specialization, avatar_url 
         FROM profiles 
         WHERE role = 'doctor' AND is_approved = true 
         AND specialization ILIKE $1
         LIMIT 3`,
        [`%${aiAnalysis.recommendedSpecialization}%`]
      );
      recommendedDoctors = doctorsQuery.rows;
    }

    res.status(201).json({
      success: true,
      analysis: result.rows[0],
      recommendedDoctors,
      message: aiAnalysis.message
    });

  } catch (error) {
    console.error('Symptom analysis error:', error.message);
    const status = error.message.includes('Quota') || error.message.includes('surcharge') ? 429 : 500;
    res.status(status).json({
      success: false,
      error: error.message || 'Erreur lors de l\'analyse des symptômes'
    });
  }
}

//get Real Appointments with Doctor Availability
 
async function getDoctorAvailability(req, res, next) {
  try {
    const { doctorId } = req.params;
    const { date } = req.query;

    if (!doctorId) {
      return res.status(400).json({ error: 'Doctor ID is required' });
    }

    //fetch slots from new availability_slots table
    let query = `
      SELECT * FROM availability_slots 
      WHERE doctor_id = $1::uuid 
      AND status = 'available'
      AND start_time >= NOW()
    `;
    const params = [doctorId];

    if (date) {
      query += ` AND DATE(start_time) = $2`;
      params.push(date);
    }
    
    query += ` ORDER BY start_time ASC`;

    const { rows: availabilitySlots } = await db.query(query, params);

    res.json({
      success: true,
      availableSlots: availabilitySlots,
      date: date || new Date().toISOString().split('T')[0]
    });

  } catch (error) {
    console.error('Get availability error:', error);
    next(error);
  }
}

//create Real Appointment
 
async function createRealAppointment(req, res, next) {
  try {
    const { doctorId, slotId, appointmentType, notes, symptomsDescription, patientName: bodyPatientName, doctorName: bodyDoctorName } = req.body;
    const patientId = req.user.id;

    if (!doctorId || !slotId) {
      return res.status(400).json({ error: 'Doctor ID and Slot ID are required' });
    }

    //verify and lock the slot
    const slotCheck = await db.query(
      `SELECT * FROM availability_slots WHERE id = $1 AND doctor_id = $2 AND status = 'available'`,
      [slotId, doctorId]
    );

    if (slotCheck.rows.length === 0) {
      return res.status(409).json({ error: 'This time slot is no longer available' });
    }

    const slot = slotCheck.rows[0];
    const scheduledAt = slot.start_time;
    const durationMinutes = Math.round((new Date(slot.end_time) - new Date(slot.start_time)) / 60000);

    //update slot status to booked
    await db.query(
      `UPDATE availability_slots SET status = 'booked', updated_at = NOW() WHERE id = $1`,
      [slotId]
    );

    //get AI analysis if symptoms provided (starts as null — no undefined variable)
    let finalAiAnalysis = null;
    if (symptomsDescription) {
      const analysisResult = await performAIAnalysis(symptomsDescription);
      finalAiAnalysis = JSON.stringify(analysisResult);
    }

    console.log('[DEBUG] createRealAppointment - patientId:', patientId, 'doctorId:', doctorId);
    console.log('[DEBUG] createRealAppointment - scheduledAt:', scheduledAt);

    //get patient name (use body value or fetch from DB)
    let patientName = bodyPatientName;
    if (!patientName) {
      const patientQuery = await db.query(
        'SELECT full_name FROM profiles WHERE id = $1',
        [patientId]
      );
      patientName = patientQuery.rows[0]?.full_name || 'Anonyme';
    }

    //get doctor details (use body value or fetch from DB) — declared here so it's in scope below
    let doctorName = bodyDoctorName;
    let doctorRow = null;
    if (!doctorName) {
      const doctorQuery = await db.query(
        'SELECT full_name, specialization FROM profiles WHERE id = $1',
        [doctorId]
      );
      doctorRow = doctorQuery.rows[0] || null;
      doctorName = doctorRow?.full_name || 'Médecin';
    }

    //create appointment
    const result = await db.query(
      `INSERT INTO real_appointments 
       (patient_id, doctor_id, slot_id, appointment_type, scheduled_at, duration_minutes, notes, symptoms_description, ai_analysis)
       VALUES ($1::uuid, $2::uuid, $3, $4, $5, $6, $7, $8, $9)
       RETURNING *`,
      [
        patientId,
        doctorId,
        slotId,
        appointmentType || 'consultation',
        scheduledAt,
        durationMinutes,
        notes,
        symptomsDescription,
        finalAiAnalysis
      ]
    );

    const appointment = result.rows[0];
    appointment.doctor = doctorRow;   //safe always in scope now
    appointment.patient_name = patientName;   //add for frontend consistency
    appointment.doctor_name = doctorName;

    //create notification for doctor
    try {
      await db.query(
        `INSERT INTO health_alerts 
         (user_id, alert_type, title, body, sent_by_ai, metadata)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [
          doctorId,
          'new_appointment',
          'Nouveau Rendez-vous',
          `Nouveau rendez-vous le ${new Date(scheduledAt).toLocaleDateString('fr-FR')} à ${new Date(scheduledAt).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })}`,
          false,
          JSON.stringify({ appointmentId: appointment.id, patientId })
        ]
      );
    } catch (notifErr) {
      console.warn('Notification insert failed (non-fatal):', notifErr.message);
    }

    //notify doctor via Socket.io
    sendToUser(doctorId, 'new_appointment', {
      appointment: appointment,
      patientId: patientId
    });

    res.status(201).json({
      success: true,
      appointment,
      message: 'Rendez-vous créé avec succès'
    });

  } catch (error) {
    console.error('Create appointment error:', error);
    next(error);
  }
}

//get Patient's Appointments
 
async function getMyAppointments(req, res, next) {
  try {
    const patientId = req.user.id;
    const { status, upcoming } = req.query;

    let query = `
      SELECT ra.id, ra.doctor_id, ra.patient_id, ra.scheduled_at, ra.status, 
             ra.appointment_type, ra.duration_minutes, ra.location, ra.meeting_url, 
             ra.notes, ra.created_at,
             p_doctor.full_name as doctor_name, 
             p_doctor.specialization as doctor_specialization,
             p_doctor.avatar_url as doctor_avatar,
             p_patient.full_name as patient_name

      FROM real_appointments ra
      LEFT JOIN profiles p_doctor ON ra.doctor_id = p_doctor.id
      LEFT JOIN profiles p_patient ON ra.patient_id = p_patient.id
      WHERE ra.patient_id = $1::uuid
    `;

    const params = [patientId];

    if (status) {
      query += ` AND ra.status = $${params.length + 1}`;
      params.push(status);
    }

    if (upcoming === 'true') {
      query += ` AND ra.scheduled_at >= NOW() AND ra.status IN ('pending', 'confirmed')`;
    }

    query += ` ORDER BY ra.scheduled_at ASC`;

    const result = await db.query(query, params);

    res.json({
      success: true,
      appointments: result.rows
    });

  } catch (error) {
    console.error('Get appointments error:', error);
    next(error);
  }
}

//medication Management
 
async function addMedicationSchedule(req, res, next) {
  try {
    const {
      medicineName,
      dosage,
      frequency,
      startDate,
      endDate,
      reminderTimes,
      notes
    } = req.body;
    const patientId = req.user.id;

    if (!medicineName || !frequency || !startDate || !reminderTimes || reminderTimes.length === 0) {
      return res.status(400).json({ error: 'Medication name, frequency, start date, and reminder times are required' });
    }

    const result = await db.query(
      `INSERT INTO medication_schedules 
       (patient_id, medicine_name, dosage, frequency, start_date, end_date, reminder_times, notes)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [
        patientId,
        medicineName,
        dosage,
        frequency,
        startDate,
        endDate,
        reminderTimes,
        notes
      ]
    );

    //create reminders for the next 30 days
    await createMedicationReminders(result.rows[0].id, patientId, reminderTimes, startDate, endDate);

    res.status(201).json({
      success: true,
      medication: result.rows[0],
      message: 'Médicament ajouté avec succès'
    });

  } catch (error) {
    console.error('Add medication error:', error);
    next(error);
  }
}

//get Patient's Medications
 
async function getMyMedications(req, res, next) {
  try {
    const patientId = req.user.id;
    const { active } = req.query;

    let query = 'SELECT * FROM medication_schedules WHERE patient_id = $1';
    const params = [patientId];

    if (active === 'true') {
      query += ` AND is_active = true AND (end_date IS NULL OR end_date >= CURRENT_DATE)`;
    }

    query += ' ORDER BY created_at DESC';

    const result = await db.query(query, params);

    res.json({
      success: true,
      medications: result.rows
    });

  } catch (error) {
    console.error('Get medications error:', error);
    next(error);
  }
}

//get Today's Medication Reminders
 
async function getTodaysReminders(req, res, next) {
  try {
    const patientId = req.user.id;
    const today = new Date().toISOString().split('T')[0];

    const result = await db.query(
      `SELECT mr.*, ms.medicine_name, ms.dosage, ms.frequency
       FROM medication_reminders mr
       JOIN medication_schedules ms ON mr.medication_schedule_id = ms.id
       WHERE mr.patient_id = $1 AND mr.reminder_date = $2
       ORDER BY mr.reminder_time`,
      [patientId, today]
    );

    res.json({
      success: true,
      reminders: result.rows
    });

  } catch (error) {
    console.error('Get reminders error:', error);
    next(error);
  }
}

//mark Medication as Taken
 
async function markMedicationTaken(req, res, next) {
  try {
    const { reminderId } = req.params;
    const patientId = req.user.id;

    const result = await db.query(
      `UPDATE medication_reminders 
       SET is_taken = true, taken_at = NOW()
       WHERE id = $1 AND patient_id = $2
       RETURNING *`,
      [reminderId, patientId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Reminder not found' });
    }

    res.json({
      success: true,
      reminder: result.rows[0],
      message: 'Médicament marqué comme pris'
    });

  } catch (error) {
    console.error('Mark medication taken error:', error);
    next(error);
  }
}

//helper Functions
async function performAIAnalysis(symptoms) {
  try {
    const medicalRouterService = require('../services/medicalRouterService');
    const recommendation = await medicalRouterService.routeSymptoms(symptoms);

    return {
      recommendedSpecialization: recommendation.specialty,
      confidenceScore: 85,     //gemini provides generally high confidence
      message: recommendation.advice,
      keywords: extractKeywords(symptoms),
      severity: assessSeverity(symptoms),
      urgency: assessUrgency(symptoms)
    };
  } catch (error) {
    console.error('AI Analysis failed:', error.message);
    throw new Error('Le service d\'Intelligence Artificielle est temporairement indisponible (Quota atteint ou surcharge). Veuillez réessayer plus tard.');
  }
}

function fallbackAnalysis(symptoms) {
  const symptomsLower = symptoms.toLowerCase();
  let recommendedSpecialization = 'Médecin généraliste';
  let confidenceScore = 50;

  if (symptomsLower.includes('cœur') || symptomsLower.includes('douleur thoracique')) {
    recommendedSpecialization = 'Cardiologue';
    confidenceScore = 70;
  } else if (symptomsLower.includes('peau')) {
    recommendedSpecialization = 'Dermatologue';
    confidenceScore = 70;
  }

  return {
    recommendedSpecialization,
    confidenceScore,
    message: `(Fallback) Suggestion: ${recommendedSpecialization}`,
    keywords: extractKeywords(symptoms),
    severity: assessSeverity(symptoms),
    urgency: assessUrgency(symptoms)
  };
}

function extractKeywords(text) {
  const keywords = [];
  const symptomKeywords = ['douleur', 'fièvre', 'fatigue', 'nausée', 'toux', 'maux', 'symptôme', 'malaise'];

  symptomKeywords.forEach(keyword => {
    if (text.toLowerCase().includes(keyword)) {
      keywords.push(keyword);
    }
  });

  return keywords;
}

function assessSeverity(text) {
  const severeKeywords = ['intense', 'insupportable', 'urgence', 'grave', 'critique'];
  const textLower = text.toLowerCase();

  return severeKeywords.some(keyword => textLower.includes(keyword)) ? 'high' : 'moderate';
}

function assessUrgency(text) {
  const urgentKeywords = ['urgence', 'immédiat', 'rapide', 'aussitôt'];
  const textLower = text.toLowerCase();

  return urgentKeywords.some(keyword => textLower.includes(keyword)) ? 'high' : 'normal';
}

function calculateAvailableSlots(startTime, endTime, durationMinutes, existingAppointments) {
  const slots = [];
  const start = new Date(`2000-01-01T${startTime}`);
  const end = new Date(`2000-01-01T${endTime}`);
  const duration = durationMinutes * 60 * 1000; // Convert to milliseconds

  let currentSlot = new Date(start);

  while (currentSlot.getTime() + duration <= end.getTime()) {
    const slotEnd = new Date(currentSlot.getTime() + duration);

    //check if slot conflicts with existing appointments
    const hasConflict = existingAppointments.some(apt => {
      const aptStart = new Date(apt.scheduled_at);
      const aptEnd = new Date(aptStart.getTime() + (apt.duration_minutes * 60 * 1000));

      return (currentSlot < aptEnd && slotEnd > aptStart);
    });

    if (!hasConflict) {
      slots.push({
        start: currentSlot.toTimeString().slice(0, 5),
        end: slotEnd.toTimeString().slice(0, 5),
        available: true
      });
    }

    currentSlot = new Date(currentSlot.getTime() + duration);
  }

  return slots;
}

async function createMedicationReminders(medicationScheduleId, patientId, reminderTimes, startDate, endDate) {
  const start = new Date(startDate);
  const end = endDate ? new Date(endDate) : new Date(start.getTime() + 30 * 24 * 60 * 60 * 1000); // 30 days from start

  for (let date = new Date(start); date <= end; date.setDate(date.getDate() + 1)) {
    for (const reminderTime of reminderTimes) {
      await db.query(
        `INSERT INTO medication_reminders 
         (medication_schedule_id, patient_id, reminder_time, reminder_date)
         VALUES ($1, $2, $3, $4)`,
        [medicationScheduleId, patientId, reminderTime, date.toISOString().split('T')[0]]
      );
    }
  }
}

module.exports = {
  analyzeSymptoms,
  getDoctorAvailability,
  createRealAppointment,
  getMyAppointments,
  addMedicationSchedule,
  getMyMedications,
  getTodaysReminders,
  markMedicationTaken
};
