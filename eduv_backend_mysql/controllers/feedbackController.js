const db = require('../config/db');

// GET /api/feedback/:userId — fetch feedback for a student
const getFeedback = async (req, res) => {
  const { userId } = req.params;
  const { search } = req.query;

  try {
    let query = `
      SELECT f.*, u.full_name AS giver_name
      FROM feedback f
      JOIN users u ON f.giver_id = u.id
      WHERE f.receiver_id = ?
    `;
    const params = [userId];

    if (search) {
      query += ` AND (f.title LIKE ? OR f.body LIKE ?)`;
      params.push(`%${search}%`, `%${search}%`);
    }

    query += ` ORDER BY f.created_at DESC`;

    const [rows] = await db.execute(query, params);
    res.json({ success: true, data: rows });
  } catch (err) {
    console.error('getFeedback error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// POST /api/feedback — submit feedback
const createFeedback = async (req, res) => {
  const { receiver_id, giver_id, category, title, body, rating } = req.body;

  if (!receiver_id || !giver_id || !title || !body || !rating) {
    return res.status(400).json({ success: false, message: 'Missing required fields' });
  }
  if (rating < 1 || rating > 5) {
    return res.status(400).json({ success: false, message: 'Rating must be 1–5' });
  }
  if (receiver_id === giver_id) {
    return res.status(400).json({ success: false, message: 'Cannot give feedback to yourself' });
  }

  try {
    const [result] = await db.execute(
      `INSERT INTO feedback (receiver_id, giver_id, category, title, body, rating)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [receiver_id, giver_id, category || 'General', title, body, rating]
    );
    res.status(201).json({ success: true, feedbackId: result.insertId });
  } catch (err) {
    console.error('createFeedback error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// DELETE /api/feedback/:id — delete a feedback entry (giver only)
const deleteFeedback = async (req, res) => {
  const { id } = req.params;
  const { giver_id } = req.body;

  try {
    const [result] = await db.execute(
      `DELETE FROM feedback WHERE id = ? AND giver_id = ?`,
      [id, giver_id]
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Not found or unauthorized' });
    }
    res.json({ success: true, message: 'Deleted' });
  } catch (err) {
    console.error('deleteFeedback error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

module.exports = { getFeedback, createFeedback, deleteFeedback };