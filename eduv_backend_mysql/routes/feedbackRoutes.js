const express = require('express');
const router = express.Router();
const { getFeedback, createFeedback, deleteFeedback } = require('../controllers/feedbackController');
const { protect } = require('../middleware/authMiddleware');

router.get('/:userId', protect, getFeedback);
router.post('/', protect, createFeedback);
router.delete('/:id', protect, deleteFeedback);

module.exports = router;