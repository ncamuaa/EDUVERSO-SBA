const db = require('../config/db');

// ── GET /api/dashboard/stats ──────────────────────────────────────────────────
exports.getDashboardStats = async (req, res) => {
  try {
    // Total students
    const totalRes = await db.query(
      `SELECT COUNT(*) FROM users WHERE role = 'student' OR role IS NULL`
    );
    const totalStudents = parseInt(totalRes.rows[0].count);

    // Students from previous month for delta
    const prevRes = await db.query(
      `SELECT COUNT(*) FROM users
       WHERE (role = 'student' OR role IS NULL)
       AND created_at < DATE_TRUNC('month', NOW())`
    );
    const prevMonthStudents = parseInt(prevRes.rows[0].count);
    const totalStudentsDelta = prevMonthStudents > 0
      ? '+' + (((totalStudents - prevMonthStudents) / prevMonthStudents) * 100).toFixed(1) + '%'
      : '+0%';

    // Active this week
    const activeRes = await db.query(
      `SELECT COUNT(*) FROM users
       WHERE (role = 'student' OR role IS NULL)
       AND last_login >= NOW() - INTERVAL '7 days'`
    );
    const activeThisWeek = parseInt(activeRes.rows[0].count);

    // Total games played
    const gamesRes = await db.query(
      `SELECT SUM(games_played) FROM game_scores`
    );
    const gamesPlayed = parseInt(gamesRes.rows[0].sum) || 0;

    // Games played last week for delta
    const gamesLastWeekRes = await db.query(
      `SELECT COUNT(*) FROM game_sessions
       WHERE completed_at >= NOW() - INTERVAL '14 days'
       AND completed_at < NOW() - INTERVAL '7 days'`
    );
    const gamesLastWeek = parseInt(gamesLastWeekRes.rows[0].count) || 1;
    const gamesThisWeekRes = await db.query(
      `SELECT COUNT(*) FROM game_sessions
       WHERE completed_at >= NOW() - INTERVAL '7 days'`
    );
    const gamesThisWeek = parseInt(gamesThisWeekRes.rows[0].count) || 0;
    const gamesDelta = '+' + (((gamesThisWeek - gamesLastWeek) / gamesLastWeek) * 100).toFixed(1) + '%';

    // Active modules (lessons count)
    const modulesRes = await db.query(`SELECT COUNT(*) FROM lessons`);
    const activeModules = parseInt(modulesRes.rows[0].count) || 0;

    // Avg score (high_score average from game_scores)
    const avgRes = await db.query(
      `SELECT ROUND(AVG(high_score), 1) FROM game_scores`
    );
    const avgScore = parseFloat(avgRes.rows[0].round) || 0;

    // Active now (logged in within last 15 minutes) — approximated by today
    const activeNowRes = await db.query(
      `SELECT COUNT(*) FROM users
       WHERE (role = 'student' OR role IS NULL)
       AND last_login >= NOW() - INTERVAL '1 day'`
    );
    const activeNow = parseInt(activeNowRes.rows[0].count) || 0;

    return res.json({
      success: true,
      stats: {
        totalStudents,
        totalStudentsDelta,
        activeThisWeek,
        gamesPlayed,
        gamesDelta,
        activeModules,
        avgScore,
        activeNow,
      }
    });
  } catch (err) {
    console.error('[dashboardController] getDashboardStats:', err);
    return res.status(500).json({ success: false, message: err.message });
  }
};

// ── GET /api/dashboard/weekly-activity ───────────────────────────────────────
exports.getWeeklyActivity = async (req, res) => {
  try {
    const result = await db.query(
      `SELECT
         TO_CHAR(completed_at, 'Dy') AS day,
         COUNT(*) AS games,
         COUNT(DISTINCT user_id) AS students
       FROM game_sessions
       WHERE completed_at >= NOW() - INTERVAL '7 days'
       GROUP BY TO_CHAR(completed_at, 'Dy'), DATE(completed_at)
       ORDER BY DATE(completed_at) ASC`
    );

    // Fill missing days
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const dataMap = {};
    result.rows.forEach(r => { dataMap[r.day] = { games: parseInt(r.games), students: parseInt(r.students) }; });
    const activity = days.map(day => ({
      day,
      games:    dataMap[day]?.games    || 0,
      students: dataMap[day]?.students || 0,
    }));

    return res.json({ success: true, activity });
  } catch (err) {
    console.error('[dashboardController] getWeeklyActivity:', err);
    return res.status(500).json({ success: false, message: err.message });
  }
};

// ── GET /api/dashboard/top-students ──────────────────────────────────────────
exports.getTopStudents = async (req, res) => {
  try {
    const result = await db.query(
      `SELECT u.full_name, u.course, u.xp,
              COALESCE(MAX(gs.high_score), 0) AS top_score
       FROM users u
       LEFT JOIN game_scores gs ON gs.user_id = u.id
       WHERE u.role = 'student' OR u.role IS NULL
       GROUP BY u.id, u.full_name, u.course, u.xp
       ORDER BY u.xp DESC
       LIMIT 5`
    );

    return res.json({ success: true, students: result.rows });
  } catch (err) {
    console.error('[dashboardController] getTopStudents:', err);
    return res.status(500).json({ success: false, message: err.message });
  }
};

// ── GET /api/dashboard/module-completion ─────────────────────────────────────
exports.getModuleCompletion = async (req, res) => {
  try {
    const result = await db.query(
      `SELECT m.title AS name,
              COUNT(up.id) AS completions
       FROM modules m
       LEFT JOIN lessons l ON l.module_id = m.id
       LEFT JOIN user_progress up ON up.lesson_id = l.id AND up.completed = true
       GROUP BY m.id, m.title
       ORDER BY completions DESC
       LIMIT 5`
    );

    return res.json({ success: true, modules: result.rows });
  } catch (err) {
    console.error('[dashboardController] getModuleCompletion:', err);
    return res.status(500).json({ success: false, message: err.message });
  }
};