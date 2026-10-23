const orderService = require('../services/orderService');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const db = require('../config/db');
const { sendToUser } = require('../services/socketService');
const { createNotification } = require('./notificationController');

//configure multer for order uploads(prescriptions and results)
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const uploadDir = path.join(__dirname, '../uploads/orders');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'order-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024   //10MB limit
  },
  fileFilter: function (req, file, cb) {
    const allowedTypes = ['image/jpeg', 'image/png', 'application/pdf'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Only PDF and image files are allowed'), false);
    }
  }
});

//MEDICATION ORDERS
 
async function createMedicationOrder(req, res, next) {
    try {
        const { pharmacyId, items, totalAmount, deliveryAddress, paymentMethod } = req.body;
        const patientId = req.user.id;
        const prescriptionFile = req.file;

        if (!pharmacyId) {
            return res.status(400).json({ error: 'ID de pharmacie manquant' });
        }

        //more robust item parsing for Multipart/form-data
        let finalItems = [];
        try {
            if (typeof items === 'string') {
                finalItems = JSON.parse(items);
            } else if (Array.isArray(items)) {
                finalItems = items;
            } else if (items) {
                finalItems = [items];
            }
        } catch (pErr) {
            console.warn('Items parsing failed, using raw string:', items);
            finalItems = [{ name: items || 'Commande' }];
        }

        //fetch patient's actual address from profile if not provided
        let finalAddress = deliveryAddress;
        if (!finalAddress) {
            const profile = await db.query('SELECT address FROM profiles WHERE id = $1', [patientId]);
            finalAddress = profile.rows[0]?.address || 'Adresse non spécifiée';
        }

        const numericalAmount = parseFloat(totalAmount) || 0;

        const order = await orderService.createMedicationOrder({
            patientId,
            pharmacyId,
            items: finalItems,
            totalAmount: numericalAmount,
            deliveryAddress: finalAddress,
            prescriptionUrl: prescriptionFile ? `/uploads/orders/${prescriptionFile.filename}` : null,
            paymentMethod: paymentMethod || 'cod'
        });

        //trigger Real-time Notification for Pharmacy
        await createNotification(
            pharmacyId,
            'Nouvelle commande',
            'Nouvelle demande de médicament reçue',
            'med_order',
            order.id.toString()
        );

        res.status(201).json({ success: true, data: order });
    } catch (err) {
        console.error('Create Medication Order Error:', err);
        res.status(500).json({ error: 'Erreur lors de la création de la commande', details: err.message });
    }
}

async function getMyOrders(req, res, next) {
    try {
        const orders = await orderService.getPatientMedicationOrders(req.user.id);
        res.json({ success: true, data: orders });
    } catch (err) {
        next(err);
    }
}

async function getPharmacyOrders(req, res, next) {
    try {
        //ensure user is a pharmacy
        if (req.user.role !== 'pharmacy') {
            return res.status(403).json({ error: 'Accès réservé aux pharmacies' });
        }
        const orders = await orderService.getPharmacyOrders(req.user.id);
        res.json({ success: true, data: orders });
    } catch (err) {
        next(err);
    }
}

//lAB REQUESTS
 
async function createLabRequest(req, res, next) {
    try {
        const { labId, serviceIds, paymentMethod, scheduledAt } = req.body;
        const patientId = req.user.id;

        if (!labId || !serviceIds || !Array.isArray(serviceIds) || serviceIds.length === 0) {
            return res.status(400).json({ error: 'Sélectionnez au moins un service de laboratoire.' });
        }

        //fetch prices and names for selected services to ensure security and data integrity
        const { rows: selectedServices } = await db.query(
            'SELECT id, test_name, price FROM public.lab_services WHERE lab_id = $1 AND id = ANY($2)',
            [labId, serviceIds]
        );

        if (selectedServices.length === 0) {
            return res.status(400).json({ error: 'Services non trouvés ou invalides pour ce laboratoire.' });
        }

        const totalAmount = selectedServices.reduce((sum, service) => sum + parseFloat(service.price), 0);
        const joinedTestNames = selectedServices.map(s => s.test_name).join(', ');

        const request = await orderService.createLabRequest({
            patientId,
            labId,
            testType: joinedTestNames,
            amount: totalAmount,
            paymentMethod: paymentMethod || 'cod',
            scheduledAt: scheduledAt || null
        });

        //trigger Real-time Notification for Laboratory
        await createNotification(
            labId,
            'Nouvelle demande labo',
            'Nouvelle demande d\'analyse reçue',
            'lab_request',
            request.id.toString()
        );

        res.status(201).json({ 
            success: true, 
            data: {
                ...request,
                test_names: joinedTestNames,
                amount: totalAmount
            } 
        });
    } catch (err) {
        console.error('Create Lab Request Error:', err);
        res.status(500).json({ error: 'Erreur lors de la création de la demande labo', details: err.message });
    }
}

async function getMyLabRequests(req, res, next) {
    try {
        const requests = await orderService.getPatientLabRequests(req.user.id);
        res.json({ success: true, data: requests });
    } catch (err) {
        next(err);
    }
}

async function getLabRequests(req, res, next) {
    try {
        if (req.user.role !== 'lab') {
            return res.status(403).json({ error: 'Accès réservé aux laboratoires' });
        }
        const requests = await orderService.getLabRequests(req.user.id);
        res.json({ success: true, data: requests });
    } catch (err) {
        next(err);
    }
}

async function updateOrderStatus(req, res, next) {
    try {
        const { id } = req.params;
        const { status } = req.body;
        const updatedOrder = await orderService.updateMedicationOrderStatus(id, status);
        res.json({ success: true, data: updatedOrder });
    } catch (err) {
        next(err);
    }
}

module.exports = {
    upload,
    createMedicationOrder,
    getMyOrders,
    getPharmacyOrders,
    updateOrderStatus,
    createLabRequest,
    getMyLabRequests,
    getLabRequests
};
