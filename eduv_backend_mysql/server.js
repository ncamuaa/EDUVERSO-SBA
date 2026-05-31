const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

dotenv.config();

const authRoutes = require('./routes/authRoutes');
const aiTutorRoutes = require('./routes/aiTutorRoutes');
const modulesRoutes = require('./routes/modulesRoutes');
const lessonsRoutes = require('./routes/lessonsRoutes');
const feedbackRoutes = require('./routes/feedbackRoutes');
const announcementsRoutes = require('./routes/announcementsRoutes');
const gameArenaRoutes = require('./routes/gameArenaRoutes');

const app = express();

app.use(cors({
  origin: true,
  credentials: true
}));

app.use(express.json({ limit: '10mb' }));

app.get('/', (req, res) => {
  res.json({ success: true, message: 'EduVerso backend is running.' });
});

app.use('/api/auth', authRoutes);
app.use('/api/ai-tutor', aiTutorRoutes);
app.use('/api/modules', modulesRoutes);
app.use('/api/lessons', lessonsRoutes);
app.use('/api/feedback', feedbackRoutes);
app.use('/api/announcements', announcementsRoutes);
app.use('/api/game-arena', gameArenaRoutes);

// ── AI proxy ──────────────────────────────────────────────────────────────
app.post('/api/ai/generate', async (req, res) => {
  try {
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': process.env.ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify(req.body),
    });
    const data = await response.json();
    res.json(data);
  } catch (err) {
    console.error('[AI proxy error]', err);
    res.status(500).json({ success: false, message: err.message });
  }
});
// ─────────────────────────────────────────────────────────────────────────

app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Route not found.' });
});

app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error.',
  });
});

const PORT = process.env.PORT || 5002;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});