const db = require('../config/db');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { sendToUser } = require('../services/socketService');
const { createNotification } = require('./notificationController');

//configure multer for image uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const uploadDir = path.join(__dirname, '../uploads/prescriptions');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'prescription-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024      //5MB limit
  },
  fileFilter: function (req, file, cb) {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  }
});

//send message with optional image and delivery request
 
async function sendMessage(req, res, next) {
  try {
    const {
      recipientId: rId, recipient_id,
      content,
      appointmentId: aId, appointment_id,
      deliveryRequested: dReq, delivery_requested,
      deliveryAddress: dAdd, delivery_address
    } = req.body;

    const recipientId = rId || recipient_id;
    const appointmentId = aId || appointment_id;
    const deliveryRequested = dReq || delivery_requested;
    const deliveryAddress = dAdd || delivery_address;

    const senderId = req.user.id; //from auth middleware
    const imageFile = req.file;

    console.log(`[SendMessage] From: ${senderId}, To: ${recipientId}, Content: ${content.substring(0, 20)}...`);

    if (!recipientId || !content) {
      console.error('[SendMessage] Validation failed: missing recipientId or content');
      return res.status(400).json({
        error: 'recipientId and content are required'
      });
    }

    //verify recipient exists
    const recipientCheck = await db.query(
      'SELECT id, role FROM profiles WHERE id = $1',
      [recipientId]
    );

    if (recipientCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Recipient not found' });
    }

    //handle delivery requests (only for patient-pharmacy conversations)
    let isDeliveryRequested = false;
    if (deliveryRequested === 'true' || deliveryRequested === true) {
      const senderProfile = await db.query(
        'SELECT role FROM profiles WHERE id = $1',
        [senderId]
      );

      const senderRole = senderProfile.rows[0]?.role;
      const recipientRole = recipientCheck.rows[0]?.role;

      //only patients can request delivery from pharmacies
      const canRequestDelivery = (senderRole === 'patient' && recipientRole === 'pharmacy');

      if (!canRequestDelivery) {
        return res.status(400).json({
          error: 'Only patients can request delivery from pharmacies'
        });
      }

      if (!deliveryAddress) {
        return res.status(400).json({
          error: 'Delivery address is required when requesting delivery'
        });
      }
      isDeliveryRequested = true;
    }

    //prepare message data
    const messageData = {
      sender_id: senderId,
      recipient_id: recipientId,
      appointment_id: (appointmentId && appointmentId !== 'null') ? appointmentId : null,
      message_type: req.body.messageType || (imageFile ? 'image' : 'text'),
      content: content,
      image_url: imageFile ? `/uploads/prescriptions/${imageFile.filename}` : null,
      delivery_requested: isDeliveryRequested,
      delivery_address: isDeliveryRequested ? deliveryAddress : null,
      delivery_status: isDeliveryRequested ? 'pending' : null,
      metadata: JSON.stringify({
        hasImage: !!imageFile,
        deliveryRequested: isDeliveryRequested,
        originalFileName: imageFile?.originalname || null,
        ...(req.body.metadata || {})
      }),
      is_from_ai: false
    };

    //insert message in db
    let result;
    try {
      result = await db.query(
        `INSERT INTO public.messages (sender_id, recipient_id, appointment_id, message_type, content, 
          image_url, delivery_requested, delivery_address, delivery_status, metadata, is_from_ai)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
         RETURNING *`,
        [
          messageData.sender_id,
          messageData.recipient_id,
          messageData.appointment_id,
          messageData.message_type,
          messageData.content,
          messageData.image_url,
          messageData.delivery_requested,
          messageData.delivery_address,
          messageData.delivery_status,
          messageData.metadata,
          messageData.is_from_ai
        ]
      );
    } catch (dbError) {
      console.error('[SendMessage] DB INSERT ERROR:', dbError.message);
      return res.status(500).json({
        error: 'Database insertion failed',
        details: dbError.message
      });
    }

    const message = result.rows[0];

    //add full image URL if present
    if (message.image_url) {
      message.image_url = `${req.protocol}://${req.get('host')}${message.image_url}`;
    }

    //send notification to recipient
    console.log(`[SendMessage] Emitting socket 'new_message' to: ${recipientId}`);
    
    //create persistent notification which will ALSO emit a 'new_system_notification'
    await createNotification(
      recipientId,
      'Nouveau message',
      'Vous avez reçu un nouveau message',
      'chat',
      message.id.toString()
    );

    //keep the original socket emission for the active chat window to update live
    sendToUser(recipientId, 'new_message', {
      message: message,
      senderId: senderId
    });

    console.log(`[SendMessage] Success. Message ID: ${message.id}`);

    res.status(201).json({
      success: true,
      message: 'Message envoyé avec succès',
      data: message
    });

  } catch (error) {
    console.error('Send message error:', error);
    next(error);
  }
}

