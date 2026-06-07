const pool = require('../config/db');

exports.getModules = async (req, res, next) => {
  try {
    const { subject, grade, course } = req.query;
    const conditions = []; const params = [];

    if (subject) { conditions.push(`subject = $${params.length + 1}`); params.push(subject); }
    if (grade)   { conditions.push(`grade_level = $${params.length + 1}`); params.push(grade); }
    if (course)  { conditions.push(`course = $${params.length + 1}`); params.push(course); }

    const where = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const modulesResult = await pool.query(
      `SELECT id, title, description, subject, grade_level, course, order_index
       FROM modules ${where}
       ORDER BY grade_level ASC, course ASC, subject ASC, order_index ASC`,
      params
    );

    const subjectsResult = await pool.query(`SELECT DISTINCT subject FROM modules ORDER BY subject ASC`);
    const gradesResult   = await pool.query(`SELECT DISTINCT grade_level FROM modules ORDER BY grade_level ASC`);
    const coursesResult  = await pool.query(`SELECT DISTINCT course FROM modules ORDER BY course ASC`);

    return res.status(200).json({
      success: true,
      modules: modulesResult.rows,
      filters: {
        subjects: subjectsResult.rows.map((r) => r.subject),
        grades: gradesResult.rows.map((r) => r.grade_level),
        courses: coursesResult.rows.map((r) => r.course),
      },
    });
  } catch (error) { next(error); }
};

exports.getModuleById = async (req, res, next) => {
  try {
    const result = await pool.query(
      `SELECT id, title, description, subject, grade_level, course, order_index FROM modules WHERE id = $1 LIMIT 1`,
      [req.params.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Module not found.' });
    }
    return res.status(200).json({ success: true, module: result.rows[0] });
  } catch (error) { next(error); }
};
exports.updateModule = async (req, res, next) => {
  try {
    const { title, description, subject, grade_level, course, order_index } = req.body;
    const result = await pool.query(
      `UPDATE modules SET title=$1, description=$2, subject=$3, grade_level=$4, course=$5, order_index=$6
       WHERE id=$7 RETURNING *`,
      [title, description, subject, grade_level, course, order_index, req.params.id]
    );
    if (result.rows.length === 0)
      return res.status(404).json({ success: false, message: 'Module not found.' });
    return res.status(200).json({ success: true, module: result.rows[0] });
  } catch (error) { next(error); }
};