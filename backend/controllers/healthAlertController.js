const healthAlertService = require('../services/healthAlertService');

async function createHealthAlert(req, res, next) {
  try {
    const { alertType, title, body, sentByAi, isRead, metadata } = req.body;
    
    const alert = await healthAlertService.createHealthAlert({
      userId: req.user.id,
      alertType,
      title,
      body,
      sentByAi,
      isRead,
      metadata
    });
    
    res.status(201).json(alert);
  } catch (err) {
    next(err);
  }
}

async function getMyHealthAlerts(req, res, next) {
  try {
    const alerts = await healthAlertService.getUserHealthAlerts(req.user.id);
    res.json(alerts);
  } catch (err) {
    next(err);
  }
}

async function getUnreadHealthAlerts(req, res, next) {
  try {
    const alerts = await healthAlertService.getUnreadHealthAlerts(req.user.id);
    res.json(alerts);
  } catch (err) {
    next(err);
  }
}

async function markAlertAsRead(req, res, next) {
  try {
    const { id } = req.params;
    const updated = await healthAlertService.markAsRead(id, req.user.id);
    res.json(updated);
  } catch (err) {
    next(err);
  }
}

async function markAllAlertsAsRead(req, res, next) {
  try {
    await healthAlertService.markAllAsRead(req.user.id);
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
}

async function deleteHealthAlert(req, res, next) {
  try {
    const { id } = req.params;
    await healthAlertService.deleteHealthAlert(id, req.user.id);
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
}

async function getAlertsByType(req, res, next) {
  try {
    const { alertType } = req.params;
    const alerts = await healthAlertService.getAlertsByType(req.user.id, alertType);
    res.json(alerts);
  } catch (err) {
    next(err);
  }
}

async function getAlertsByDateRange(req, res, next) {
  try {
    const { startDate, endDate } = req.query;
    const alerts = await healthAlertService.getAlertsByDateRange(
      req.user.id,
      startDate,
      endDate
    );
    res.json(alerts);
  } catch (err) {
    next(err);
  }
}

async function getAiGeneratedAlerts(req, res, next) {
  try {
    const alerts = await healthAlertService.getAiGeneratedAlerts(req.user.id);
    res.json(alerts);
  } catch (err) {
    next(err);
  }
}

async function getHealthAlertStatistics(req, res, next) {
  try {
    const stats = await healthAlertService.getHealthAlertStatistics(req.user.id);
    res.json(stats);
  } catch (err) {
    next(err);
  }
}

async function getAlertTypeStatistics(req, res, next) {
  try {
    const stats = await healthAlertService.getAlertTypeStatistics();
    res.json(stats);
  } catch (err) {
    next(err);
  }
}

module.exports = {
  createHealthAlert,
  getMyHealthAlerts,
  getUnreadHealthAlerts,
  markAlertAsRead,
  markAllAlertsAsRead,
  deleteHealthAlert,
  getAlertsByType,
  getAlertsByDateRange,
  getAiGeneratedAlerts,
  getHealthAlertStatistics,
  getAlertTypeStatistics,
};
