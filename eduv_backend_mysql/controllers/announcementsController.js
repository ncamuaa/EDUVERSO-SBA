const db = require('../config/db');

const getAnnouncements = async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 1;
  const offset = (page - 1) * limit;

  try {
    const [[{ total }]] = await db.execute(
      `SELECT COUNT(*) AS total FROM announcements`
    );

    const [rows] = await db.execute(
      `SELECT * FROM announcements ORDER BY created_at DESC LIMIT ? OFFSET ?`,
      [limit, offset]
    );

    res.json({
      success: true,
      data: rows,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (err) {
    console.error('getAnnouncements error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

const createAnnouncement = async (req, res) => {
  const { tag, badge, title, body } = req.body;

  if (!tag || !badge || !title || !body) {
    return res.status(400).json({ success: false, message: 'Missing required fields' });
  }

  try {
    const [result] = await db.execute(
      `INSERT INTO announcements (tag, badge, title, body) VALUES (?, ?, ?, ?)`,
      [tag, badge, title, body]
    );
    res.status(201).json({ success: true, announcementId: result.insertId });
  } catch (err) {
    console.error('createAnnouncement error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

module.exports = { getAnnouncements, createAnnouncement };