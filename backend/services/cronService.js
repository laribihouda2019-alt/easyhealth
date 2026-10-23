const cron = require('node-cron');
const db = require('../config/db');
const { createNotification } = require('../controllers/notificationController');

function initCronJobs() {
    //run every day at 08:00 AM to generate notifications for medications
    cron.schedule('0 8 * * *', async () => {
        try {
            const { rows } = await db.query(`
                SELECT ms.id, ms.patient_id, ms.medicine_name, ms.reminder_times 
                FROM public.medication_schedules ms
                WHERE ms.is_active = true 
                AND CURRENT_DATE BETWEEN ms.start_date AND COALESCE(ms.end_date, '2099-12-31')
            `);

            for (const med of rows) {
                if (med.reminder_times && med.reminder_times.length > 0) {
                    const body = `N'oubliez pas de prendre: ${med.medicine_name} aujourd'hui aux heures suivantes: ${med.reminder_times.join(', ')}`;
                    await createNotification(
                        med.patient_id,
                        'Rappel de médicament',
                        body,
                        'medication',
                        med.id.toString()
                    );
                }
            }
        } catch (err) {
            //table might not exist in early dev, ignore
        }
    });

    //DOCTORS: Run EVERY MINUTE to check for appointments starting in exactly 15 minutes
    cron.schedule('* * * * *', async () => {
        try {
            const { rows } = await db.query(`
                SELECT a.id, a.doctor_id, a.scheduled_at, p.full_name as patient_name
                FROM public.real_appointments a
                JOIN public.profiles p ON a.patient_id = p.id
                WHERE a.status = 'confirmed' 
                AND a.scheduled_at >= NOW() + interval '14 minutes'
                AND a.scheduled_at < NOW() + interval '16 minutes'
            `);

            for (const appt of rows) {
                const timeStr = new Date(appt.scheduled_at).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
                const body = `Rappel: Vous avez une consultation avec ${appt.patient_name} dans 15 minutes (à ${timeStr}).`;
                
                await createNotification(
                    appt.doctor_id,
                    'Consultation Imminente',
                    body,
                    'appointment',
                    appt.id.toString()
                );
            }
        } catch (err) {
            //silent
        }
    });

    //LABORATORIES: Run daily (e.g., at 09:00 AM) to alert labs about accepted requests lacking uploaded results (>24 hours)
    cron.schedule('0 9 * * *', async () => {
        try {
            const { rows } = await db.query(`
                SELECT r.id, r.lab_id, r.test_type, p.full_name as patient_name
                FROM public.lab_requests r
                JOIN public.profiles p ON r.patient_id = p.id
                WHERE r.status = 'accepted'
                AND r.result_url IS NULL
                AND r.updated_at < NOW() - interval '24 hours'
            `);

            for (const req of rows) {
                const body = `Tâche en attente: Veuillez uploader les résultats d'analyse (${req.test_type}) pour le patient ${req.patient_name}.`;
                
                await createNotification(
                    req.lab_id,
                    'Résultats en attente',
                    body,
                    'lab_request',
                    req.id.toString()
                );
            }
        } catch (err) {
            //silent 
        }
    });

    
}

module.exports = { initCronJobs };

