const db = require('../config/db');

async function createPayment({ userId, appointmentId, amount, currency, chargilyInvoiceId, chargilyCheckoutUrl }) {
  const { rows } = await db.query(
    `insert into public.payments
      (user_id, appointment_id, amount, currency, status, chargily_invoice_id, chargily_checkout_url)
     values ($1,$2,$3,$4,'pending',$5,$6)
     returning *`,
    [userId, appointmentId, amount, currency, chargilyInvoiceId, chargilyCheckoutUrl]
  );
  return rows[0];
}

async function updatePaymentStatusByInvoiceId(invoiceId, status, providerPayload) {
  const { rows } = await db.query(
    `update public.payments
     set status = $2,
         provider_payload = $3,
         paid_at = case when $2 = 'paid' then now() else paid_at end,
         failed_at = case when $2 = 'failed' then now() else failed_at end,
         refunded_at = case when $2 = 'refunded' then now() else refunded_at end
     where chargily_invoice_id = $1
     returning *`,
    [invoiceId, status, providerPayload]
  );
  return rows[0] || null;
}

module.exports = {
  createPayment,
  updatePaymentStatusByInvoiceId,
};

