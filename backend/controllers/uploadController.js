const multer = require('multer');
const path = require('path');
const fs = require('fs');

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const dir = 'uploads/avatars';
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    cb(null, dir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, 'avatar-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ storage: storage });

async function uploadAvatar(req, res) {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }
    
    const avatarUrl = `/uploads/avatars/${req.file.filename}`;
    
    //update profile automatically if user is authenticated
    if (req.user) {
      const db = require('../config/db');
      await db.query('UPDATE public.profiles SET avatar_url = $1 WHERE id = $2', [avatarUrl, req.user.id]);
    }

    res.json({ success: true, avatarUrl });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ error: 'Failed to upload avatar' });
  }
}

module.exports = {
  upload,
  uploadAvatar
};
