const pool = require('../config/db');
const Anthropic = require('@anthropic-ai/sdk');

const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

// =============================================================
// GET /api/lessons/module/:moduleId
// =============================================================
exports.getLessonsByModule = async (req, res, next) => {
  try {
    const { moduleId } = req.params;

    const [lessons] = await pool.execute(
      `SELECT l.id, l.title, l.order_index,
              CASE WHEN up.completed = 1 THEN 1 ELSE 0 END AS completed
       FROM lessons l
       LEFT JOIN user_progress up
         ON up.lesson_id = l.id AND up.user_id = ?
       WHERE l.module_id = ?
       ORDER BY l.order_index ASC`,
      [req.user.id, moduleId]
    );

    return res.status(200).json({ success: true, lessons });
  } catch (error) {
    next(error);
  }
};

// =============================================================
// GET /api/lessons/:id
// =============================================================
exports.getLessonById = async (req, res, next) => {
  try {
    const lessonId = req.params.id;

    const [lessonRows] = await pool.execute(
      `SELECT l.id, l.title, l.module_id, l.order_index,
              m.title AS module_title, m.subject, m.grade_level, m.course
       FROM lessons l
       JOIN modules m ON m.id = l.module_id
       WHERE l.id = ?
       LIMIT 1`,
      [lessonId]
    );

    if (lessonRows.length === 0) {
      return res.status(404).json({ success: false, message: 'Lesson not found.' });
    }

    const lesson = lessonRows[0];

    let [content] = await pool.execute(
      `SELECT id, type, body, language, order_index
       FROM lesson_content
       WHERE lesson_id = ?
       ORDER BY order_index ASC`,
      [lessonId]
    );

    if (content.length === 0) {
      content = await _generateAndSaveContent(lesson, lessonId);
    }

    const [questions] = await pool.execute(
      `SELECT id, question, order_index
       FROM quiz_questions
       WHERE lesson_id = ?
       ORDER BY order_index ASC`,
      [lessonId]
    );

    const quiz = await Promise.all(
      questions.map(async (q) => {
        const [options] = await pool.execute(
          `SELECT id, option_text, order_index
           FROM quiz_options
           WHERE question_id = ?
           ORDER BY order_index ASC`,
          [q.id]
        );
        return { ...q, options };
      })
    );

    const [progressRows] = await pool.execute(
      `SELECT completed, quiz_score, completed_at
       FROM user_progress
       WHERE user_id = ? AND lesson_id = ?
       LIMIT 1`,
      [req.user.id, lessonId]
    );

    const progress =
      progressRows.length > 0
        ? progressRows[0]
        : { completed: 0, quiz_score: null, completed_at: null };

    return res.status(200).json({
      success: true,
      lesson: { ...lesson, content, quiz, progress },
    });
  } catch (error) {
    next(error);
  }
};

// =============================================================
// POST /api/lessons/:id/complete
// Body: { quizAnswers: { [questionId]: optionId } }
// =============================================================
exports.completeLesson = async (req, res, next) => {
  try {
    const lessonId = req.params.id;
    const { quizAnswers = {} } = req.body;

    let correct = 0;
    let total = 0;

    // correctAnswers: { questionId -> correctOptionId }  ← returned to client
    const correctAnswers = {};

    const questionIds = Object.keys(quizAnswers).map(Number);

    if (questionIds.length > 0) {
      const placeholders = questionIds.map(() => '?').join(',');

      // Fetch the correct option ID for every submitted question
      const [correctRows] = await pool.execute(
        `SELECT question_id, id AS option_id
         FROM quiz_options
         WHERE question_id IN (${placeholders}) AND is_correct = 1`,
        questionIds
      );

      // Build map and grade in one pass
      for (const row of correctRows) {
        correctAnswers[row.question_id] = row.option_id;
      }

      total = questionIds.length;
      correct = questionIds.filter(
        (qid) => correctAnswers[qid] !== undefined &&
                 correctAnswers[qid] === Number(quizAnswers[qid])
      ).length;
    }

    const score = total > 0 ? Math.round((correct / total) * 100) : 100;

    // Upsert progress
    await pool.execute(
      `INSERT INTO user_progress (user_id, lesson_id, completed, quiz_score, completed_at)
       VALUES (?, ?, 1, ?, NOW())
       ON DUPLICATE KEY UPDATE
         completed    = 1,
         quiz_score   = VALUES(quiz_score),
         completed_at = NOW()`,
      [req.user.id, lessonId, score]
    );

    // Award XP
    const xpGained = score === 100 ? 30 : 20;
    await pool.execute(
      `UPDATE users
       SET xp    = xp + ?,
           level = FLOOR((xp + ?) / 100) + 1
       WHERE id = ?`,
      [xpGained, xpGained, req.user.id]
    );

    console.log('[completeLesson] correctAnswers:', JSON.stringify(correctAnswers));
    return res.status(200).json({
      success: true,
      message: 'Lesson completed!',
      score,
      correct,
      total,
      xpGained,
      correctAnswers,   // { "12": 45, "13": 47, ... }  questionId → correct optionId
    });
  } catch (error) {
    next(error);
  }
};

// =============================================================
// PRIVATE — AI content generation + persist
// =============================================================
async function _generateAndSaveContent(lesson, lessonId) {
  const prompt = `You are an expert ${lesson.subject} teacher for Philippine Senior High School students (${lesson.grade_level}, ${lesson.course} strand).

Create lesson content for the topic: "${lesson.title}" (part of the module "${lesson.module_title}").

Respond ONLY with a JSON array of content blocks. No markdown fences. No explanation outside JSON.

Each block must follow one of these shapes:
- { "type": "text", "body": "markdown string", "order_index": N }
- { "type": "code", "body": "code string", "language": "dart|javascript|python|java", "order_index": N }

Requirements:
- 3-5 content blocks total
- Start with a clear text explanation
- Include at least one code example relevant to the topic
- Use simple, friendly language suitable for Grade 11/12 students
- Body text may use basic markdown (##, **, -, \\n)`;

  const response = await client.messages.create({
    model: 'claude-sonnet-4-20250514',
    max_tokens: 1500,
    messages: [{ role: 'user', content: prompt }],
  });

  const raw = response.content[0].text.trim();
  let blocks;

  try {
    blocks = JSON.parse(raw);
  } catch {
    blocks = [
      {
        type: 'text',
        body: `## ${lesson.title}\n\nContent is being prepared. Please check back soon.`,
        order_index: 1,
      },
    ];
  }

  for (const block of blocks) {
    await pool.execute(
      `INSERT INTO lesson_content (lesson_id, type, body, language, order_index)
       VALUES (?, ?, ?, ?, ?)`,
      [lessonId, block.type, block.body, block.language ?? null, block.order_index]
    );
  }

  return blocks;
}