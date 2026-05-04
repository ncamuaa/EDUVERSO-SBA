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

// Helper: compute level and progress from total XP
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

    // --- Streak & XP Logic ---
    const today = new Date().toISOString().split('T')[0]; // "YYYY-MM-DD"
    const lastLogin = user.last_login
      ? new Date(user.last_login).toISOString().split('T')[0]
      : null;

    let newStreak = user.streak;
    let newXp = user.xp;

    if (lastLogin !== today) {
      // Only award XP and update streak if it's a new day login
      newXp += 10;

      if (lastLogin === null) {
        newStreak = 1;
      } else {
        const diffDays =
          (new Date(today) - new Date(lastLogin)) / (1000 * 60 * 60 * 24);

        if (diffDays === 1) {
          newStreak += 1; // Consecutive day — keep streak going
        } else if (diffDays > 1) {
          newStreak = 1;  // Missed a day — reset streak
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
        xpInLevel,      // XP within current level (0–99)
        level,
        progress,       // 0.0 to 1.0 — use directly in Flutter progressBar()
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