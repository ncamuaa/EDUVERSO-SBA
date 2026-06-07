const pool = require('../config/db');

exports.getAllStudents = async (req, res, next) => {
  try {
    const result = await pool.query(
      `SELECT id, full_name, email, username, course, section, grade_level,
              xp, level, streak, profile_image, role, last_login, created_at
       FROM users
       WHERE role = 'student' OR role IS NULL
       ORDER BY created_at DESC`
    );
    return res.status(200).json({ success: true, students: result.rows });
  } catch (error) { next(error); }
};

exports.getStudentById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      `SELECT id, full_name, email, username, course, section, grade_level,
              xp, level, streak, profile_image, role, last_login, created_at
       FROM users WHERE id = $1 LIMIT 1`,
      [id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Student not found.' });
    }
    return res.status(200).json({ success: true, student: result.rows[0] });
  } catch (error) { next(error); }
};

exports.getStudentStats = async (req, res, next) => {
  try {
    const total = await pool.query(
      `SELECT COUNT(*) FROM users WHERE role = 'student' OR role IS NULL`
    );
    const activeThisWeek = await pool.query(
      `SELECT COUNT(*) FROM users
       WHERE (role = 'student' OR role IS NULL)
       AND last_login >= NOW() - INTERVAL '7 days'`
    );
    const avgScore = await pool.query(
      `SELECT ROUND(AVG(xp), 1) as avg_xp FROM users
       WHERE role = 'student' OR role IS NULL`
    );
    return res.status(200).json({
      success: true,
      stats: {
        total: parseInt(total.rows[0].count),
        activeThisWeek: parseInt(activeThisWeek.rows[0].count),
        avgXp: parseFloat(avgScore.rows[0].avg_xp) || 0,
      }
    });
  } catch (error) { next(error); }
};

exports.deleteStudent = async (req, res, next) => {
  try {
    const { id } = req.params;
    await pool.query(`DELETE FROM users WHERE id = $1`, [id]);
    return res.status(200).json({ success: true, message: 'Student deleted successfully.' });
  } catch (error) { next(error); }
};

// ✅ Called from Flutter on login — no auth needed
exports.updateLastLogin = async (req, res) => {
  const { userId } = req.body;
  if (!userId) return res.status(400).json({ success: false, message: 'Missing userId' });
  try {
    await pool.query(
      `UPDATE users SET last_login = NOW() WHERE id = $1`,
      [userId]
    );
    res.status(200).json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};