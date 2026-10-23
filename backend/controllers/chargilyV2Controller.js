const { ChargilyClient } = require('@chargily/chargily-pay');
const db = require('../config/db');
const ENV = require('../config/env');

//initialize Chargily Client
const client = new ChargilyClient({
    api_key: ENV.CHARGILY_SECRET_KEY,
    mode: 'test', 
});

//create a checkout session
 
async function createCheckout(req, res, next) {
    try {
        const { amount, appointmentId, metadata = {} } = req.body;
        const user = req.user;

        //ensure amount is a rounded integer as required by Chargily V2
        const finalAmount = Math.round(parseFloat(amount));

        if (!finalAmount || finalAmount < 100) {
            return res.status(400).json({ error: 'Le montant doit être d\'au moins 100 DZD.' });
        }

        //sanitize metadata: Chargily V2 requires metadata values to be strings
        const sanitizedMetadata = {};
        if (user && user.id) sanitizedMetadata.userId = String(user.id);
        if (appointmentId) sanitizedMetadata.appointmentId = String(appointmentId);
        
        if (metadata && typeof metadata === 'object') {
          Object.keys(metadata).forEach(key => {
              if (metadata[key] !== null && metadata[key] !== undefined) {
                  sanitizedMetadata[key] = String(metadata[key]);
              }
          });
        }

        const host = req.get('host');
        const isLocal = host.includes('localhost') || host.includes('127.0.0.1');

        // we might need to skip webhook_url or use a tunnel URL,Chargily V2 may reject 'localhost' webhooks.
        const checkoutPayload = {
            amount: finalAmount,
            currency: 'dzd',
            success_url: `${ENV.FRONTEND_URL}/#/payment-success`,
            failure_url: `${ENV.FRONTEND_URL}/#/payment-failure`,
            metadata: sanitizedMetadata
        };

        //only add webhook_url if we're not on localhost, or use the dev value
        if (!isLocal) {
          checkoutPayload.webhook_url = `${req.protocol}://${host}/api/payments/webhook/chargily-v2`;
        }

        console.log('[CHARGILY] Creating checkout with payload:', JSON.stringify(checkoutPayload, null, 2));

        const checkout = await client.createCheckout(checkoutPayload);

        if (!checkout || !checkout.checkout_url) {
          console.error('[CHARGILY] Partial success but no URL in response:', checkout);
          throw new Error('La réponse de Chargily ne contient pas d\'URL de paiement.');
        }

        //create a pending payment record in our DB
        await db.query(
            `INSERT INTO public.payments 
       (user_id, appointment_id, amount, currency, status, chargily_invoice_id, chargily_checkout_url, provider_payload)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
            [
                user.id,
                appointmentId ? parseInt(appointmentId) : null,
                finalAmount,
                'DZD',
                'pending',
                checkout.id,
                checkout.checkout_url,
                JSON.stringify(checkout)
            ]
        );

        res.json({
            success: true,
            checkout_url: checkout.checkout_url,
            checkout_id: checkout.id
        });

    } catch (error) {
        console.error('--- CHARGILY ERROR DETAILS ---');
        console.error('Error Name:', error.name);
        console.error('Error Message:', error.message);
        
        if (error.response && error.response.data) {
            console.error('Chargily API Error Response:', JSON.stringify(error.response.data, null, 2));
            return res.status(error.response.status || 500).json({
                error: 'Erreur Chargily API',
                details: error.response.data
            });
        }
        
        res.status(500).json({ 
            error: 'Erreur lors de la création du paiement',
            message: error.message 
        });
    }
}

//handle Chargily Webhook V2

async function handleWebhook(req, res, next) {
    try {
        const signature = req.headers['signature'];
        const payload = req.rawBody || JSON.stringify(req.body);

       //check documentation for verifySignature

        const event = req.body;
        const type = event.type;
        const data = event.data;

        if (type === 'checkout.paid') {
            const checkoutId = data.id;
            const metadata = data.metadata;

            //update payment status in DB
            await db.query(
                `UPDATE public.payments 
         SET status = 'paid', updated_at = NOW(), provider_payload = $1
         WHERE chargily_invoice_id = $2`,
                [JSON.stringify(data), checkoutId]
            );

            //if it was for an appointment, maybe update appointment status too
            if (metadata && metadata.appointmentId) {
                await db.query(
                    `UPDATE real_appointments SET status = 'confirmed' WHERE id = $1`,
                    [metadata.appointmentId]
                );
            }

            //update medication order status
            if (metadata && metadata.orderId) {
                await db.query(
                    `UPDATE medication_orders SET status = 'paid' WHERE id = $1`,
                    [metadata.orderId]
                );
            }

            //update lab request status
            if (metadata && metadata.requestId) {
                await db.query(
                    `UPDATE lab_requests SET status = 'paid' WHERE id = $1`,
                    [metadata.requestId]
                );
            }
        }

        res.status(200).send('OK');

    } catch (error) {
        console.error('Chargily webhook error:', error);
        res.status(500).send('Internal Server Error');
    }
}

module.exports = {
    createCheckout,
    handleWebhook
};
