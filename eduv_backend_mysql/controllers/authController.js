const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');

function generateToken(user) {
  return jwt.sign(
    {
      id: user.id,
      email: user.email,
      fullName: user.full_name,
    },
    process.env.JWT_SECRET,
    {
      expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    }
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
      return res.status(400).json({
        success: false,
        message: 'Full name, email, and password are required.',
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const [result] = await pool.execute(
      `INSERT INTO users (full_name, email, password, xp, level, streak, last_login)
       VALUES (?, ?, ?, 0, 1, 0, NULL)`,
      [fullName, email, hashedPassword]
    );

    const user = {
      id: result.insertId,
      full_name: fullName,
      email,
    };

    return res.status(201).json({
      success: true,
      message: 'User registered successfully.',
      token: generateToken(user),
      user: {
        id: user.id,
        fullName: user.full_name,
        email: user.email,
      },
    });
  } catch (error) {
    next(error);
  }
};

exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    const [users] = await pool.execute(
      `SELECT id, full_name, email, password, xp, level, streak, last_login
       FROM users
       WHERE email = ?
       LIMIT 1`,
      [email]
    );

    if (users.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password.',
      });
    }

    const user = users[0];
    const passwordMatch = await bcrypt.compare(password, user.password);

    if (!passwordMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password.',
      });
    }

    const today = new Date().toISOString().split('T')[0];
    const lastLogin = user.last_login
      ? new Date(user.last_login).toISOString().split('T')[0]
      : null;

    let newStreak = user.streak;
    let newXp = user.xp;

    if (lastLogin !== today) {
      newXp += 10;

      if (lastLogin === null) {
        newStreak = 1;
      } else {
        const diffDays =
          (new Date(today) - new Date(lastLogin)) / (1000 * 60 * 60 * 24);

        if (diffDays === 1) {
          newStreak += 1;
        } else if (diffDays > 1) {
          newStreak = 1;
        }
      }

      const { level: newLevel } = computeLevel(newXp);

      await pool.execute(
        `UPDATE users SET xp = ?, level = ?, streak = ?, last_login = ? WHERE id = ?`,
        [newXp, newLevel, newStreak, today, user.id]
      );
    }

    const { level, xpInLevel, progress } = computeLevel(newXp);

    return res.status(200).json({
      success: true,
      message: 'Login successful.',
      token: generateToken(user),
      user: {
        id: user.id,
        fullName: user.full_name,
        email: user.email,
        xp: newXp,
        xpInLevel,
        level,
        progress,
        streak: newStreak,
      },
    });
  } catch (error) {
    next(error);
  }
};

exports.profile = async (req, res, next) => {
  try {
    const [users] = await pool.execute(
      `SELECT id, full_name, email, xp, level, streak, created_at
       FROM users
       WHERE id = ?
       LIMIT 1`,
      [req.user.id]
    );

    if (users.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found.',
      });
    }

    const user = users[0];
    const { level, xpInLevel, progress } = computeLevel(user.xp);

    return res.status(200).json({
      success: true,
      user: {
        id: user.id,
        fullName: user.full_name,
        email: user.email,
        xp: user.xp,
        xpInLevel,
        level,
        progress,
        streak: user.streak,
        createdAt: user.created_at,
      },
    });
  } catch (error) {
    next(error);
  }
};

// PUT /api/auth/profile
// Updates full_name (and optionally username) for the logged-in user.
exports.updateProfile = async (req, res, next) => {
  try {
    const { fullName, username } = req.body;

    if (!fullName || fullName.trim() === '') {
      return res.status(400).json({
        success: false,
        message: 'Full name is required.',
      });
    }

    // If your users table has a username column, include it; otherwise omit.
    await pool.execute(
      `UPDATE users SET full_name = ? WHERE id = ?`,
      [fullName.trim(), req.user.id]
    );

    return res.status(200).json({
      success: true,
      message: 'Profile updated successfully.',
      user: {
        fullName: fullName.trim(),
        username: username?.trim() ?? null,
      },
    });
  } catch (error) {
    next(error);
  }
};

// PUT /api/auth/email
// Updates the email for the logged-in user.
exports.updateEmail = async (req, res, next) => {
  try {
    const { email } = req.body;

    if (!email || !email.includes('@')) {
      return res.status(400).json({
        success: false,
        message: 'A valid email address is required.',
      });
    }

    // Check if email is already taken by another user.
    const [existing] = await pool.execute(
      `SELECT id FROM users WHERE email = ? AND id != ? LIMIT 1`,
      [email.trim(), req.user.id]
    );

    if (existing.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'This email is already in use.',
      });
    }

    await pool.execute(
      `UPDATE users SET email = ? WHERE id = ?`,
      [email.trim(), req.user.id]
    );

    // Re-issue token so the new email is reflected in future requests.
    const newToken = jwt.sign(
      { id: req.user.id, email: email.trim(), fullName: req.user.fullName },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    return res.status(200).json({
      success: true,
      message: 'Email updated successfully.',
      token: newToken,
      email: email.trim(),
    });
  } catch (error) {
    next(error);
  }
};

// PUT /api/auth/password
// Verifies the current password then sets a new one.
exports.updatePassword = async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Current password and new password are required.',
      });
    }

    if (newPassword.length < 8) {
      return res.status(400).json({
        success: false,
        message: 'New password must be at least 8 characters.',
      });
    }

    const [users] = await pool.execute(
      `SELECT password FROM users WHERE id = ? LIMIT 1`,
      [req.user.id]
    );

    if (users.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    const match = await bcrypt.compare(currentPassword, users[0].password);
    if (!match) {
      return res.status(401).json({
        success: false,
        message: 'Current password is incorrect.',
      });
    }

    const hashed = await bcrypt.hash(newPassword, 10);
    await pool.execute(
      `UPDATE users SET password = ? WHERE id = ?`,
      [hashed, req.user.id]
    );

    return res.status(200).json({
      success: true,
      message: 'Password updated successfully.',
    });
  } catch (error) {
    next(error);
  }
};

// PUT /api/auth/phone
// Saves or updates the phone number for the logged-in user.
// Requires a `phone` VARCHAR column on the users table.
exports.updatePhone = async (req, res, next) => {
  try {
    const { phone } = req.body;

    if (!phone || phone.trim() === '') {
      return res.status(400).json({
        success: false,
        message: 'Phone number is required.',
      });
    }

    await pool.execute(
      `UPDATE users SET phone = ? WHERE id = ?`,
      [phone.trim(), req.user.id]
    );

    return res.status(200).json({
      success: true,
      message: 'Phone number updated successfully.',
      phone: phone.trim(),
    });
  } catch (error) {
    next(error);
  }
};