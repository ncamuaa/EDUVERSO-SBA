const express = require('express');
const { chat, listModels } = require('../controllers/aiTutorController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.get('/models', listModels);
router.post('/chat', protect, chat);

module.exports = router;