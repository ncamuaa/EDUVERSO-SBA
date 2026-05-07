const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
dotenv.config();

const authRoutes    = require('./routes/authRoutes');
const aiTutorRoutes = require('./routes/aiTutorRoutes');
const modulesRoutes = require('./routes/modulesRoutes'); // ✅ new
const lessonsRoutes = require('./routes/lessonsRoutes');
const feedbackRoutes = require('./routes/feedbackRoutes');
const announcementsRoutes = require('./routes/announcementsRoutes');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'EduVerso backend is running.',
  });
});

app.use('/api/auth',      authRoutes);
app.use('/api/ai-tutor',  aiTutorRoutes);
app.use('/api/modules',   modulesRoutes); // ✅ new
app.use('/api/lessons', lessonsRoutes);
app.use('/api/feedback', feedbackRoutes);
app.use('/api/announcements', announcementsRoutes);

app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found.',
  });
});

app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error.',
  });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});