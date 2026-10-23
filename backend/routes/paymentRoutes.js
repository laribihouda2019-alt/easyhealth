const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const chargilyV2Controller = require('../controllers/chargilyV2Controller');
const ccpPaymentController = require('../controllers/ccpPaymentController');
const { authMiddleware } = require('../middlewares/auth');

//multer config for proofs
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/proofs/');
    },
    filename: (req, file, cb) => {
        cb(null, `proof_${Date.now()}${path.extname(file.originalname)}`);
    }
});

const upload = multer({ storage });

//chargily
router.post('/chargily-v2/checkout', authMiddleware, chargilyV2Controller.createCheckout);
router.post('/webhook/chargily-v2', chargilyV2Controller.handleWebhook);

//CCP
router.post('/ccp/upload', authMiddleware, upload.single('proof'), ccpPaymentController.uploadCcpProof);

module.exports = router;
