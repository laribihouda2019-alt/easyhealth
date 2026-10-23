const medicationService = require('../services/medicationService');

async function addMedication(req, res, next) {
  try {
    const {
      medicineName,
      dosage,
      frequency,
      startDate,
      endDate,
      reminderTimes,
      isActive,
      metadata
    } = req.body;

    const medication = await medicationService.createMedication({
      userId: req.user.id,
      medicineName,
      dosage,
      frequency,
      startDate: startDate || new Date().toISOString().split('T')[0],
      endDate,
      reminderTimes,
      isActive,
      metadata
    });

    res.status(201).json(medication);
  } catch (err) {
    next(err);
  }
}

async function getMyMedications(req, res, next) {
  try {
    const { includeInactive = false } = req.query;
    const medications = await medicationService.getUserMedications(
      req.user.id,
      includeInactive === 'true'
    );
    res.json(medications);
  } catch (err) {
    next(err);
  }
}

async function getMedicationById(req, res, next) {
  try {
    const { id } = req.params;
    const medication = await medicationService.getMedicationById(id);
    res.json(medication);
  } catch (err) {
    next(err);
  }
}

async function updateMedication(req, res, next) {
  try {
    const { id } = req.params;
    const {
      medicineName,
      dosage,
      frequency,
      startDate,
      endDate,
      reminderTimes,
      isActive,
      metadata
    } = req.body;

    const updated = await medicationService.updateMedication(id, req.user.id, {
      medicineName,
      dosage,
      frequency,
      startDate,
      endDate,
      reminderTimes,
      isActive,
      metadata
    });

    res.json(updated);
  } catch (err) {
    next(err);
  }
}

async function deactivateMedication(req, res, next) {
  try {
    const { id } = req.params;
    const updated = await medicationService.deactivateMedication(id, req.user.id);
    res.json(updated);
  } catch (err) {
    next(err);
  }
}

async function getTodaysMedications(req, res, next) {
  try {
    const medications = await medicationService.getTodaysMedications(req.user.id);
    res.json(medications);
  } catch (err) {
    next(err);
  }
}

async function getMedicationsDueAtTime(req, res, next) {
  try {
    const { time } = req.query;
    const medications = await medicationService.getMedicationsDueAtTime(req.user.id, time);
    res.json(medications);
  } catch (err) {
    next(err);
  }
}

async function getMedicationsByDateRange(req, res, next) {
  try {
    const { startDate, endDate } = req.query;
    const medications = await medicationService.getMedicationsByDateRange(
      req.user.id,
      startDate,
      endDate
    );
    res.json(medications);
  } catch (err) {
    next(err);
  }
}

async function searchMedications(req, res, next) {
  try {
    const { query } = req.query;
    const medications = await medicationService.searchMedications(req.user.id, query);
    res.json(medications);
  } catch (err) {
    next(err);
  }
}

async function getMedicationStatistics(req, res, next) {
  try {
    const stats = await medicationService.getMedicationStatistics(req.user.id);
    res.json(stats);
  } catch (err) {
    next(err);
  }
}

module.exports = {
  addMedication,
  getMyMedications,
  getMedicationById,
  updateMedication,
  deactivateMedication,
  getTodaysMedications,
  getMedicationsDueAtTime,
  getMedicationsByDateRange,
  searchMedications,
  getMedicationStatistics,
};
