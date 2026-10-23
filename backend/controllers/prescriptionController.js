const db = require('../config/db');
const { v4: uuidv4 } = require('uuid');

//creates a new prescription record(ordonnance)
 
async function createPrescription(req, res, next) {
    try {
        const { patientId, appointmentId, medications, notes } = req.body;
        const doctorId = req.user.id;

        if (!patientId || !medications || !Array.isArray(medications)) {
            return res.status(400).json({ error: 'Patient ID and valid medications list are required' });
        }

        //fetch Doctor and Patient names for persistence
        const profileQuery = `
            SELECT id, full_name, specialty, role FROM public.profiles 
            WHERE id IN ($1, $2)
        `;
        const profiles = await db.query(profileQuery, [doctorId, patientId]);
        
        const doctorProfile = profiles.rows.find(p => p.id === doctorId);
        const patientProfile = profiles.rows.find(p => p.id === patientId);

        //professional Fallback Logic: full_name -> email prefix -> default
        const getProfessionalName = (profile, defaultName) => {
            if (profile && profile.full_name && profile.full_name.trim().length > 0) {
                return profile.full_name;
            }
            if (profile && profile.email) {
                return profile.email.split('@')[0];
            }
            return defaultName;
        };

        const doctorName = getProfessionalName(doctorProfile, 'Médecin');
        const docSpecialty = doctorProfile ? doctorProfile.specialty : (req.user.specialty || 'Urologue');
        const patientName = getProfessionalName(patientProfile, 'Patient');

        const verificationCode = `ORD-${Date.now()}-${Math.floor(Math.random() * 1000)}`;

        const query = `
            INSERT INTO public.prescriptions (
                doctor_id, 
                patient_id, 
                appointment_id, 
                medications, 
                verification_code, 
                notes,
                doctor_name,
                patient_name,
                doctor_specialty
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            RETURNING *
        `;

        const values = [
            doctorId,
            patientId,
            appointmentId || null,
            JSON.stringify(medications),
            verificationCode,
            notes || null,
            doctorName,
            patientName,
            docSpecialty
        ];

        const result = await db.query(query, values);
        
        res.status(201).json({
            success: true,
            data: result.rows[0]
        });

    } catch (error) {
        console.error('Create Prescription Error:', error);
        res.status(500).json({ error: 'Failed to create prescription', details: error.message });
    }
}

//gets a specific prescription by ID
 
async function getPrescriptionById(req, res, next) {
    try {
        const { id } = req.params;
        
        const query = `
            SELECT r.*, 
                   d.full_name as doctor_name, d.specialty as doctor_specialty, d.logo_url as doctor_logo,
                   p.full_name as patient_name
            FROM public.prescriptions r
            JOIN public.profiles d ON r.doctor_id = d.id
            JOIN public.profiles p ON r.patient_id = p.id
            WHERE r.id = $1
        `;
        
        const result = await db.query(query, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Prescription not found' });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });

    } catch (error) {
        console.error('Get Prescription Error:', error);
        res.status(500).json({ error: 'Failed to fetch prescription' });
    }
}

//gets all prescriptions for a patient(can be called by patient or doctor)
 
async function getMyPrescriptions(req, res, next) {
    try {
        const userId = req.user.id;
        const role = req.user.role;

        let query;
        let values;

        if (role === 'patient') {
            query = `
                SELECT r.*, d.full_name as doctor_name, d.specialty as doctor_specialty
                FROM public.prescriptions r
                JOIN public.profiles d ON r.doctor_id = d.id
                WHERE r.patient_id = $1
                ORDER BY r.prescription_date DESC
            `;
            values = [userId];
        } else if (role === 'doctor') {
            query = `
                SELECT r.*, p.full_name as patient_name
                FROM public.prescriptions r
                JOIN public.profiles p ON r.patient_id = p.id
                WHERE r.doctor_id = $1
                ORDER BY r.prescription_date DESC
            `;
            values = [userId];
        } else {
            return res.status(403).json({ error: 'Unauthorized role' });
        }

        const result = await db.query(query, values);

        res.json({
            success: true,
            data: result.rows
        });

    } catch (error) {
        console.error('Get My Prescriptions Error:', error);
        res.status(500).json({ error: 'Failed to fetch prescriptions' });
    }
}

//gets a specific prescription by verification code(for QR scanning)
 
async function getPrescriptionByCode(req, res, next) {
    try {
        const { code } = req.params;
        
        const query = `
            SELECT r.*, 
                   d.full_name as doctor_name, d.specialty as doctor_specialty, d.logo_url as doctor_logo,
                   p.full_name as patient_name
            FROM public.prescriptions r
            JOIN public.profiles d ON r.doctor_id = d.id
            JOIN public.profiles p ON r.patient_id = p.id
            WHERE r.verification_code = $1
        `;
        
        const result = await db.query(query, [code]);

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Ordonnance non trouvée ou code invalide' });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });

    } catch (error) {
        console.error('Verify Prescription Error:', error);
        res.status(500).json({ error: 'Failed to verify prescription' });
    }
}

module.exports = {
    createPrescription,
    getPrescriptionById,
    getMyPrescriptions,
    getPrescriptionByCode
};
