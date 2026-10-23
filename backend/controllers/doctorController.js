const db = require('../config/db');
const { sendToUser } = require('../services/socketService');

//get Doctor Appointments with Patient Detail
 
async function getDoctorAppointments(req, res, next) {
  try {
    const doctorId = req.user.id;
    console.log('[DEBUG] Fetching appointments for doctorId:', doctorId);

    // Also check total appointments for this doctor without any filters
    const totalCount = await db.query('SELECT count(*) FROM real_appointments WHERE doctor_id = $1', [doctorId]);
    console.log('[DEBUG] Total appointments found in DB for this doctor:', totalCount.rows[0].count);

    const { status, date, upcoming } = req.query;
    console.log('[DEBUG] Query filters:', { status, date, upcoming });

    let query = `
      SELECT ra.id, ra.doctor_id, ra.patient_id, ra.scheduled_at, ra.status, 
             ra.appointment_type, ra.duration_minutes, ra.location, ra.meeting_url, 
             ra.notes, ra.created_at,
             p.full_name as patient_name,
             p.email as patient_email,
             p.phone as patient_phone,
             p.avatar_url as patient_avatar

      FROM real_appointments ra
      LEFT JOIN profiles p ON ra.patient_id = p.id
      WHERE ra.doctor_id = $1::uuid
    `;

    const params = [doctorId];

    if (status) {
      query += ` AND ra.status = $${params.length + 1}`;
      params.push(status);
    }

    if (date) {
      query += ` AND DATE(ra.scheduled_at) = $${params.length + 1}`;
      params.push(date);
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
    console.error('Get doctor appointments error:', error);
    next(error);
  }
}

//set Doctor Availability
 
async function setAvailability(req, res, next) {
  try {
    const { availability } = req.body; //array of availability objects
    const doctorId = req.user.id;

    if (!availability || !Array.isArray(availability)) {
      return res.status(400).json({ error: 'Availability array is required' });
    }

    //delete existing availability
    await db.query('DELETE FROM doctor_availability WHERE doctor_id = $1', [doctorId]);

    //insert new availability
    const insertedAvailability = [];
    for (const avail of availability) {
      const result = await db.query(
        `INSERT INTO doctor_availability 
         (doctor_id, day_of_week, start_time, end_time, max_appointments, is_available)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING *`,
        [
          doctorId,
          avail.dayOfWeek,
          avail.startTime,
          avail.endTime,
          avail.maxAppointments || 1,
          avail.isAvailable !== false
        ]
      );
      insertedAvailability.push(result.rows[0]);
    }

    res.status(201).json({
      success: true,
      availability: insertedAvailability,
      message: 'Disponibilité mise à jour avec succès'
    });

  } catch (error) {
    console.error('Set availability error:', error);
    next(error);
  }
}

//get Doctor's Current Availability
 
async function getMyAvailability(req, res, next) {
  try {
    const doctorId = req.user.id;

    const result = await db.query(
      'SELECT * FROM doctor_availability WHERE doctor_id = $1 ORDER BY day_of_week, start_time',
      [doctorId]
    );

    res.json({
      success: true,
      availability: result.rows
    });

  } catch (error) {
    console.error('Get availability error:', error);
    next(error);
  }
}

//update Appointment Status

async function updateAppointmentStatus(req, res, next) {
  try {
    const { appointmentId } = req.params;
    const { status, notes } = req.body;
    const doctorId = req.user.id;

    if (!['pending', 'confirmed', 'completed', 'cancelled', 'no_show', 'accepted', 'rejected'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }

    const result = await db.query(
      `UPDATE real_appointments 
       SET status = $1, notes = COALESCE($2, notes), updated_at = NOW()
       WHERE id = $3 AND doctor_id = $4
       RETURNING *`,
      [status, notes, appointmentId, doctorId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Appointment not found' });
    }

    const appointment = result.rows[0];

    //notify patient of status change
    await db.query(
      `INSERT INTO health_alerts 
       (user_id, alert_type, title, body, sent_by_ai, metadata)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        appointment.patient_id,
        'appointment_status_change',
        'Statut du Rendez-vous Mis à Jour',
        `Votre rendez-vous du ${new Date(appointment.scheduled_at).toLocaleDateString('fr-FR')} est maintenant: ${status}`,
        false,
        JSON.stringify({ appointmentId: appointment.id, status })
      ]
    );

    //notify patient of status change via Socket.io
    sendToUser(appointment.patient_id, 'appointment_status_change', {
      appointmentId: appointment.id,
      status: status
    });

    res.json({
      success: true,
      appointment,
      message: 'Statut du rendez-vous mis à jour'
    });

  } catch (error) {
    console.error('Update appointment status error:', error);
    next(error);
  }
}

//record Disease Observation
 
async function recordDiseaseObservation(req, res, next) {
  try {
    const {
      diseaseName,
      diseaseCategory,
      symptoms,
      patientAgeRange,
      patientGender,
      severityLevel,
      notes
    } = req.body;
    const doctorId = req.user.id;

    if (!diseaseName || !diseaseCategory || !symptoms) {
      return res.status(400).json({ error: 'Disease name, category, and symptoms are required' });
    }

    const result = await db.query(
      `INSERT INTO disease_observations 
       (doctor_id, disease_name, disease_category, symptoms, patient_age_range, patient_gender, severity_level, notes)
       VALUES ($1::uuid, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [
        doctorId,
        diseaseName,
        diseaseCategory,
        JSON.stringify(symptoms),
        patientAgeRange,
        patientGender,
        severityLevel,
        notes
      ]
    );

    //trigger AI analysis for this disease
    await triggerDiseaseAnalysis(diseaseName, diseaseCategory);

    res.status(201).json({
      success: true,
      observation: result.rows[0],
      message: 'Observation enregistrée avec succès'
    });

  } catch (error) {
    console.error('Record disease observation error:', error);
    next(error);
  }
}

//get Doctor's Disease Observations
 
async function getMyDiseaseObservations(req, res, next) {
  try {
    const doctorId = req.user.id;
    const { date, diseaseName, category } = req.query;

    let query = 'SELECT * FROM disease_observations WHERE doctor_id = $1::uuid';
    const params = [doctorId];

    if (date) {
      query += ` AND observation_date = $${params.length + 1}`;
      params.push(date);
    }

    if (diseaseName) {
      query += ` AND disease_name ILIKE $${params.length + 1}`;
      params.push(`%${diseaseName}%`);
    }

    if (category) {
      query += ` AND disease_category = $${params.length + 1}`;
      params.push(category);
    }

    query += ' ORDER BY observation_date DESC, created_at DESC';

    const result = await db.query(query, params);

    res.json({
      success: true,
      observations: result.rows
    });

  } catch (error) {
    console.error('Get disease observations error:', error);
    next(error);
  }
}

//get today's Appointments (for reminders)
 
async function getTodaysAppointments(req, res, next) {
  try {
    const doctorId = req.user.id;
    const today = new Date().toISOString().split('T')[0];
    console.log('[DEBUG] getTodaysAppointments - Doctor ID:', doctorId, 'Today:', today);

    const result = await db.query(
      `SELECT ra.*, 
             p.full_name as patient_name,
             p.phone as patient_phone,
             p.avatar_url as patient_avatar
       FROM real_appointments ra
       JOIN profiles p ON ra.patient_id = p.id
       WHERE ra.doctor_id = $1::uuid AND DATE(ra.scheduled_at) = $2
       AND ra.status IN ('pending', 'confirmed')
       ORDER BY ra.scheduled_at ASC`,
      [doctorId, today]
    );
    console.log('[DEBUG] getTodaysAppointments - Query result:', result.rows);

    res.json({
      success: true,
      appointments: result.rows,
      count: result.rows.length
    });

  } catch (error) {
    console.error('Get today\'s appointments error:', error);
    next(error);
  }
}

//get Disease Statistic(for doctor's view)
 
async function getDiseaseStatistics(req, res, next) {
  try {
    const doctorId = req.user.id;
    const { period } = req.query; // 'week', 'month', 'year'

    let dateFilter = '';
    if (period === 'week') {
      dateFilter = 'AND observation_date >= CURRENT_DATE - INTERVAL \'7 days\'';
    } else if (period === 'month') {
      dateFilter = 'AND observation_date >= CURRENT_DATE - INTERVAL \'30 days\'';
    } else if (period === 'year') {
      dateFilter = 'AND observation_date >= CURRENT_DATE - INTERVAL \'365 days\'';
    }

    const result = await db.query(
      `SELECT 
         disease_name,
         disease_category,
         COUNT(*) as total_cases,
         COUNT(DISTINCT observation_date) as days_observed,
         array_agg(DISTINCT patient_age_range) as age_ranges,
         array_agg(DISTINCT patient_gender) as genders,
         array_agg(DISTINCT severity_level) as severity_levels
       FROM disease_observations 
       WHERE doctor_id = $1 ${dateFilter}
       GROUP BY disease_name, disease_category
       ORDER BY total_cases DESC`,
      [doctorId]
    );

    res.json({
      success: true,
      statistics: result.rows,
      period: period || 'all'
    });

  } catch (error) {
    console.error('Get disease statistics error:', error);
    next(error);
  }
}

//get Common Symptoms (for doctor's observations)
 
async function getCommonSymptoms(req, res, next) {
  try {
    const doctorId = req.user.id;
    const { period } = req.query;

    let dateFilter = '';
    if (period === 'week') {
      dateFilter = 'AND observation_date >= CURRENT_DATE - INTERVAL \'7 days\'';
    } else if (period === 'month') {
      dateFilter = 'AND observation_date >= CURRENT_DATE - INTERVAL \'30 days\'';
    }

    const result = await db.query(
      `SELECT 
         jsonb_array_elements_text(symptoms) as symptom,
         COUNT(*) as frequency,
         COUNT(DISTINCT observation_date) as days_observed
       FROM disease_observations 
       WHERE doctor_id = $1 ${dateFilter}
       GROUP BY symptom
       ORDER BY frequency DESC
       LIMIT 20`,
      [doctorId]
    );

    res.json({
      success: true,
      commonSymptoms: result.rows
    });

  } catch (error) {
    console.error('Get common symptoms error:', error);
    next(error);
  }
}

//helper Function
async function triggerDiseaseAnalysis(diseaseName, diseaseCategory) {
  try {
    //check if this disease needs statistical analysis
    const existingStats = await db.query(
      'SELECT * FROM disease_statistics WHERE disease_name = $1 AND observation_date = CURRENT_DATE',
      [diseaseName]
    );

    if (existingStats.rows.length === 0) {
      //create new statistics entry
      await db.query(
        `INSERT INTO disease_statistics (disease_name, disease_category, total_cases)
         VALUES ($1, $2, 1)
         ON CONFLICT (disease_name, observation_date)
         DO UPDATE SET total_cases = disease_statistics.total_cases + 1`,
        [diseaseName, diseaseCategory]
      );
    } else {
      //update existing statistics
      await db.query(
        `UPDATE disease_statistics 
         SET total_cases = total_cases + 1, updated_at = NOW()
         WHERE disease_name = $1 AND observation_date = CURRENT_DATE`,
        [diseaseName]
      );
    }

    //check for epidemic alert
    await checkForEpidemicAlert(diseaseName, diseaseCategory);

  } catch (error) {
    console.error('Trigger disease analysis error:', error);
  }
}

async function checkForEpidemicAlert(diseaseName, diseaseCategory) {
  try {
    //get recent statistics for this disease
    const recentStats = await db.query(
      `SELECT 
         observation_date,
         total_cases,
         LAG(total_cases) OVER (ORDER BY observation_date) as previous_cases
       FROM disease_statistics 
       WHERE disease_name = $1 AND observation_date >= CURRENT_DATE - INTERVAL \'7 days\'
       ORDER BY observation_date DESC
       LIMIT 2`,
      [diseaseName]
    );

    if (recentStats.rows.length >= 2) {
      const current = recentStats.rows[0];
      const previous = recentStats.rows[1];

      if (previous.total_cases > 0) {
        const increasePercentage = ((current.total_cases - previous.total_cases) / previous.total_cases) * 100;

        //if increase is more than 50%, create epidemic alert
        if (increasePercentage > 50) {
          await createEpidemicAlert(diseaseName, diseaseCategory, increasePercentage);
        }
      }
    }

  } catch (error) {
    console.error('Check epidemic alert error:', error);
  }
}

async function createEpidemicAlert(diseaseName, diseaseCategory, increasePercentage) {
  try {
    //check if alert already exists for today
    const existingAlert = await db.query(
      'SELECT id FROM epidemic_alerts WHERE disease_name = $1 AND created_at >= CURRENT_DATE',
      [diseaseName]
    );

    if (existingAlert.rows.length === 0) {
      const alertSeverity = increasePercentage > 100 ? 'critical' : increasePercentage > 75 ? 'high' : 'medium';

      await db.query(
        `INSERT INTO epidemic_alerts 
         (disease_name, disease_category, alert_severity, alert_message, increase_percentage, recommended_actions)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [
          diseaseName,
          diseaseCategory,
          alertSeverity,
          `Augmentation significative des cas de ${diseaseName} détectée (${increasePercentage.toFixed(1)}%)`,
          increasePercentage,
          JSON.stringify({
            recommendations: [
              'Surveillance renforcée',
              'Information du public',
              'Préparation des services de santé',
              'Mise en place de mesures préventives'
            ],
            severity: alertSeverity
          })
        ]
      );

      //notify admin
      await notifyAdmin(diseaseName, alertSeverity, increasePercentage);
    }

  } catch (error) {
    console.error('Create epidemic alert error:', error);
  }
}

async function notifyAdmin(diseaseName, severity, increasePercentage) {
  try {
    //get admin users
    const adminQuery = await db.query(
      'SELECT id FROM profiles WHERE role = \'admin\' AND is_approved = true'
    );

    for (const admin of adminQuery.rows) {
      await db.query(
        `INSERT INTO health_alerts 
         (user_id, alert_type, title, body, sent_by_ai, metadata)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [
          admin.id,
          'epidemic_alert',
          `Alerte Épidémique: ${diseaseName}`,
          `Augmentation de ${increasePercentage.toFixed(1)}% des cas de ${diseaseName}. Niveau: ${severity}`,
          true,
          JSON.stringify({ diseaseName, severity, increasePercentage })
        ]
      );
    }

  } catch (error) {
    console.error('Notify admin error:', error);
  }
}

//get Specific Patient's Medical Records (for scanning feature)
 
async function getPatientMedicalRecords(req, res, next) {
  try {
    const { patientId } = req.params;
    
    const result = await db.query(
      'SELECT * FROM medical_records WHERE patient_id = $1::uuid ORDER BY created_at DESC',
      [patientId]
    );

    res.json({
      success: true,
      data: result.rows
    });

  } catch (error) {
    console.error('Get patient medical records error:', error);
    next(error);
  }
}

module.exports = {
  getDoctorAppointments,
  setAvailability,
  getMyAvailability,
  updateAppointmentStatus,
  recordDiseaseObservation,
  getMyDiseaseObservations,
  getTodaysAppointments,
  getDiseaseStatistics,
  getCommonSymptoms,
  getPatientMedicalRecords
};
