const express = require('express');
const {
  getAllStudents,
  getStudentById,
  getStudentStats,
  deleteStudent,
  updateLastLogin,
} = require('../controllers/studentsController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// ✅ No auth needed — called from Flutter on login
router.post('/update-last-login', updateLastLogin);

router.get('/',        protect, getAllStudents);
router.get('/stats',   protect, getStudentStats);
router.get('/:id',     protect, getStudentById);
router.delete('/:id',  protect, deleteStudent);

module.exports = router;