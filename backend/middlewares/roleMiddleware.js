const { ROLES_REQUIRING_APPROVAL } = require('../config/constants');

function requireRole(allowedRoles = []) {
  return (req, res, next) => {
    const user = req.user;
    if (!user || !allowedRoles.includes(user.role)) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    next();
  };
} //if user have role

function requireApprovalForRestrictedRoles(req, res, next) {
  const user = req.user;
  if (!user) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  if (ROLES_REQUIRING_APPROVAL.includes(user.role) && !user.is_approved) {
    return res.status(403).json({
      error: 'Account pending approval. Please wait for admin verification.',
    });
  }
        //user autoriser from admin
  next();
}

module.exports = {
  requireRole,
  requireApprovalForRestrictedRoles,
};

