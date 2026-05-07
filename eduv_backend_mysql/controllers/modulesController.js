const pool = require('../config/db');

// =============================================================
// GET /api/modules
// Query params (all optional):
//   subject    — filter by subject name
//   grade      — filter by grade_level  (e.g. "Grade 11")
//   course     — filter by course        (e.g. "STEM")
// Returns modules + distinct filter options for the Flutter UI.
// =============================================================
exports.getModules = async (req, res, next) => {
  try {
    const { subject, grade, course } = req.query;

    // Build the WHERE clause dynamically
    const conditions = [];
    const params = [];

    if (subject) {
      conditions.push('subject = ?');
      params.push(subject);
    }
    if (grade) {
      conditions.push('grade_level = ?');
      params.push(grade);
    }
    if (course) {
      conditions.push('course = ?');
      params.push(course);
    }

    const where =
      conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const [modules] = await pool.execute(
      `SELECT id, title, description, subject, grade_level, course, order_index
       FROM modules
       ${where}
       ORDER BY grade_level ASC, course ASC, subject ASC, order_index ASC`,
      params
    );

    // Always return the full set of distinct filter values so
    // the Flutter dropdowns can populate without a second request.
    const [subjects] = await pool.execute(
      `SELECT DISTINCT subject FROM modules ORDER BY subject ASC`
    );
    const [grades] = await pool.execute(
      `SELECT DISTINCT grade_level FROM modules ORDER BY grade_level ASC`
    );
    const [courses] = await pool.execute(
      `SELECT DISTINCT course FROM modules ORDER BY course ASC`
    );

    return res.status(200).json({
      success: true,
      modules,
      filters: {
        subjects: subjects.map((r) => r.subject),
        grades: grades.map((r) => r.grade_level),
        courses: courses.map((r) => r.course),
      },
    });
  } catch (error) {
    next(error);
  }
};

// =============================================================
// GET /api/modules/:id
// Returns a single module by ID.
// =============================================================
exports.getModuleById = async (req, res, next) => {
  try {
    const [rows] = await pool.execute(
      `SELECT id, title, description, subject, grade_level, course, order_index
       FROM modules
       WHERE id = ?
       LIMIT 1`,
      [req.params.id]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Module not found.',
      });
    }

    return res.status(200).json({ success: true, module: rows[0] });
  } catch (error) {
    next(error);
  }
};