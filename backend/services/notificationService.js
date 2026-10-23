async function sendInAppNotification(userId, { title, body, alertType = 'general', metadata = {} }) {
  return {
    userId,
    title,
    body,
    alertType,
    metadata,
  };
}

async function sendEmailNotification(email, payload) {
  return { email, ...payload };
}

async function sendSmsNotification(phone, payload) {
  return { phone, ...payload };
}

module.exports = {
  sendInAppNotification,
  sendEmailNotification,
  sendSmsNotification,
};


