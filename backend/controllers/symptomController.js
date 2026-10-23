const symptomService = require('../services/symptomService');

async function logSymptom(req, res, next) {
  try {
    const { symptoms, description, painLevel, metadata } = req.body;
    const symptomLog = await symptomService.createSymptomLog({
      userId: req.user.id,
      symptoms,
      description,
      painLevel,
      metadata
    });
    res.status(201).json(symptomLog);
  } catch (err) {
    next(err);
  }
}

async function getMySymptoms(req, res, next) {
  try {
    const { page = 1, limit = 50 } = req.query;
    const symptoms = await symptomService.getUserSymptoms(
      req.user.id,
      parseInt(limit),
      (parseInt(page) - 1) * parseInt(limit)
    );
    res.json(symptoms);
  } catch (err) {
    next(err);
  }
}

async function getSymptomById(req, res, next) {
  try {
    const { id } = req.params;
    const symptom = await symptomService.getSymptomById(id);
    res.json(symptom);
  } catch (err) {
    next(err);
  }
}

async function updateSymptom(req, res, next) {
  try {
    const { id } = req.params;
    const { symptoms, description, painLevel, metadata } = req.body;
    const updated = await symptomService.updateSymptomLog(id, req.user.id, {
      symptoms,
      description,
      painLevel,
      metadata
    });
    res.json(updated);
  } catch (err) {
    next(err);
  }
}

async function deleteSymptom(req, res, next) {
  try {
    const { id } = req.params;
    await symptomService.deleteSymptomLog(id, req.user.id);
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
}

async function getSymptomsByDateRange(req, res, next) {
  try {
    const { startDate, endDate } = req.query;
    const symptoms = await symptomService.getSymptomsByDateRange(
      req.user.id,
      startDate,
      endDate
    );
    res.json(symptoms);
  } catch (err) {
    next(err);
  }
}

async function getRecentSymptoms(req, res, next) {
  try {
    const symptoms = await symptomService.getRecentSymptoms(req.user.id);
    res.json(symptoms);
  } catch (err) {
    next(err);
  }
}

async function searchSymptoms(req, res, next) {
  try {
    const { query } = req.query;
    const symptoms = await symptomService.searchSymptoms(req.user.id, query);
    res.json(symptoms);
  } catch (err) {
    next(err);
  }
}

async function getSymptomStatistics(req, res, next) {
  try {
    const stats = await symptomService.getSymptomStatistics(req.user.id);
    res.json(stats);
  } catch (err) {
    next(err);
  }
}

async function getCommonSymptoms(req, res, next) {
  try {
    const symptoms = await symptomService.getCommonSymptoms(req.user.id);
    res.json(symptoms);
  } catch (err) {
    next(err);
  }
}

module.exports = {
  logSymptom,
  getMySymptoms,
  getSymptomById,
  updateSymptom,
  deleteSymptom,
  getSymptomsByDateRange,
  getRecentSymptoms,
  searchSymptoms,
  getSymptomStatistics,
  getCommonSymptoms,
};
