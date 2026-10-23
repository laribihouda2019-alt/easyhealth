const db = require('../config/db');
const { v4: uuidv4 } = require('uuid');

//initiate Video Call
 
async function initiateVideoCall(req, res, next) {
  try {
    const { recipientId, appointmentId } = req.body;
    const initiatorId = req.user.id;

    if (!recipientId) {
      return res.status(400).json({ error: 'Recipient ID is required' });
    }

    //generate unique room ID for video call
    const roomId = uuidv4();

    //create video call record
    const result = await db.query(
      `INSERT INTO video_calls 
       (appointment_id, initiator_id, recipient_id, call_status, room_id, started_at)
       VALUES ($1, $2, $3, $4, $5, NOW())
       RETURNING *`,
      [appointmentId, initiatorId, recipientId, 'initiated', roomId]
    );

    //create message for video call
    await db.query(
      `INSERT INTO messages 
       (sender_id, recipient_id, message_type, content, video_call_id, sent_at)
       VALUES ($1, $2, $3, $4, $5, NOW())
       RETURNING *`,
      [initiatorId, recipientId, 'video_call', 'Appel vidéo démarré', result.rows[0].id]
    );

    //get recipient details
    const recipientQuery = await db.query(
      'SELECT full_name, avatar_url FROM profiles WHERE id = $1',
      [recipientId]
    );

    //create notification for recipient
    await db.query(
      `INSERT INTO health_alerts 
       (user_id, alert_type, title, body, sent_by_ai, metadata)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        recipientId,
        'video_call_request',
        'Appel Vidéo Entrant',
        `Appel vidéo de ${req.user.fullName}`,
        false,
        JSON.stringify({ 
          callId: result.rows[0].id, 
          roomId, 
          initiatorId,
          initiatorName: req.user.fullName 
        })
      ]
    );

    res.status(201).json({
      success: true,
      videoCall: result.rows[0],
      recipient: recipientQuery.rows[0],
      message: 'Appel vidéo initié avec succès'
    });

  } catch (error) {
    console.error('Initiate video call error:', error);
    next(error);
  }
}

//accept Video Call
 
async function acceptVideoCall(req, res, next) {
  try {
    const { callId } = req.params;
    const userId = req.user.id;

    const result = await db.query(
      `UPDATE video_calls 
       SET call_status = 'ongoing', started_at = NOW()
       WHERE id = $1 AND recipient_id = $2
       RETURNING *`,
      [callId, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Video call not found or not authorized' });
    }

    const videoCall = result.rows[0];

    //notify initiator that call was accepted
    await db.query(
      `INSERT INTO health_alerts 
       (user_id, alert_type, title, body, sent_by_ai, metadata)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        videoCall.initiator_id,
        'video_call_accepted',
        'Appel Vidéo Accepté',
        `${req.user.fullName} a accepté votre appel vidéo`,
        false,
        JSON.stringify({ callId, roomId: videoCall.room_id })
      ]
    );

    res.json({
      success: true,
      videoCall,
      message: 'Appel vidéo accepté'
    });

  } catch (error) {
    console.error('Accept video call error:', error);
    next(error);
  }
}

//reject Video Call
 
async function rejectVideoCall(req, res, next) {
  try {
    const { callId } = req.params;
    const userId = req.user.id;

    const result = await db.query(
      `UPDATE video_calls 
       SET call_status = 'cancelled', ended_at = NOW()
       WHERE id = $1 AND recipient_id = $2
       RETURNING *`,
      [callId, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Video call not found or not authorized' });
    }

    const videoCall = result.rows[0];

    //notify initiator that call was rejected
    await db.query(
      `INSERT INTO health_alerts 
       (user_id, alert_type, title, body, sent_by_ai, metadata)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        videoCall.initiator_id,
        'video_call_rejected',
        'Appel Vidéo Refusé',
        `${req.user.fullName} a refusé votre appel vidéo`,
        false,
        JSON.stringify({ callId })
      ]
    );

    res.json({
      success: true,
      videoCall,
      message: 'Appel vidéo refusé'
    });

  } catch (error) {
    console.error('Reject video call error:', error);
    next(error);
  }
}

//end Video Call

async function endVideoCall(req, res, next) {
  try {
    const { callId } = req.params;
    const userId = req.user.id;

    const result = await db.query(
      `UPDATE video_calls 
       SET call_status = 'completed', ended_at = NOW()
       WHERE id = $1 AND (initiator_id = $2 OR recipient_id = $2)
       RETURNING *`,
      [callId, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Video call not found or not authorized' });
    }

    const videoCall = result.rows[0];

    //calculate duration
    if (videoCall.started_at) {
      const duration = Math.floor((new Date(videoCall.ended_at) - new Date(videoCall.started_at)) / 1000);
      
      await db.query(
        `UPDATE video_calls 
         SET duration_seconds = $1
         WHERE id = $2`,
        [duration, callId]
      );
    }

    //notify other participant
    const otherUserId = videoCall.initiator_id === userId ? videoCall.recipient_id : videoCall.initiator_id;
    
    await db.query(
      `INSERT INTO health_alerts 
       (user_id, alert_type, title, body, sent_by_ai, metadata)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        otherUserId,
        'video_call_ended',
        'Appel Vidéo Terminé',
        `L'appel vidéo a été terminé`,
        false,
        JSON.stringify({ callId, duration: videoCall.duration_seconds })
      ]
    );

    res.json({
      success: true,
      videoCall: { ...result.rows[0], duration_seconds: videoCall.duration_seconds },
      message: 'Appel vidéo terminé'
    });

  } catch (error) {
    console.error('End video call error:', error);
    next(error);
  }
}

