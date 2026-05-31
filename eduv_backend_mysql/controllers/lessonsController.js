const pool = require('../config/db');

exports.getLessonsByModule = async (req, res, next) => {
  try {
    const { moduleId } = req.params;
    const result = await pool.query(
      `SELECT l.id, l.title, l.order_index,
              CASE WHEN up.completed = TRUE THEN 1 ELSE 0 END AS completed
       FROM lessons l
       LEFT JOIN user_progress up ON up.lesson_id = l.id AND up.user_id = $1
       WHERE l.module_id = $2
       ORDER BY l.order_index ASC`,
      [req.user.id, moduleId]
    );
    return res.status(200).json({ success: true, lessons: result.rows });
  } catch (error) { next(error); }
};

exports.getLessonById = async (req, res, next) => {
  try {
    const lessonId = req.params.id;
    const lessonResult = await pool.query(
      `SELECT l.id, l.title, l.content, l.module_id, l.order_index,
              m.title AS module_title, m.subject, m.grade_level, m.course
       FROM lessons l
       JOIN modules m ON m.id = l.module_id
       WHERE l.id = $1 LIMIT 1`,
      [lessonId]
    );
    if (lessonResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Lesson not found.' });
    }
    const lesson = lessonResult.rows[0];

    let contentResult = await pool.query(
      `SELECT id, type, body, language, order_index FROM lesson_content WHERE lesson_id = $1 ORDER BY order_index ASC`,
      [lessonId]
    );

    let content = contentResult.rows;
    if (content.length === 0) {
      const body = lesson.content || `## ${lesson.title}\n\nContent coming soon.`;
      await pool.query(
        `INSERT INTO lesson_content (lesson_id, type, body, language, order_index) VALUES ($1, 'text', $2, NULL, 1)`,
        [lessonId, body]
      );
      content = [{ id: 1, type: 'text', body, language: null, order_index: 1 }];
    }

    const questionsResult = await pool.query(
      `SELECT id, question, order_index FROM quiz_questions WHERE lesson_id = $1 ORDER BY order_index ASC`,
      [lessonId]
    );

    const quiz = await Promise.all(
      questionsResult.rows.map(async (q) => {
        const optionsResult = await pool.query(
          `SELECT id, option_text, order_index FROM quiz_options WHERE question_id = $1 ORDER BY order_index ASC`,
          [q.id]
        );
        return { ...q, options: optionsResult.rows };
      })
    );

    const progressResult = await pool.query(
      `SELECT completed, quiz_score, completed_at FROM user_progress WHERE user_id = $1 AND lesson_id = $2 LIMIT 1`,
      [req.user.id, lessonId]
    );

    const progress = progressResult.rows.length > 0
      ? progressResult.rows[0]
      : { completed: 0, quiz_score: null, completed_at: null };

    return res.status(200).json({ success: true, lesson: { ...lesson, content, quiz, progress } });
  } catch (error) { next(error); }
};

exports.completeLesson = async (req, res, next) => {
  try {
    const lessonId = req.params.id;
    const { quizAnswers = {} } = req.body;

    let correct = 0; let total = 0;
    const correctAnswers = {};
    const questionIds = Object.keys(quizAnswers).map(Number);

    if (questionIds.length > 0) {
      const placeholders = questionIds.map((_, i) => `$${i + 1}`).join(',');
      const correctRows = await pool.query(
        `SELECT question_id, id AS option_id FROM quiz_options WHERE question_id IN (${placeholders}) AND is_correct = TRUE`,
        questionIds
      );
      for (const row of correctRows.rows) { correctAnswers[row.question_id] = row.option_id; }
      total = questionIds.length;
      correct = questionIds.filter((qid) => correctAnswers[qid] !== undefined && correctAnswers[qid] === Number(quizAnswers[qid])).length;
    }

    const score = total > 0 ? Math.round((correct / total) * 100) : 100;

    await pool.query(
      `INSERT INTO user_progress (user_id, lesson_id, completed, quiz_score, completed_at)
       VALUES ($1, $2, TRUE, $3, NOW())
       ON CONFLICT (user_id, lesson_id) DO UPDATE SET completed = TRUE, quiz_score = EXCLUDED.quiz_score, completed_at = NOW()`,
      [req.user.id, lessonId, score]
    );

    const xpGained = score === 100 ? 30 : 20;
    await pool.query(
      `UPDATE users SET xp = xp + $1, level = FLOOR((xp + $1) / 100) + 1 WHERE id = $2`,
      [xpGained, req.user.id]
    );

    const userResult = await pool.query(
      `SELECT xp, level, (xp % 100) AS xpinlevel FROM users WHERE id = $1 LIMIT 1`,
      [req.user.id]
    );
    const updatedUser = userResult.rows[0] ?? { xp: 0, level: 1, xpinlevel: 0 };

    return res.status(200).json({
      success: true, message: 'Lesson completed!', score, correct, total, xpGained, correctAnswers,
      xp: updatedUser.xp, level: updatedUser.level, xpInLevel: updatedUser.xpinlevel,
    });
  } catch (error) { next(error); }
};