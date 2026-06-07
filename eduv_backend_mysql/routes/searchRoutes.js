const express = require('express');
const router  = express.Router();
const db      = require('../config/db');
const { protect } = require('../middleware/authMiddleware');

router.get('/', protect, async (req, res) => {
  const q = (req.query.q || '').trim();
  if (!q) return res.json({ success: true, results: [] });

  const like = `%${q}%`;

  try {
    const studentsResult = await db.query(
      `SELECT id, full_name AS name, course AS subtitle, 'student' AS type
       FROM users
       WHERE role = 'student' AND (full_name ILIKE $1 OR course ILIKE $1)
       LIMIT 5`,
      [like]
    );

    const modulesResult = await db.query(
      `SELECT id, title AS name, description AS subtitle, 'module' AS type
       FROM modules
       WHERE title ILIKE $1 OR description ILIKE $1
       LIMIT 5`,
      [like]
    );

    const lessonsResult = await db.query(
      `SELECT id, title AS name, NULL AS subtitle, 'game' AS type
       FROM lessons
       WHERE title ILIKE $1
       LIMIT 5`,
      [like]
    );

    res.json({
      success: true,
      results: [
        ...studentsResult.rows,
        ...modulesResult.rows,
        ...lessonsResult.rows,
      ]
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Search failed' });
  }
});

module.exports = router;
