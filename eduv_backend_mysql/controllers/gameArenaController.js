const db = require('../config/db');

const getLeaderboard = async (req, res) => {
  const { game_type } = req.query;
  const validTypes = ['escape_the_program', 'guess_game'];
  if (game_type && !validTypes.includes(game_type)) {
    return res.status(400).json({ success: false, message: 'Invalid game_type' });
  }
  try {
    const params = [];
    let whereClause = '';
    if (game_type) { whereClause = 'WHERE gs.game_type = $1'; params.push(game_type); }

    const result = await db.query(
      `SELECT u.full_name AS player_name, gs.game_type, gs.high_score, gs.total_xp, gs.games_played
       FROM game_scores gs
       JOIN users u ON u.id = gs.user_id
       ${whereClause}
       ORDER BY gs.high_score DESC LIMIT 10`,
      params
    );
    res.status(200).json({ success: true, leaderboard: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

const getMyStats = async (req, res) => {
  const { userId } = req.params;
  try {
    const result = await db.query(
      `SELECT game_type, high_score, total_xp, games_played, updated_at FROM game_scores WHERE user_id = $1`,
      [userId]
    );
    res.status(200).json({ success: true, stats: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

const getGuessGameQuestions = async (req, res) => {
  const { difficulty, limit = 10 } = req.query;
  try {
    const params = [];
    let whereClause = '';
    if (difficulty) { whereClause = 'WHERE difficulty = $1'; params.push(difficulty); }
    params.push(parseInt(limit));

    const result = await db.query(
      `SELECT id, question, option_a, option_b, option_c, option_d, difficulty, xp_reward
       FROM guess_game_questions ${whereClause}
       ORDER BY RANDOM() LIMIT $${params.length}`,
      params
    );
    res.status(200).json({ success: true, questions: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

const submitGuessGame = async (req, res) => {
  const { userId, answers } = req.body;
  if (!userId || !Array.isArray(answers) || answers.length === 0) {
    return res.status(400).json({ success: false, message: 'Missing required fields' });
  }
  try {
    const questionIds = answers.map((a) => a.questionId);
    const placeholders = questionIds.map((_, i) => `$${i + 1}`).join(',');

    const qResult = await db.query(
      `SELECT id, correct_option, xp_reward FROM guess_game_questions WHERE id IN (${placeholders})`,
      questionIds
    );

    const questionMap = {};
    qResult.rows.forEach((q) => (questionMap[q.id] = q));

    let score = 0; let xpEarned = 0;
    const results = answers.map((a) => {
      const q = questionMap[a.questionId];
      const correct = q && q.correct_option === a.selected;
      if (correct) { score++; xpEarned += q.xp_reward; }
      return { questionId: a.questionId, selected: a.selected, correct, correct_option: q?.correct_option };
    });

    await db.query(
      `INSERT INTO game_sessions (user_id, game_type, score, xp_earned, completed, completed_at)
       VALUES ($1, 'guess_game', $2, $3, TRUE, NOW())`,
      [userId, score, xpEarned]
    );

    await db.query(
      `INSERT INTO game_scores (user_id, game_type, high_score, total_xp, games_played)
       VALUES ($1, 'guess_game', $2, $3, 1)
       ON CONFLICT (user_id, game_type) DO UPDATE SET
         high_score = GREATEST(game_scores.high_score, EXCLUDED.high_score),
         total_xp = game_scores.total_xp + EXCLUDED.total_xp,
         games_played = game_scores.games_played + 1`,
      [userId, score, xpEarned]
    );

    res.status(200).json({ success: true, score, xpEarned, total: answers.length, results });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

const getEscapePuzzles = async (req, res) => {
  try {
    const result = await db.query(
      `SELECT id, level_number, title, description, puzzle_code, solution_hint, xp_reward
       FROM escape_puzzles ORDER BY level_number ASC`
    );
    res.status(200).json({ success: true, puzzles: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

const submitEscapePuzzle = async (req, res) => {
  const { userId, puzzleId, userOutput } = req.body;
  if (!userId || !puzzleId || userOutput === undefined) {
    return res.status(400).json({ success: false, message: 'Missing required fields' });
  }
  try {
    const result = await db.query(
      `SELECT id, expected_output, xp_reward FROM escape_puzzles WHERE id = $1`,
      [puzzleId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Puzzle not found' });
    }
    const puzzle = result.rows[0];
    const passed = userOutput.trim() === puzzle.expected_output.trim();
    const xpEarned = passed ? puzzle.xp_reward : 0;

    await db.query(
      `INSERT INTO game_sessions (user_id, game_type, score, xp_earned, completed, completed_at)
       VALUES ($1, 'escape_the_program', $2, $3, $4, NOW())`,
      [userId, passed ? 1 : 0, xpEarned, passed]
    );

    if (passed) {
      await db.query(
        `INSERT INTO game_scores (user_id, game_type, high_score, total_xp, games_played)
         VALUES ($1, 'escape_the_program', 1, $2, 1)
         ON CONFLICT (user_id, game_type) DO UPDATE SET
           high_score = GREATEST(game_scores.high_score, 1),
           total_xp = game_scores.total_xp + EXCLUDED.total_xp,
           games_played = game_scores.games_played + 1`,
        [userId, xpEarned]
      );
    }
    res.status(200).json({ success: true, passed, xpEarned });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

module.exports = { getLeaderboard, getMyStats, getGuessGameQuestions, submitGuessGame, getEscapePuzzles, submitEscapePuzzle };
const syncProgress = async (req, res) => {
  const { userId, totalXp, highScore, gameType = 'overall' } = req.body;
  if (!userId) return res.status(400).json({ success: false, message: 'Missing userId' });
  try {
    await db.query(
      `INSERT INTO game_scores (user_id, game_type, high_score, total_xp, games_played)
       VALUES ($1, $2, $3, $4, 1)
       ON CONFLICT (user_id, game_type) DO UPDATE SET
         high_score = GREATEST(game_scores.high_score, EXCLUDED.high_score),
         total_xp = GREATEST(game_scores.total_xp, EXCLUDED.total_xp),
         games_played = game_scores.games_played + 1,
         updated_at = NOW()`,
      [userId, gameType, highScore ?? 0, totalXp ?? 0]
    );
    res.status(200).json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

module.exports = { getLeaderboard, getMyStats, getGuessGameQuestions, submitGuessGame, getEscapePuzzles, submitEscapePuzzle, syncProgress };
