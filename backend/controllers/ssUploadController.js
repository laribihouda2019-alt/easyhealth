const multer = require('multer');
const path = require('path');
const fs = require('fs');

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const dir = 'uploads/chifa';
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    cb(null, dir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, 'chifa-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ 
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 },     //5MB limit
});

async function uploadDocuments(req, res) {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ error: 'No files uploaded' });
    }
    
    const fileUrls = req.files.map(file => `uploads/chifa/${file.filename}`);
    res.json({ success: true, fileUrls });
  } catch (error) {
    console.error('Chifa Document Upload error:', error);
    res.status(500).json({ error: 'Failed to upload documents' });
  }
}

module.exports = {
  upload,
  uploadDocuments
};
