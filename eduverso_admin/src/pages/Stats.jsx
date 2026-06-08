import { useState, useEffect } from 'react';
import Card from '../components/Card';
import { supabase } from '../lib/supabase';
import {
  BarChart, Bar, PieChart, Pie, Cell,
  XAxis, YAxis, Tooltip, ResponsiveContainer,
} from 'recharts';

const COLORS = ['#6C3CE1', '#EC4899', '#3B82F6', '#10B981', '#F59E0B', '#8B5CF6', '#06B6D4', '#FF6B6B'];

export default function Stats() {
  const [loading, setLoading]             = useState(true);
  const [totalStudents, setTotalStudents] = useState(0);
  const [totalGames, setTotalGames]       = useState(0);
  const [totalXp, setTotalXp]             = useState(0);
  const [totalFeedback, setTotalFeedback] = useState(0);
  const [avgRating, setAvgRating]         = useState(0);
  const [courseData, setCourseData]       = useState([]);
  const [gameData, setGameData]           = useState([]);
  const [subjectData, setSubjectData]     = useState([]);
  const [feedbackDist, setFeedbackDist]   = useState([]);

  useEffect(() => { fetchAll(); }, []);

  async function fetchAll() {
    setLoading(true);
    try {
      await Promise.all([fetchStudents(), fetchGames(), fetchFeedback(), fetchModules()]);
    } finally {
      setLoading(false);
    }
  }

  async function fetchStudents() {
    const { data } = await supabase.from('users').select('course, created_at');
    if (!data) return;
    setTotalStudents(data.length);
    const courseMap = {};
    data.forEach(u => {
      const c = u.course || 'Unknown';
      courseMap[c] = (courseMap[c] || 0) + 1;
    });
    setCourseData(
      Object.entries(courseMap)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 6)
        .map(([name, value], i) => ({ name, value, color: COLORS[i % COLORS.length] }))
    );
  }

  async function fetchGames() {
    const { data } = await supabase.from('game_scores').select('game_type, total_xp, high_score, games_played');
    if (!data) return;
    setTotalGames(data.reduce((a, b) => a + (b.games_played || 0), 0));
    setTotalXp(data.reduce((a, b) => a + (b.total_xp || 0), 0));
    const gameMap = {};
    data.forEach(g => {
      const key = g.game_type || 'unknown';
      if (!gameMap[key]) gameMap[key] = { plays: 0, xp: 0, topScore: 0 };
      gameMap[key].plays    += g.games_played || 0;
      gameMap[key].xp       += g.total_xp || 0;
      gameMap[key].topScore  = Math.max(gameMap[key].topScore, g.high_score || 0);
    });
    const labels = {
      guess_game: 'Guess', word_scramble: 'Scramble', true_or_false: 'T/F',
      speed_quiz: 'Speed', escape_the_program: 'Escape', flash_cards: 'Flash', memory_match: 'Memory',
    };
    setGameData(
      Object.entries(gameMap).map(([key, val]) => ({
        game: labels[key] || key,
        plays: val.plays,
        xp: val.xp,
        topScore: val.topScore,
      }))
    );
  }

  async function fetchFeedback() {
    const { data } = await supabase.from('feedback').select('rating, content');
    if (!data) return;
    setTotalFeedback(data.length);
    setAvgRating(data.length ? (data.reduce((a, b) => a + (b.rating || 0), 0) / data.length).toFixed(1) : 0);
    setFeedbackDist([5, 4, 3, 2, 1].map(r => ({
      rating: `${r}★`,
      count: data.filter(f => f.rating === r).length,
    })));
  }

  async function fetchModules() {
    const { data } = await supabase.from('modules').select('subject');
    if (!data) return;
    const subjectMap = {};
    data.forEach(m => {
      const s = m.subject || 'Unknown';
      subjectMap[s] = (subjectMap[s] || 0) + 1;
    });
    setSubjectData(
      Object.entries(subjectMap)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 8)
        .map(([subject, modules]) => ({ subject, modules }))
    );
  }

  const Skeleton = () => (
    <div style={{ height: 220, borderRadius: 12, background: 'var(--bg)', animation: 'pulse 1.5s ease-in-out infinite' }} />
  );

  // Fixed-width bar chart that scrolls horizontally — no more giant spaces
  const ScrollableBar = ({ data, dataKey, color, nameKey, height = 220, name }) => {
  const needsScroll = data.length > 6;
  const chartWidth = needsScroll ? data.length * 88 : undefined;

  return (
    <div style={{ overflowX: needsScroll ? 'auto' : 'hidden', overflowY: 'hidden' }}>
      {needsScroll ? (
        <BarChart width={chartWidth} height={height} data={data} maxBarSize={48} barCategoryGap="30%">
          <XAxis dataKey={nameKey} axisLine={false} tickLine={false} tick={{ fontSize: 11, fontWeight: 700, fill: '#9CA3AF' }} />
          <YAxis hide />
          <Tooltip contentStyle={{ borderRadius: 12, border: 'none', fontFamily: 'Nunito', fontWeight: 700 }} />
          <Bar dataKey={dataKey} fill={color} radius={[8, 8, 0, 0]} name={name} />
        </BarChart>
      ) : (
        <ResponsiveContainer width="100%" height={height}>
          <BarChart data={data} maxBarSize={64} barCategoryGap="30%">
            <XAxis dataKey={nameKey} axisLine={false} tickLine={false} tick={{ fontSize: 11, fontWeight: 700, fill: '#9CA3AF' }} />
            <YAxis hide />
            <Tooltip contentStyle={{ borderRadius: 12, border: 'none', fontFamily: 'Nunito', fontWeight: 700 }} />
            <Bar dataKey={dataKey} fill={color} radius={[8, 8, 0, 0]} name={name} />
          </BarChart>
        </ResponsiveContainer>
      )}
    </div>
  );
};

  return (
    <div style={{ padding: 32, display: 'flex', flexDirection: 'column', gap: 24 }}>
      <style>{`@keyframes pulse { 0%,100%{opacity:.6} 50%{opacity:.3} }`}</style>

      {/* KPI Row */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16 }}>
        {[
          { label: 'Total Students',  value: loading ? '…' : totalStudents.toLocaleString(), sub: 'registered users',            color: 'var(--primary)',      emoji: '👥' },
          { label: 'Total Game Plays',value: loading ? '…' : totalGames.toLocaleString(),    sub: 'across all games',             color: 'var(--accent-green)', emoji: '🎮' },
          { label: 'Total XP Earned', value: loading ? '…' : totalXp.toLocaleString(),       sub: 'by all students',              color: 'var(--secondary)',    emoji: '⚡' },
          { label: 'Avg. Rating',     value: loading ? '…' : `${avgRating}★`,                sub: `from ${totalFeedback} reviews`,color: 'var(--accent-pink)',  emoji: '⭐' },
        ].map(({ label, value, sub, color, emoji }) => (
          <Card key={label}>
            <div style={{ fontSize: 28, marginBottom: 8 }}>{emoji}</div>
            <div style={{ fontFamily: 'Fredoka One', fontSize: 26, color, lineHeight: 1, marginBottom: 4 }}>{value}</div>
            <div style={{ fontWeight: 800, fontSize: 13, color: 'var(--text-primary)' }}>{label}</div>
            <div style={{ fontSize: 12, color: 'var(--text-muted)', fontWeight: 600 }}>{sub}</div>
          </Card>
        ))}
      </div>

      {/* Game Plays Bar Chart */}
      <Card>
        <div style={{ fontFamily: 'Fredoka One', fontSize: 18, marginBottom: 20 }}>Game Plays by Type</div>
        {loading ? <Skeleton /> : gameData.length === 0 ? (
          <div style={{ textAlign: 'center', padding: 40, color: 'var(--text-muted)', fontWeight: 600 }}>No game data yet.</div>
        ) : (
          <ScrollableBar data={gameData} dataKey="plays" color="var(--primary)" nameKey="game" height={220} name="Plays" />
        )}
      </Card>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>

        {/* Students by Course Pie */}
        <Card>
          <div style={{ fontFamily: 'Fredoka One', fontSize: 18, marginBottom: 20 }}>Students by Course</div>
          {loading ? <Skeleton /> : courseData.length === 0 ? (
            <div style={{ textAlign: 'center', padding: 40, color: 'var(--text-muted)', fontWeight: 600 }}>No data yet.</div>
          ) : (
            <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
              <ResponsiveContainer width="50%" height={200}>
                <PieChart>
                  <Pie data={courseData} cx="50%" cy="50%" innerRadius={50} outerRadius={75} dataKey="value" strokeWidth={0}>
                    {courseData.map((entry) => <Cell key={entry.name} fill={entry.color} />)}
                  </Pie>
                </PieChart>
              </ResponsiveContainer>
              <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 8 }}>
                {courseData.map(({ name, value, color }) => (
                  <div key={name} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                      <div style={{ width: 8, height: 8, borderRadius: 2, background: color, flexShrink: 0 }} />
                      <span style={{ fontSize: 11, fontWeight: 700, color: 'var(--text-secondary)' }}>
                        {name.replace('BS ', '').replace('Bachelor of ', '')}
                      </span>
                    </div>
                    <span style={{ fontSize: 12, fontWeight: 800, color }}>{value}</span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </Card>

        {/* Feedback Distribution */}
        <Card>
          <div style={{ fontFamily: 'Fredoka One', fontSize: 18, marginBottom: 20 }}>Feedback Distribution</div>
          {loading ? <Skeleton /> : feedbackDist.every(f => f.count === 0) ? (
            <div style={{ textAlign: 'center', padding: 40, color: 'var(--text-muted)', fontWeight: 600 }}>No feedback yet.</div>
          ) : (
            <ResponsiveContainer width="100%" height={200}>
              <BarChart data={feedbackDist} barSize={24} layout="vertical">
                <XAxis type="number" hide />
                <YAxis type="category" dataKey="rating" axisLine={false} tickLine={false} tick={{ fontSize: 13, fontWeight: 800, fill: '#F59E0B' }} width={30} />
                <Tooltip contentStyle={{ borderRadius: 12, border: 'none', fontFamily: 'Nunito', fontWeight: 700 }} />
                <Bar dataKey="count" fill="var(--secondary)" radius={[0, 8, 8, 0]} name="Responses" />
              </BarChart>
            </ResponsiveContainer>
          )}
        </Card>
      </div>

      {/* Modules by Subject */}
      <Card>
        <div style={{ fontFamily: 'Fredoka One', fontSize: 18, marginBottom: 20 }}>Modules by Subject</div>
        {loading ? <Skeleton /> : subjectData.length === 0 ? (
          <div style={{ textAlign: 'center', padding: 40, color: 'var(--text-muted)', fontWeight: 600 }}>No modules yet.</div>
        ) : (
          <ScrollableBar data={subjectData} dataKey="modules" color="#8B5CF6" nameKey="subject" height={200} name="Modules" />
        )}
      </Card>

      {/* XP by Game */}
      <Card>
        <div style={{ fontFamily: 'Fredoka One', fontSize: 18, marginBottom: 20 }}>Total XP Earned by Game</div>
        {loading ? <Skeleton /> : gameData.length === 0 ? (
          <div style={{ textAlign: 'center', padding: 40, color: 'var(--text-muted)', fontWeight: 600 }}>No game data yet.</div>
        ) : (
          <ScrollableBar data={gameData} dataKey="xp" color="#F59E0B" nameKey="game" height={200} name="Total XP" />
        )}
      </Card>
    </div>
  );
}