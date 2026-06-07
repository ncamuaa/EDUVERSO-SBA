const db = require('../config/db');

const getFeedback = async (req, res) => {
  const { userId } = req.params;
  const { search } = req.query;
  try {
    let query = `
      SELECT f.id, f.content AS body, f.rating, f.created_at,
             'General' AS category, f.content AS title, '' AS giver_name
      FROM feedback f
      WHERE f.user_id = $1
    `;
    const params = [userId];
    if (search) {
      query += ` AND f.content ILIKE $2`;
      params.push(`%${search}%`);
    }
    query += ` ORDER BY f.created_at DESC`;
    const result = await db.query(query, params);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error('getFeedback error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

const createFeedback = async (req, res) => {
  const { user_id, content, rating } = req.body;
  if (!user_id || !content || !rating) {
    return res.status(400).json({ success: false, message: 'Missing required fields' });
  }
  if (rating < 1 || rating > 5) {
    return res.status(400).json({ success: false, message: 'Rating must be 1–5' });
  }
  try {
    const result = await db.query(
      `INSERT INTO feedback (user_id, content, rating) VALUES ($1, $2, $3) RETURNING id`,
      [user_id, content, rating]
    );
    res.status(201).json({ success: true, feedbackId: result.rows[0].id });
  } catch (err) {
    console.error('createFeedback error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

const deleteFeedback = async (req, res) => {
  const { id } = req.params;
  try {
    const result = await db.query(`DELETE FROM feedback WHERE id = $1`, [id]);
    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Not found' });
    }
    res.json({ success: true, message: 'Deleted' });
  } catch (err) {
    console.error('deleteFeedback error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

module.exports = { getFeedback, createFeedback, deleteFeedback };
const getAllFeedback = async (req, res) => {
  try {
    const result = await db.query(`
      SELECT f.id, f.content AS body, f.rating, f.created_at,
             u.full_name AS student_name, u.course, u.section
      FROM feedback f
      LEFT JOIN users u ON f.user_id = u.id
      ORDER BY f.created_at DESC
    `);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error('getAllFeedback error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

module.exports = { getFeedback, createFeedback, deleteFeedback, getAllFeedback };