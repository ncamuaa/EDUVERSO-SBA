const db = require('../config/db');

const getAnnouncements = async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const offset = (page - 1) * limit;

  try {
    const countResult = await db.query(`SELECT COUNT(*) AS total FROM announcements`);
    const total = parseInt(countResult.rows[0].total);

    const rows = await db.query(
      `SELECT * FROM announcements ORDER BY created_at DESC LIMIT $1 OFFSET $2`,
      [limit, offset]
    );

    res.json({
      success: true,
      data: rows.rows,
      pagination: { total, page, limit, totalPages: Math.ceil(total / limit) },
    });
  } catch (err) {
    console.error('getAnnouncements error:', err);
    res.status(500).json({ success: false, message: err.message });
  }
};

const createAnnouncement = async (req, res) => {
  const { tag, badge, title, body } = req.body;
  if (!tag || !badge || !title || !body) {
    return res.status(400).json({ success: false, message: 'Missing required fields' });
  }
  try {
    const result = await db.query(
      `INSERT INTO announcements (tag, badge, title, body) VALUES ($1, $2, $3, $4) RETURNING id`,
      [tag, badge, title, body]
    );
    res.status(201).json({ success: true, announcementId: result.rows[0].id });
  } catch (err) {
    console.error('createAnnouncement error:', err);
    res.status(500).json({ success: false, message: err.message });
  }
};

module.exports = { getAnnouncements, createAnnouncement };