const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');

function generateToken(user) {
  return jwt.sign(
    { id: user.id, email: user.email, fullName: user.full_name },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
}

function computeLevel(xp) {
  const level = Math.floor(xp / 100) + 1;
  const xpInLevel = xp % 100;
  const progress = xpInLevel / 100;
  return { level, xpInLevel, progress };
}

exports.register = async (req, res, next) => {
  try {
    const { fullName, email, password } = req.body;
    if (!fullName || !email || !password) {
      return res.status(400).json({ success: false, message: 'Full name, email, and password are required.' });
    }
    const hashedPassword = await bcrypt.hash(password, 10);
    const result = await pool.query(
      `INSERT INTO users (full_name, email, password, xp, level, streak, last_login)
       VALUES ($1, $2, $3, 0, 1, 0, NULL) RETURNING id`,
      [fullName, email, hashedPassword]
    );
    const user = { id: result.rows[0].id, full_name: fullName, email };
    return res.status(201).json({
      success: true, message: 'User registered successfully.',
      token: generateToken(user),
      user: { id: user.id, fullName: user.full_name, email: user.email },
    });
  } catch (error) { next(error); }
};

exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const result = await pool.query(
      `SELECT id, full_name, email, password, xp, level, streak, last_login FROM users WHERE email = $1 LIMIT 1`,
      [email]
    );
    if (result.rows.length === 0) {
      return res.status(401).json({ success: false, message: 'Invalid email or password.' });
    }
    const user = result.rows[0];
    const passwordMatch = await bcrypt.compare(password, user.password);
    if (!passwordMatch) {
      return res.status(401).json({ success: false, message: 'Invalid email or password.' });
    }
    const today = new Date().toISOString().split('T')[0];
    const lastLogin = user.last_login ? new Date(user.last_login).toISOString().split('T')[0] : null;
    let newStreak = user.streak;
    let newXp = user.xp;
    if (lastLogin !== today) {
      newXp += 10;
      if (lastLogin === null) { newStreak = 1; }
      else {
        const diffDays = (new Date(today) - new Date(lastLogin)) / (1000 * 60 * 60 * 24);
        if (diffDays === 1) { newStreak += 1; } else if (diffDays > 1) { newStreak = 1; }
      }
      const { level: newLevel } = computeLevel(newXp);
      await pool.query(
        `UPDATE users SET xp = $1, level = $2, streak = $3, last_login = $4 WHERE id = $5`,
        [newXp, newLevel, newStreak, today, user.id]
      );
    }
    const { level, xpInLevel, progress } = computeLevel(newXp);
    return res.status(200).json({
      success: true, message: 'Login successful.',
      token: generateToken(user),
      user: { id: user.id, fullName: user.full_name, email: user.email, xp: newXp, xpInLevel, level, progress, streak: newStreak },
    });
  } catch (error) { next(error); }
};

exports.profile = async (req, res, next) => {
  try {
    const result = await pool.query(
      `SELECT id, full_name, email, xp, level, streak, profile_image, course, section, created_at FROM users WHERE id = $1 LIMIT 1`,
      [req.user.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }
    const user = result.rows[0];
    const { level, xpInLevel, progress } = computeLevel(user.xp);
    return res.status(200).json({
      success: true,
      user: { id: user.id, fullName: user.full_name, email: user.email, xp: user.xp, xpInLevel, level, progress, streak: user.streak, profileImage: user.profile_image, course: user.course, section: user.section, createdAt: user.created_at },
    });
  } catch (error) { next(error); }
};

exports.updateProfile = async (req, res, next) => {
  try {
    const { fullName, username } = req.body;
    if (!fullName || fullName.trim() === '') {
      return res.status(400).json({ success: false, message: 'Full name is required.' });
    }
    await pool.query(`UPDATE users SET full_name = $1 WHERE id = $2`, [fullName.trim(), req.user.id]);
    return res.status(200).json({ success: true, message: 'Profile updated successfully.', user: { fullName: fullName.trim(), username: username?.trim() ?? null } });
  } catch (error) { next(error); }
};

exports.updateEmail = async (req, res, next) => {
  try {
    const { email } = req.body;
    if (!email || !email.includes('@')) {
      return res.status(400).json({ success: false, message: 'A valid email address is required.' });
    }
    const existing = await pool.query(`SELECT id FROM users WHERE email = $1 AND id != $2 LIMIT 1`, [email.trim(), req.user.id]);
    if (existing.rows.length > 0) {
      return res.status(409).json({ success: false, message: 'This email is already in use.' });
    }
    await pool.query(`UPDATE users SET email = $1 WHERE id = $2`, [email.trim(), req.user.id]);
    const newToken = jwt.sign(
      { id: req.user.id, email: email.trim(), fullName: req.user.fullName },
      process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );
    return res.status(200).json({ success: true, message: 'Email updated successfully.', token: newToken, email: email.trim() });
  } catch (error) { next(error); }
};

exports.updatePassword = async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = req.body;
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ success: false, message: 'Current password and new password are required.' });
    }
    if (newPassword.length < 8) {
      return res.status(400).json({ success: false, message: 'New password must be at least 8 characters.' });
    }
    const result = await pool.query(`SELECT password FROM users WHERE id = $1 LIMIT 1`, [req.user.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }
    const match = await bcrypt.compare(currentPassword, result.rows[0].password);
    if (!match) {
      return res.status(401).json({ success: false, message: 'Current password is incorrect.' });
    }
    const hashed = await bcrypt.hash(newPassword, 10);
    await pool.query(`UPDATE users SET password = $1 WHERE id = $2`, [hashed, req.user.id]);
    return res.status(200).json({ success: true, message: 'Password updated successfully.' });
  } catch (error) { next(error); }
};

exports.updatePhone = async (req, res, next) => {
  try {
    const { phone } = req.body;
    if (!phone || phone.trim() === '') {
      return res.status(400).json({ success: false, message: 'Phone number is required.' });
    }
    await pool.query(`UPDATE users SET phone = $1 WHERE id = $2`, [phone.trim(), req.user.id]);
    return res.status(200).json({ success: true, message: 'Phone number updated successfully.', phone: phone.trim() });
  } catch (error) { next(error); }
};

exports.updateProfileImage = async (req, res, next) => {
  try {
    const { profileImage } = req.body;
    await pool.query(`UPDATE users SET profile_image = $1 WHERE id = $2`, [profileImage, req.user.id]);
    return res.status(200).json({ success: true, message: 'Profile image updated successfully.', profileImage });
  } catch (error) { next(error); }
};
exports.adminLogin = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Email and password are required.' });
    }

    const result = await pool.query(
      `SELECT id, full_name, email, password, role FROM users WHERE email = $1 LIMIT 1`,
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ success: false, message: 'Invalid email or password.' });
    }

    const user = result.rows[0];

    if (user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Access denied. Admins only.' });
    }

    const passwordMatch = await bcrypt.compare(password, user.password);
    if (!passwordMatch) {
      return res.status(401).json({ success: false, message: 'Invalid email or password.' });
    }

    return res.status(200).json({
      success: true,
      message: 'Admin login successful.',
      token: generateToken(user),
      user: { id: user.id, fullName: user.full_name, email: user.email, role: user.role },
    });
  } catch (error) { next(error); }
};