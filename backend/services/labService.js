const db = require('../config/db');
const messageService = require('./messageService');

async function getServices(labId) {
    const { rows } = await db.query(
        'SELECT * FROM public.lab_services WHERE lab_id = $1 ORDER BY created_at DESC', 
        [labId]
    );
    return rows;
}

async function addService({ labId, testName, price }) {
    const { rows } = await db.query(
        'INSERT INTO public.lab_services (lab_id, test_name, price) VALUES ($1, $2, $3) RETURNING *',
        [labId, testName, price]
    );
    return rows[0];
}

async function uploadResult({ requestId, filePath, status }) {
    const { rows } = await db.query(
        'INSERT INTO public.test_results (request_id, file_path, status) VALUES ($1, $2, $3) RETURNING *',
        [requestId, filePath, status]
    );
    
    // Auto-update the parent lab request status
    if (status === 'Ready') {
       await db.query(
           'UPDATE public.lab_requests SET status = $1, result_url = $2 WHERE id = $3', 
           ['completed', filePath, requestId]
       );
    }
    
    return rows[0];
}

async function getResultsForRequest(requestId) {
     const { rows } = await db.query('SELECT * FROM public.test_results WHERE request_id = $1', [requestId]);
     return rows;
}

async function updateRequestStatus(requestId, status, labId) {
    // First update the status
    const { rows } = await db.query(
        'UPDATE public.lab_requests SET status = $1 WHERE id = $2 RETURNING *',
        [status, requestId]
    );
    
    const request = rows[0];
    if (!request) throw new Error('Demande introuvable');

    // If marked as completed, send the automated message
    if (status === 'completed') {
        try {
            await messageService.sendMessage({
                senderId: labId,
                recipientId: request.patient_id,
                content: 'Vos analyses sont terminées. Vous pouvez consulter les résultats dans votre espace dédié.'
            });
        } catch (e) {
            console.error(`Erreur lors de l'envoi du message auto:`, e);
            // Non-blocking error
        }
    }

    return request;
}

module.exports = {
   getServices,
   addService,
   uploadResult,
   getResultsForRequest,
   updateRequestStatus
};

