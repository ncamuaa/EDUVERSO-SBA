const express = require('express');
const router = express.Router();
const { getFeedback, createFeedback, deleteFeedback, getAllFeedback } = require('../controllers/feedbackController');
const { protect } = require('../middleware/authMiddleware');

router.get('/all', protect, getAllFeedback);      // ← must be before /:userId
router.get('/:userId', protect, getFeedback);
router.post('/', protect, createFeedback);
router.delete('/:id', protect, deleteFeedback);

module.exports = router;