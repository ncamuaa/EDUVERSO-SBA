const express = require('express');
const {
  getLessonsByModule,
  getLessonById,
  completeLesson,
} = require('../controllers/lessonsController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.get('/module/:moduleId', protect, getLessonsByModule); // list for a module
router.get('/:id',             protect, getLessonById);       // single lesson + quiz
router.post('/:id/complete',   protect, completeLesson);      // mark done + submit quiz

module.exports = router;