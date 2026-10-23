const paymentModel = require('../models/paymentModel');
const { PAYMENT_STATUS } = require('../config/constants');

async function createPendingPayment(payload) {
  return paymentModel.createPayment(payload);
}

async function handleChargilyWebhook(payload, signature) {
  const invoiceId = payload.invoice_id || payload.id;
  const chargilyStatus = payload.status;

  let mappedStatus = PAYMENT_STATUS.PENDING;
  if (chargilyStatus === 'paid') mappedStatus = PAYMENT_STATUS.PAID;
  else if (chargilyStatus === 'failed') mappedStatus = PAYMENT_STATUS.FAILED;
  else if (chargilyStatus === 'refunded') mappedStatus = PAYMENT_STATUS.REFUNDED;

  const updated = await paymentModel.updatePaymentStatusByInvoiceId(invoiceId, mappedStatus, payload);
  return updated;
}

module.exports = {
  createPendingPayment,
  handleChargilyWebhook,
};


