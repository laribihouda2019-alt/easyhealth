const db = require('../config/db');

async function uploadCcpProof(req, res) {
    try {
        const { appointmentId, accountName, ccpNumber } = req.body;
        const user = req.user;
        const proofFile = req.file;

        if (!appointmentId || !accountName || !ccpNumber || !proofFile) {
            return res.status(400).json({ error: 'Tous les champs sont requis' });
        }

        const proofUrl = `/uploads/proofs/${proofFile.filename}`;

        //insert into payments table
        await db.query(
            `INSERT INTO payments 
       (user_id, appointment_id, amount, status, gateway, gateway_invoice_id, metadata)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
            [
                user.id,
                appointmentId,
                0, //amount should be fetched from appointment in a real 
                'pending_verification',
                'ccp',
                `ccp_${Date.now()}`,
                JSON.stringify({
                    account_name: accountName,
                    ccp_number: ccpNumber,
                    proof_url: proofUrl
                })
            ]
        );

        //update appointment status to "payment_pending_verification" 

        res.json({
            success: true,
            message: 'Preuve de paiement téléchargée avec succès',
            proof_url: proofUrl
        });

    } catch (error) {
        console.error('CCP Upload error:', error);
        res.status(500).json({ error: 'Erreur lors du téléchargement de la preuve' });
    }
}

module.exports = {
    uploadCcpProof
};
