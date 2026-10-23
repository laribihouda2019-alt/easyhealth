const analyticsService = require('../services/analyticsService');

async function createAnonymizedDiagnosis(req, res, next) {
  try {
    const {
      pseudoId,
      ageRange,
      gender,
      country,
      city,
      primaryCondition,
      symptoms,
      outcome,
      source,
      metadata
    } = req.body;

    const diagnosis = await analyticsService.createAnonymizedDiagnosis({
      pseudoId,
      ageRange,
      gender,
      country,
      city,
      primaryCondition,
      symptoms,
      outcome,
      source,
      metadata
    });

    res.status(201).json(diagnosis);
  } catch (err) {
    next(err);
  }
}

async function getAllAnonymizedDiagnoses(req, res, next) {
  try {
    const diagnoses = await analyticsService.getAllAnonymizedDiagnoses();
    res.json(diagnoses);
  } catch (err) {
    next(err);
  }
}

async function getDiagnosesByCondition(req, res, next) {
  try {
    const { condition } = req.params;
    const diagnoses = await analyticsService.getDiagnosesByCondition(condition);
    res.json(diagnoses);
  } catch (err) {
    next(err);
  }
}

async function getDiagnosesByAgeRange(req, res, next) {
  try {
    const { ageRange } = req.params;
    const diagnoses = await analyticsService.getDiagnosesByAgeRange(ageRange);
    res.json(diagnoses);
  } catch (err) {
    next(err);
  }
}

async function getDiagnosesByLocation(req, res, next) {
  try {
    const { country, city } = req.query;
    const diagnoses = await analyticsService.getDiagnosesByLocation(country, city);
    res.json(diagnoses);
  } catch (err) {
    next(err);
  }
}

async function getDiagnosesBySymptoms(req, res, next) {
  try {
    const { symptom } = req.query;
    const diagnoses = await analyticsService.getDiagnosesBySymptoms(symptom);
    res.json(diagnoses);
  } catch (err) {
    next(err);
  }
}

async function getDiagnosesBySource(req, res, next) {
  try {
    const { source } = req.params;
    const diagnoses = await analyticsService.getDiagnosesBySource(source);
    res.json(diagnoses);
  } catch (err) {
    next(err);
  }
}

async function getConditionStatistics(req, res, next) {
  try {
    const stats = await analyticsService.getConditionStatistics();
    res.json(stats);
  } catch (err) {
    next(err);
  }
}

async function getAgeConditionStatistics(req, res, next) {
  try {
    const stats = await analyticsService.getAgeConditionStatistics();
    res.json(stats);
  } catch (err) {
    next(err);
  }
}

async function getCommonSymptoms(req, res, next) {
  try {
    const symptoms = await analyticsService.getCommonSymptoms();
    res.json(symptoms);
  } catch (err) {
    next(err);
  }
}

async function getRegionalStatistics(req, res, next) {
  try {
    const stats = await analyticsService.getRegionalStatistics();
    res.json(stats);
  } catch (err) {
    next(err);
  }
}

async function getOutcomeStatistics(req, res, next) {
  try {
    const stats = await analyticsService.getOutcomeStatistics();
    res.json(stats);
  } catch (err) {
    next(err);
  }
}

async function getSummary(req, res, next) {
  try {
    const userId = req.user.id;
    const role = req.user.role;
    const summary = await analyticsService.getDashboardSummary(userId, role);
    res.json({
      success: true,
      data: summary
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  createAnonymizedDiagnosis,
  getAllAnonymizedDiagnoses,
  getDiagnosesByCondition,
  getDiagnosesByAgeRange,
  getDiagnosesByLocation,
  getDiagnosesBySymptoms,
  getDiagnosesBySource,
  getConditionStatistics,
  getAgeConditionStatistics,
  getCommonSymptoms,
  getRegionalStatistics,
  getOutcomeStatistics,
  getSummary,
};
