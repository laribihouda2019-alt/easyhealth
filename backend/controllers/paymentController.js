const paymentService = require('../services/paymentService');

async function handleChargilyWebhook(req, res, next) {
  try {
    const signature = req.headers['x-chargily-signature'] || req.headers['x-signature'];
    const payload = req.body;
    await paymentService.handleChargilyWebhook(payload, signature);
    res.status(200).json({ received: true });
  } catch (err) {
    next(err);
  }
}

async function createPayment(req, res, next) {
  try {
    const { appointmentId, amount, currency } = req.body;
    
    const payment = await paymentService.createPayment({
      userId: req.user.id,
      appointmentId,
      amount,
      currency
    });
    
    res.status(201).json(payment);
  } catch (err) {
    next(err);
  }
}

async function getMyPayments(req, res, next) {
  try {
    const payments = await paymentService.getUserPayments(req.user.id);
    res.json(payments);
  } catch (err) {
    next(err);
  }
}

async function getPaymentById(req, res, next) {
  try {
    const { id } = req.params;
    const payment = await paymentService.getPaymentById(id);
    res.json(payment);
  } catch (err) {
    next(err);
  }
}

async function updatePaymentStatus(req, res, next) {
  try {
    const { id } = req.params;
    const { status } = req.body;
    
    const updated = await paymentService.updatePaymentStatus(id, status);
    res.json(updated);
  } catch (err) {
    next(err);
  }
}

async function getPaymentsByStatus(req, res, next) {
  try {
    const { status } = req.params;
    const payments = await paymentService.getPaymentsByStatus(status);
    res.json(payments);
  } catch (err) {
    next(err);
  }
}

async function getAppointmentPayments(req, res, next) {
  try {
    const { appointmentId } = req.params;
    const payments = await paymentService.getAppointmentPayments(appointmentId);
    res.json(payments);
  } catch (err) {
    next(err);
  }
}

async function getPaymentStatistics(req, res, next) {
  try {
    const stats = await paymentService.getPaymentStatistics(req.user.id);
    res.json(stats);
  } catch (err) {
    next(err);
  }
}

async function getRevenueStatistics(req, res, next) {
  try {
    const stats = await paymentService.getRevenueStatistics();
    res.json(stats);
  } catch (err) {
    next(err);
  }
}

module.exports = {
  handleChargilyWebhook,
  createPayment,
  getMyPayments,
  getPaymentById,
  updatePaymentStatus,
  getPaymentsByStatus,
  getAppointmentPayments,
  getPaymentStatistics,
  getRevenueStatistics,
};