//get Video Call Details
 
async function getVideoCall(req, res, next) {
  try {
    const { callId } = req.params;
    const userId = req.user.id;

    const result = await db.query(
      `SELECT vc.*, 
         initiator.full_name as initiator_name,
         initiator.avatar_url as initiator_avatar,
         recipient.full_name as recipient_name,
         recipient.avatar_url as recipient_avatar
       FROM video_calls vc
       JOIN profiles initiator ON vc.initiator_id = initiator.id
       JOIN profiles recipient ON vc.recipient_id = recipient.id
       WHERE vc.id = $1 AND (vc.initiator_id = $2 OR vc.recipient_id = $2)`,
      [callId, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Video call not found or not authorized' });
    }

    res.json({
      success: true,
      videoCall: result.rows[0]
    });

  } catch (error) {
    console.error('Get video call error:', error);
    next(error);
  }
}

//get User's Video Calls

async function getUserVideoCalls(req, res, next) {
  try {
    const userId = req.user.id;
    const { status, limit } = req.query;

    let query = `
      SELECT vc.*, 
         initiator.full_name as initiator_name,
         initiator.avatar_url as initiator_avatar,
         recipient.full_name as recipient_name,
         recipient.avatar_url as recipient_avatar
       FROM video_calls vc
       JOIN profiles initiator ON vc.initiator_id = initiator.id
       JOIN profiles recipient ON vc.recipient_id = recipient.id
       WHERE (vc.initiator_id = $1 OR vc.recipient_id = $1)
    `;
    
    const params = [userId];

    if (status) {
      query += ` AND vc.call_status = $${params.length + 1}`;
      params.push(status);
    }

    query += ` ORDER BY vc.created_at DESC`;

    if (limit) {
      query += ` LIMIT $${params.length + 1}`;
      params.push(parseInt(limit));
    }

    const result = await db.query(query, params);

    res.json({
      success: true,
      videoCalls: result.rows
    });

  } catch (error) {
    console.error('Get user video calls error:', error);
    next(error);
  }
}

//get Active Video Calls
 
async function getActiveVideoCalls(req, res, next) {
  try {
    const userId = req.user.id;

    const result = await db.query(
      `SELECT vc.*, 
         initiator.full_name as initiator_name,
         initiator.avatar_url as initiator_avatar,
         recipient.full_name as recipient_name,
         recipient.avatar_url as recipient_avatar
       FROM video_calls vc
       JOIN profiles initiator ON vc.initiator_id = initiator.id
       JOIN profiles recipient ON vc.recipient_id = recipient.id
       WHERE (vc.initiator_id = $1 OR vc.recipient_id = $1)
       AND vc.call_status IN ('initiated', 'ongoing')
       ORDER BY vc.created_at DESC`,
      [userId]
    );

    res.json({
      success: true,
      activeCalls: result.rows
    });

  } catch (error) {
    console.error('Get active video calls error:', error);
    next(error);
  }
}

//generate Video Call Token(for WebRTC)
 
async function generateVideoCallToken(req, res, next) {
  try {
    const { callId } = req.params;
    const userId = req.user.id;

    //verify user is part of the call
    const callCheck = await db.query(
      'SELECT id, room_id FROM video_calls WHERE id = $1 AND (initiator_id = $2 OR recipient_id = $2)',
      [callId, userId]
    );

    if (callCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Video call not found or not authorized' });
    }

    const videoCall = callCheck.rows[0];

    //generate token
    const token = generateWebRTCToken(userId, videoCall.room_id);

    res.json({
      success: true,
      token,
      roomId: videoCall.room_id,
      callId
    });

  } catch (error) {
    console.error('Generate video call token error:', error);
    next(error);
  }
}

//update Call Quality
 
async function updateCallQuality(req, res, next) {
  try {
    const { callId } = req.params;
    const { quality, issues, rating } = req.body;
    const userId = req.user.id;

    //verify user is part of the call
    const callCheck = await db.query(
      'SELECT id FROM video_calls WHERE id = $1 AND (initiator_id = $2 OR recipient_id = $2)',
      [callId, userId]
    );

    if (callCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Video call not found or not authorized' });
    }

    //update call metadata with quality information
    await db.query(
      `UPDATE video_calls 
       SET metadata = COALESCE(metadata, '{}'::jsonb) || $1::jsonb
       WHERE id = $2`,
      [
        JSON.stringify({
          quality,
          issues,
          rating,
          reportedBy: userId,
          reportedAt: new Date().toISOString()
        }),
        callId
      ]
    );

    res.json({
      success: true,
      message: 'Qualité d\'appel mise à jour'
    });

  } catch (error) {
    console.error('Update call quality error:', error);
    next(error);
  }
}


function generateWebRTCToken(userId, roomId) {
  
  const payload = {
    userId,
    roomId,
    timestamp: Date.now(),
    exp: Date.now() + (24 * 60 * 60 * 1000) // 24 hours
  };

  return Buffer.from(JSON.stringify(payload)).toString('base64');
}

module.exports = {
  initiateVideoCall,
  acceptVideoCall,
  rejectVideoCall,
  endVideoCall,
  getVideoCall,
  getUserVideoCalls,
  getActiveVideoCalls,
  generateVideoCallToken,
  updateCallQuality
};
