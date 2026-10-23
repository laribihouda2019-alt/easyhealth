const { RtcTokenBuilder, RtcRole } = require('agora-token');
require('dotenv').config();

exports.generateToken = (req, res) => {
  //set response header
  res.header("Access-Control-Allow-Origin", "*");

  let channelName = req.query.channelName || req.body.channelName;
  if (!channelName) {
    return res.status(400).json({ error: 'channelName is required' });
  }

  //get UID
  let uid = req.query.uid || req.body.uid || 0;
  //parse UID to integer if possible, otherwise keep as string
  if (!isNaN(uid)) {
    uid = parseInt(uid, 10);
  }

  //get role
  let role = RtcRole.PUBLISHER;
  if (req.query.role === 'subscriber' || req.body.role === 'subscriber') {
    role = RtcRole.SUBSCRIBER;
  }

  //get expiration time
  let expireTime = req.query.expireTime || req.body.expireTime || 86400; // default 24 hours
  expireTime = parseInt(expireTime, 10);

  const currentTime = Math.floor(Date.now() / 1000);
  const privilegeExpireTime = currentTime + expireTime;

  const appID = process.env.AGORA_APP_ID;
  const appCertificate = process.env.AGORA_APP_CERTIFICATE;

  //returning a dummy token if the credentials are not configured yet,
  //avoid crashing the server loop for the developer.
  if (!appID || appID === 'your_agora_app_id_here') {
     console.error(" AGORA_APP_ID is missing or placeholder.");
     return res.status(500).json({ error: "Agora App ID not configured" });
  }

  if (!appCertificate || appCertificate === 'your_agora_app_certificate_here') {
     console.warn(" AGORA_APP_CERTIFICATE is missing. Returning an empty token (this only works if App Certificate is disabled in Agora console).");
     return res.json({ 
       token: "", 
       appID: appID,
       channelName 
     });
  }

  try {
    const token = RtcTokenBuilder.buildTokenWithUid(
      appID,
      appCertificate,
      channelName,
      uid,
      role,
      expireTime,
      privilegeExpireTime
    );
    return res.json({ token, appID, channelName, uid });
  } catch (err) {
    console.error("Agora Token Generation Error:", err);
    return res.status(500).json({ error: "Failed to generate token" });
  }
};
