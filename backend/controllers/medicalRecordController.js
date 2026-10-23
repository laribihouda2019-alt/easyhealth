const medicalRecordService = require('../services/medicalRecordService');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

//configure multer for medical records
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const uploadDir = path.join(__dirname, '../uploads/records');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'record-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 20 * 1024 * 1024   //20MB limit
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

async function createRecord(req, res, next) {
    try {
        const { title, category, notes } = req.body;
        const patientId = req.user.id;
        const recordFile = req.file;

        if (!title || !category) {
            return res.status(400).json({ error: 'Titre et catégorie sont obligatoires' });
        }

        if (!recordFile) {
            return res.status(400).json({ error: 'Veuillez télécharger un document (PDF ou Image)' });
        }

        const record = await medicalRecordService.createRecord({
            patientId,
            title,
            category: category || 'Autre',
            fileUrl: `/uploads/records/${recordFile.filename}`,
            notes: notes || ''
        });

        res.status(201).json({ success: true, data: record });
    } catch (err) {
        console.error('Create Medical Record Error:', err);
        res.status(500).json({ 
            error: 'Erreur lors de la création du document', 
            details: err.message 
        });
    }
}

async function getMyRecords(req, res, next) {
    try {
        const records = await medicalRecordService.getRecordsByPatient(req.user.id);
        res.json({ success: true, data: records });
    } catch (err) {
        next(err);
    }
}

async function deleteRecord(req, res, next) {
    try {
        const { id } = req.params;
        const result = await medicalRecordService.deleteRecord(id, req.user.id);
        if (!result) return res.status(404).json({ error: 'Document non trouvé' });
        res.json({ success: true, message: 'Document supprimé' });
    } catch (err) {
        next(err);
    }
}

module.exports = {
    upload,
    createRecord,
    getMyRecords,
    deleteRecord
};
