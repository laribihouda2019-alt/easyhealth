const db = require('../config/db');

async function addAvailabilitySlots(req, res, next) {
  try {
    const { slots } = req.body; // Array of { start_time, end_time }
    const doctorId = req.user.id;

    if (!slots || !Array.isArray(slots)) {
      return res.status(400).json({ error: 'Slots array is required' });
    }

    const insertedSlots = [];
    for (const slot of slots) {
      const { rows } = await db.query(
        `INSERT INTO public.availability_slots (doctor_id, start_time, end_time)
         VALUES ($1, $2, $3)
         RETURNING *`,
        [doctorId, slot.start_time, slot.end_time]
      );
      insertedSlots.push(rows[0]);
    }

    res.status(201).json(insertedSlots);
  } catch (err) {
    next(err);
  }
}

async function getDoctorSlots(req, res, next) {
  try {
    const doctorId = req.user.id;
    const { rows } = await db.query(
      `SELECT * FROM public.availability_slots 
       WHERE doctor_id = $1::uuid 
       AND start_time >= NOW()
       ORDER BY start_time ASC`,
      [doctorId]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

async function getAvailableDoctorSlots(req, res, next) {
  try {
    const { doctorId } = req.params;
    const { date } = req.query;

    let query = `
      SELECT * FROM public.availability_slots 
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

    const { rows } = await db.query(query, params);
    res.json({
      success: true,
      availableSlots: rows
    });
  } catch (err) {
    next(err);
  }
}

async function deleteSlot(req, res, next) {
  try {
    const { id } = req.params;
    const doctorId = req.user.id;

    const { rowCount } = await db.query(
      `DELETE FROM public.availability_slots 
       WHERE id = $1 AND doctor_id = $2 AND status = 'available'`,
      [id, doctorId]
    );

    if (rowCount === 0) {
      return res.status(404).json({ error: 'Slot not found or already booked' });
    }

    res.json({ message: 'Slot deleted' });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  addAvailabilitySlots,
  getDoctorSlots,
  getAvailableDoctorSlots,
  deleteSlot,
};
