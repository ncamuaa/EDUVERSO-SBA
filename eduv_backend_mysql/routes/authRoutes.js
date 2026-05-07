const express = require('express');
const {
  register,
  login,
  profile,
  updateProfile,
  updateEmail,
  updatePassword,
  updatePhone,
} = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// ── Auth ──────────────────────────────────────────────────────
router.post('/register', register);
router.post('/login', login);

// ── Profile (read) ────────────────────────────────────────────
router.get('/profile', protect, profile);

// ── Settings (write) — all require a valid JWT ─────────────────
router.put('/profile',  protect, updateProfile);   // name / username
router.put('/email',    protect, updateEmail);     // change email
router.put('/password', protect, updatePassword);  // change password
router.put('/phone',    protect, updatePhone);     // add / update phone

module.exports = router;