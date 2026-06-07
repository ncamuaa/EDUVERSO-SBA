const express = require('express');
const router = express.Router();
const {
  getLeaderboard,
  getMyStats,
  getGuessGameQuestions,
  submitGuessGame,
  getEscapePuzzles,
  submitEscapePuzzle,
  syncProgress,
} = require('../controllers/gameArenaController');

const { protect } = require('../middleware/authMiddleware');

// ✅ No auth needed — userId validated from body
router.post('/sync-progress', syncProgress);

// All other routes require authentication
router.use(protect);

// ─── SHARED ──────────────────────────────────────────────────────────────────
router.get('/leaderboard', getLeaderboard);
router.get('/my-stats/:userId', getMyStats);

// ─── GUESS GAME ───────────────────────────────────────────────────────────────
router.get('/guess-game/questions', getGuessGameQuestions);
router.post('/guess-game/submit', submitGuessGame);

// ─── ESCAPE THE PROGRAM ───────────────────────────────────────────────────────
router.get('/escape/puzzles', getEscapePuzzles);
router.post('/escape/submit', submitEscapePuzzle);

module.exports = router;