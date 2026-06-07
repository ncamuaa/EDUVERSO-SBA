const express = require('express');
const {
  getDashboardStats,
  getWeeklyActivity,
  getTopStudents,
  getModuleCompletion,
} = require('../controllers/dashboardController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(protect);

router.get('/stats',             getDashboardStats);
router.get('/weekly-activity',   getWeeklyActivity);
router.get('/top-students',      getTopStudents);
router.get('/module-completion', getModuleCompletion);

module.exports = router;