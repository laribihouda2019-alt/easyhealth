const jwt = require('jsonwebtoken');
const db = require('../config/db');
const ENV = require('../config/env');

//verifies JWT token and attaches user to request
 
async function authMiddleware(req, res, next) {
  try {
    //get token from header
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: 'Access denied. No token provided.',
        code: 'NO_TOKEN'
      });
    }

    const token = authHeader.substring(7); //remove 'Bearer ' prefix

    //verify token
    let decoded;
    try {
      decoded = jwt.verify(token, ENV.JWT_SECRET || 'easyhealth_jwt_secret_key');
    } catch (jwtError) {
      if (jwtError.name === 'TokenExpiredError') {
        return res.status(401).json({
          error: 'Token expired. Please login again.',
          code: 'TOKEN_EXPIRED'
        });
      } else if (jwtError.name === 'JsonWebTokenError') {
        return res.status(401).json({
          error: 'Invalid token. Please login again.',
          code: 'INVALID_TOKEN'
        });
      } else {
        return res.status(401).json({
          error: 'Token verification failed.',
          code: 'TOKEN_VERIFICATION_FAILED'
        });
      }
    }

    //get user profile from database
    const userResult = await db.query(
      'SELECT id, full_name, email, role, is_approved, metadata FROM profiles WHERE id = $1',
      [decoded.userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(401).json({
        error: 'User not found. Please login again.',
        code: 'USER_NOT_FOUND'
      });
    }

    const user = userResult.rows[0];

    //check if user is approved(for professional roles)
    if (!user.is_approved && user.role !== 'patient') {
      return res.status(403).json({
        error: 'Account not approved. Please wait for verification.',
        code: 'ACCOUNT_NOT_APPROVED'
      });
    }

    //attach user to request
    req.user = {
      id: user.id,
      fullName: user.full_name,
      email: user.email,
      role: user.role,
      isApproved: user.is_approved,
      metadata: user.metadata
    };

    next();

  } catch (error) {
    console.error('Auth middleware error:', error);
    return res.status(500).json({
      error: 'Internal server error during authentication.',
      code: 'AUTH_ERROR'
    });
  }
}

//optional authentication attaches user if token exists, but doesn't require it
 
async function optionalAuthMiddleware(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next(); //no token,continue without user
    }

    const token = authHeader.substring(7);

    try {
      const decoded = jwt.verify(token, ENV.JWT_SECRET || 'easyhealth_jwt_secret_key');
      
      const userResult = await db.query(
        'SELECT id, full_name, email, role, is_approved, metadata FROM profiles WHERE id = $1',
        [decoded.userId]
      );

      if (userResult.rows.length > 0) {
        const user = userResult.rows[0];
        req.user = {
          id: user.id,
          fullName: user.full_name,
          email: user.email,
          role: user.role,
          isApproved: user.is_approved,
          metadata: user.metadata
        };
      }
    } catch (jwtError) {
      //ignore JWT errors for optional auth
    }

    next();

  } catch (error) {
    console.error('Optional auth middleware error:', error);
    next(); //continue without user on error
  }
}

//role-based access control middleware
 
function requireRole(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        error: 'Authentication required.',
        code: 'AUTH_REQUIRED'
      });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        error: 'Access denied. Insufficient permissions.',
        code: 'INSUFFICIENT_PERMISSIONS',
        required: allowedRoles,
        current: req.user.role
      });
    }

    next();
  };
}

//admin-only middleware
 
const requireAdmin = requireRole('admin');

//professional roles middleware(doctor, pharmacy, lab)
 
const requireProfessional = requireRole('doctor', 'pharmacy', 'lab');

module.exports = {
  authMiddleware,
  optionalAuthMiddleware,
  requireRole,
  requireAdmin,
  requireProfessional,
  requireAuth: authMiddleware
};
