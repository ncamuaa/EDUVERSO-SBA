const db = require('../config/db');

// ─── SHARED ──────────────────────────────────────────────────────────────────

// GET /api/game-arena/leaderboard?game_type=guess_game
const getLeaderboard = async (req, res) => {
  const { game_type } = req.query;

  const validTypes = ['escape_the_program', 'guess_game'];
  if (game_type && !validTypes.includes(game_type)) {
    return res.status(400).json({ success: false, message: 'Invalid game_type' });
  }

  try {
    const whereClause = game_type ? 'WHERE gs.game_type = ?' : '';
    const params = game_type ? [game_type] : [];

    const [rows] = await db.execute(
      `SELECT u.name AS player_name, gs.game_type, gs.high_score, gs.total_xp, gs.games_played
       FROM game_scores gs
       JOIN users u ON u.id = gs.user_id
       ${whereClause}
       ORDER BY gs.high_score DESC
       LIMIT 10`,
      params
    );

    res.status(200).json({ success: true, leaderboard: rows });
  } catch (err) {
    console.error('getLeaderboard error:', err);
    res.status(500).json({ success: false, message: err.message });
  }
};

// GET /api/game-arena/my-stats/:userId
const getMyStats = async (req, res) => {
  const { userId } = req.params;

  try {
    const [rows] = await db.execute(
      `SELECT game_type, high_score, total_xp, games_played, updated_at
       FROM game_scores
       WHERE user_id = ?`,
      [userId]
    );

    res.status(200).json({ success: true, stats: rows });
  } catch (err) {
    console.error('getMyStats error:', err);
    res.status(500).json({ success: false, message: err.message });
  }
};

// ─── GUESS GAME ───────────────────────────────────────────────────────────────

// GET /api/game-arena/guess-game/questions?difficulty=easy&limit=10
const getGuessGameQuestions = async (req, res) => {
  const { difficulty, limit = 10 } = req.query;

  try {
    const whereClause = difficulty ? 'WHERE difficulty = ?' : '';
    const params = difficulty ? [difficulty, parseInt(limit)] : [parseInt(limit)];

    const [questions] = await db.execute(
      `SELECT id, question, option_a, option_b, option_c, option_d, difficulty, xp_reward
       FROM guess_game_questions
       ${whereClause}
       ORDER BY RAND()
       LIMIT ?`,
      params
    );

    // Do NOT expose correct_option here — validated on submit
    res.status(200).json({ success: true, questions });
  } catch (err) {
    console.error('getGuessGameQuestions error:', err);
    res.status(500).json({ success: false, message: err.message });
  }
};

// POST /api/game-arena/guess-game/submit
// Body: { userId, answers: [{ questionId, selected }] }
const submitGuessGame = async (req, res) => {
  const { userId, answers } = req.body;

  if (!userId || !Array.isArray(answers) || answers.length === 0) {
    return res.status(400).json({ success: false, message: 'Missing required fields' });
  }

  try {
    const questionIds = answers.map((a) => a.questionId);
    const placeholders = questionIds.map(() => '?').join(',');

    const [questions] = await db.execute(
      `SELECT id, correct_option, xp_reward FROM guess_game_questions WHERE id IN (${placeholders})`,
      questionIds
    );

    const questionMap = {};
    questions.forEach((q) => (questionMap[q.id] = q));

    let score = 0;
    let xpEarned = 0;
    const results = answers.map((a) => {
      const q = questionMap[a.questionId];
      const correct = q && q.correct_option === a.selected;
      if (correct) {
        score++;
        xpEarned += q.xp_reward;
      }
      return {
        questionId: a.questionId,
        selected: a.selected,
        correct,
        correct_option: q?.correct_option,
      };
    });

    // Log session
    await db.execute(
      `INSERT INTO game_sessions (user_id, game_type, score, xp_earned, completed, completed_at)
       VALUES (?, 'guess_game', ?, ?, TRUE, NOW())`,
      [userId, score, xpEarned]
    );

    // Upsert high score
    await db.execute(
      `INSERT INTO game_scores (user_id, game_type, high_score, total_xp, games_played)
       VALUES (?, 'guess_game', ?, ?, 1)
       ON DUPLICATE KEY UPDATE
         high_score = GREATEST(high_score, VALUES(high_score)),
         total_xp = total_xp + VALUES(total_xp),
         games_played = games_played + 1`,
      [userId, score, xpEarned]
    );

    res.status(200).json({ success: true, score, xpEarned, total: answers.length, results });
  } catch (err) {
    console.error('submitGuessGame error:', err);
    res.status(500).json({ success: false, message: err.message });
  }
};

// ─── ESCAPE THE PROGRAM ───────────────────────────────────────────────────────

// GET /api/game-arena/escape/puzzles
const getEscapePuzzles = async (req, res) => {
  try {
    const [puzzles] = await db.execute(
      `SELECT id, level_number, title, description, puzzle_code, solution_hint, xp_reward
       FROM escape_puzzles
       ORDER BY level_number ASC`
    );

    res.status(200).json({ success: true, puzzles });
  } catch (err) {
    console.error('getEscapePuzzles error:', err);
    res.status(500).json({ success: false, message: err.message });
  }
};

// POST /api/game-arena/escape/submit
// Body: { userId, puzzleId, userOutput }
const submitEscapePuzzle = async (req, res) => {
  const { userId, puzzleId, userOutput } = req.body;

  if (!userId || !puzzleId || userOutput === undefined) {
    return res.status(400).json({ success: false, message: 'Missing required fields' });
  }

  try {
    const [rows] = await db.execute(
      `SELECT id, expected_output, xp_reward FROM escape_puzzles WHERE id = ?`,
      [puzzleId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Puzzle not found' });
    }

    const puzzle = rows[0];
    const passed = userOutput.trim() === puzzle.expected_output.trim();
    const xpEarned = passed ? puzzle.xp_reward : 0;

    // Log session
    await db.execute(
      `INSERT INTO game_sessions (user_id, game_type, score, xp_earned, completed, completed_at)
       VALUES (?, 'escape_the_program', ?, ?, ?, NOW())`,
      [userId, passed ? 1 : 0, xpEarned, passed]
    );

    if (passed) {
      // Upsert score
      await db.execute(
        `INSERT INTO game_scores (user_id, game_type, high_score, total_xp, games_played)
         VALUES (?, 'escape_the_program', 1, ?, 1)
         ON DUPLICATE KEY UPDATE
           high_score = GREATEST(high_score, 1),
           total_xp = total_xp + VALUES(total_xp),
           games_played = games_played + 1`,
        [userId, xpEarned]
      );
    }

    res.status(200).json({ success: true, passed, xpEarned });
  } catch (err) {
    console.error('submitEscapePuzzle error:', err);
    res.status(500).json({ success: false, message: err.message });
  }
};

module.exports = {
  getLeaderboard,
  getMyStats,
  getGuessGameQuestions,
  submitGuessGame,
  getEscapePuzzles,
  submitEscapePuzzle,
};