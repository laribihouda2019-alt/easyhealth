const messageService = require('../services/messageService');

async function sendMessage(req, res, next) {
  try {
    const { recipientId, appointmentId, messageType, content, isFromAi, metadata } = req.body;
    const message = await messageService.sendMessage({
      senderId: req.user.id,
      recipientId,
      appointmentId,
      messageType,
      content,
      isFromAi,
      metadata
    });
    res.status(201).json(message);
  } catch (err) {
    next(err);
  }
}

async function getConversation(req, res, next) {
  try {
    const { userId } = req.params;
    const messages = await messageService.getConversation(req.user.id, userId);
    res.json(messages);
  } catch (err) {
    next(err);
  }
}

async function getMyMessages(req, res, next) {
  try {
    const messages = await messageService.getUserMessages(req.user.id);
    res.json(messages);
  } catch (err) {
    next(err);
  }
}

async function getUnreadMessages(req, res, next) {
  try {
    const messages = await messageService.getUnreadMessages(req.user.id);
    res.json(messages);
  } catch (err) {
    next(err);
  }
}

async function markMessageAsRead(req, res, next) {
  try {
    const { messageId } = req.params;
    const updated = await messageService.markAsRead(messageId, req.user.id);
    res.json(updated);
  } catch (err) {
    next(err);
  }
}

async function markConversationAsRead(req, res, next) {
  try {
    const { userId } = req.params;
    await messageService.markConversationAsRead(req.user.id, userId);
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
}

async function getAppointmentMessages(req, res, next) {
  try {
    const { appointmentId } = req.params;
    const messages = await messageService.getAppointmentMessages(appointmentId);
    res.json(messages);
  } catch (err) {
    next(err);
  }
}

async function deleteMessage(req, res, next) {
  try {
    const { messageId } = req.params;
    const updated = await messageService.deleteMessage(messageId, req.user.id);
    res.json(updated);
  } catch (err) {
    next(err);
  }
}

module.exports = {
  sendMessage,
  getConversation,
  getMyMessages,
  getUnreadMessages,
  markMessageAsRead,
  markConversationAsRead,
  getAppointmentMessages,
  deleteMessage,
};
