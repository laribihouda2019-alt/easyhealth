const labService = require('../services/labService');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

//ensure dedicated local folder for lab results
const uploadDir = path.join(__dirname, '../uploads/lab_results');
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'result-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  fileFilter: function (req, file, cb) {
    const allowedTypes = ['image/jpeg', 'image/png', 'application/pdf'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Seuls les fichiers PDF et images sont autorisés'), false);
    }
  }
});

async function getLabServices(req, res, next) {
    try {
        const { labId } = req.params;
        const services = await labService.getServices(labId);
        res.json(services);
    } catch(err) {
        next(err);
    }
}

async function addLabService(req, res, next) {
    try {
        const { testName, price } = req.body;
        
        if (req.user.role !== 'lab') {
            return res.status(403).json({ error: 'Accès réservé aux laboratoires' });
        }
        
        const service = await labService.addService({ 
            labId: req.user.id, 
            testName, 
            price 
        });
        
        res.status(201).json(service);
    } catch(err) {
        next(err);
    }
}

async function uploadTestResult(req, res, next) {
    try {
        const { requestId, status } = req.body;
        const filePath = req.file ? `/uploads/lab_results/${req.file.filename}` : null;
        
        if (!filePath) {
            return res.status(400).json({ error: 'Fichier manquant' });
        }
        
        const testStatus = status || 'Ready'; //default to Ready if a file is uploaded
        
        const result = await labService.uploadResult({ 
            requestId, 
            filePath, 
            status: testStatus 
        });
        
        res.status(201).json({
            success: true,
            data: result,
            message: 'Résultat téléchargé avec succès'
        });
    } catch(err) {
        next(err);
    }
}

async function getTestResults(req, res, next) {
    try {
        const { requestId } = req.params;
        const results = await labService.getResultsForRequest(requestId);
        res.json(results);
    } catch(err) {
        next(err);
    }
}

async function updateRequestStatus(req, res, next) {
    try {
        const { requestId } = req.params;
        const { status } = req.body;
        
        if (req.user.role !== 'lab') {
            return res.status(403).json({ error: 'Accès réservé aux laboratoires' });
        }
        
        const result = await labService.updateRequestStatus(requestId, status, req.user.id);
        res.json({ success: true, data: result });
    } catch(err) {
        next(err);
    }
}

module.exports = {
    upload,
    getLabServices,
    addLabService,
    uploadTestResult,
    getTestResults,
    updateRequestStatus
};