//get conversation between two users
 
async function getConversation(req, res, next) {
  try {
    const { otherUserId } = req.params;
    const currentUserId = req.user.id;

    //validate if otherUserId is a valid UUID to prevent crash
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(otherUserId)) {
      return res.status(200).json({
        success: true,
        data: [],
        message: 'Invalid user ID format'
      });
    }

    const result = await db.query(
      `SELECT m.*, 
        sender.full_name as sender_name, sender.role as sender_role,
        recipient.full_name as recipient_name, recipient.role as recipient_role
       FROM messages m
       LEFT JOIN profiles sender ON m.sender_id = sender.id
       LEFT JOIN profiles recipient ON m.recipient_id = recipient.id
       WHERE (m.sender_id = $1 AND m.recipient_id = $2) 
          OR (m.sender_id = $2 AND m.recipient_id = $1)
       ORDER BY m.sent_at ASC`,
      [currentUserId, otherUserId]
    );

    //add full image URLs
    const messages = result.rows.map(msg => {
      if (msg.image_url) {
        msg.image_url = `${req.protocol}://${req.get('host')}${msg.image_url}`;
      }
      return msg;
    });

    res.json({
      success: true,
      data: messages
    });

  } catch (error) {
    console.error('Get conversation error:', error);
    next(error);
  }
}

//get all conversations for current user
 
async function getMyConversations(req, res, next) {
  try {
    const currentUserId = req.user.id;

    //refined query to ensure we get the OTHER user's profile and last message correctly
    const result = await db.query(
      `SELECT DISTINCT ON (other_user.id) 
        other_user.id,
        other_user.full_name,
        other_user.role,
        other_user.avatar_url,
        m.content as last_message,
        m.sent_at as last_message_time,
        m.message_type as last_message_type,
        CASE WHEN m.sender_id = $1 THEN false ELSE true END as unread
       FROM (
         SELECT 
           CASE WHEN sender_id = $1 THEN recipient_id ELSE sender_id END as other_id,
           sender_id, recipient_id, content, sent_at, message_type
         FROM public.messages 
         WHERE sender_id = $1 OR recipient_id = $1
       ) m
       JOIN public.profiles other_user ON m.other_id = other_user.id
       WHERE other_user.id != $1
       ORDER BY other_user.id, m.sent_at DESC`,
      [currentUserId]
    );

    res.json({
      success: true,
      data: result.rows
    });

  } catch (error) {
    console.error('Get conversations error:', error);
    next(error);
  }
}

//update delivery status
 
async function updateDeliveryStatus(req, res, next) {
  try {
    const { messageId } = req.params;
    const { deliveryStatus } = req.body;
    const currentUserId = req.user.id;

    const validStatuses = ['pending', 'confirmed', 'delivered', 'cancelled'];
    if (!validStatuses.includes(deliveryStatus)) {
      return res.status(400).json({
        error: 'Invalid delivery status'
      });
    }

    //verify user is recipient(pharmacy)or sender(patient)
    const messageCheck = await db.query(
      'SELECT sender_id, recipient_id FROM messages WHERE id = $1',
      [messageId]
    );

    if (messageCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Message not found' });
    }

    const message = messageCheck.rows[0];
    if (message.sender_id !== currentUserId && message.recipient_id !== currentUserId) {
      return res.status(403).json({
        error: 'Not authorized to update this delivery'
      });
    }

    const result = await db.query(
      `UPDATE messages 
       SET delivery_status = $1, updated_at = NOW()
       WHERE id = $2
       RETURNING *`,
      [deliveryStatus, messageId]
    );

    res.json({
      success: true,
      message: 'Delivery status updated',
      data: result.rows[0]
    });

  } catch (error) {
    console.error('Update delivery status error:', error);
    next(error);
  }
}

//mark message as read
 
async function markAsRead(req, res, next) {
  try {
    const { messageId } = req.params;
    const currentUserId = req.user.id;

    const result = await db.query(
      `UPDATE messages 
       SET read_at = NOW()
       WHERE id = $1 AND recipient_id = $2
       RETURNING *`,
      [messageId, currentUserId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Message not found or not recipient' });
    }

    res.json({
      success: true,
      message: 'Message marked as read',
      data: result.rows[0]
    });

  } catch (error) {
    console.error('Mark as read error:', error);
    next(error);
  }
}

module.exports = {
  upload,
  sendMessage,
  getConversation,
  getMyConversations,
  updateDeliveryStatus,
  markAsRead
};
