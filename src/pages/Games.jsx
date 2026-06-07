import { useState, useEffect } from 'react';
import { Plus, Gamepad2, Play, Zap, Trophy } from 'lucide-react';
import Card from '../components/Card';

const GAME_META = {
  guess_game:          { title: 'Guess Game',         subject: 'General',     type: 'Quiz',       color: '#6C3CE1', difficulty: 'Medium' },
  word_scramble:       { title: 'Word Scramble',      subject: 'English',     type: 'Puzzle',     color: '#3B82F6', difficulty: 'Easy'   },
  true_or_false:       { title: 'True or False',      subject: 'General',     type: 'Challenge',  color: '#EC4899', difficulty: 'Easy'   },
  speed_quiz:          { title: 'Speed Quiz',         subject: 'Mixed',       type: 'Speed',      color: '#F59E0B', difficulty: 'Hard'   },
  escape_the_program:  { title: 'Escape the Program', subject: 'Programming', type: 'Puzzle',     color: '#10B981', difficulty: 'Hard'   },
  flash_cards:         { title: 'Flash Cards',        subject: 'All',         type: 'Review',     color: '#3657C9', difficulty: 'Easy'   },
  memory_match:        { title: 'Memory Match',       subject: 'All',         type: 'Memory',     color: '#FF6B6B', difficulty: 'Medium' },
};

const gameColors = {
  guess_game:          { bg: 'rgba(108,60,225,0.1)',  color: '#6C3CE1' },
  word_scramble:       { bg: 'rgba(59,130,246,0.1)',  color: '#3B82F6' },
  true_or_false:       { bg: 'rgba(236,72,153,0.1)',  color: '#EC4899' },
  speed_quiz:          { bg: 'rgba(245,158,11,0.1)',  color: '#F59E0B' },
  escape_the_program:  { bg: 'rgba(16,185,129,0.1)',  color: '#10B981' },
  flash_cards:         { bg: 'rgba(54,87,201,0.1)',   color: '#3657C9' },
  memory_match:        { bg: 'rgba(255,107,107,0.1)', color: '#FF6B6B' },
};

export default function Games() {
  const [leaderboard, setLeaderboard] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('all');

  const token = localStorage.getItem('token');

  useEffect(() => {
    const fetchData = async () => {
      try {
        const res = await fetch('http://localhost:5002/api/game-arena/leaderboard', {
          headers: { Authorization: `Bearer ${token}` },
        });
        const data = await res.json();
        if (data.success) setLeaderboard(data.leaderboard);
      } catch (err) {
        console.error('Failed to fetch game data:', err);
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, []);

  const totalPlays = leaderboard.reduce((a, b) => a + (b.games_played || 0), 0);
  const totalXp    = leaderboard.reduce((a, b) => a + (b.total_xp    || 0), 0);
  const topScore   = leaderboard.length ? Math.max(...leaderboard.map(l => l.high_score || 0)) : 0;

  const games = Object.entries(GAME_META);

  const filteredLeaderboard = leaderboard.filter(l =>
    activeTab === 'all' || l.game_type === activeTab
  );

  return (
    <div style={{ padding: 32, display: 'flex', flexDirection: 'column', gap: 24 }}>

      {/* Stats Row */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16 }}>
        {[
          { label: 'Total Games',  value: games.length,                icon: <Gamepad2 size={24} color="#6C3CE1" />, bg: 'rgba(108,60,225,0.1)', color: '#6C3CE1' },
          { label: 'Total Plays',  value: totalPlays.toLocaleString(), icon: <Play     size={24} color="#10B981" />, bg: 'rgba(16,185,129,0.1)',  color: '#10B981' },
          { label: 'Total XP',     value: totalXp.toLocaleString(),    icon: <Zap      size={24} color="#F59E0B" />, bg: 'rgba(245,158,11,0.1)',  color: '#F59E0B' },
          { label: 'Top Score',    value: topScore,                    icon: <Trophy   size={24} color="#EC4899" />, bg: 'rgba(236,72,153,0.1)',  color: '#EC4899' },
        ].map(({ label, value, icon, bg, color }) => (
          <Card key={label} style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <div style={{ width: 48, height: 48, borderRadius: 12, background: bg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              {icon}
            </div>
            <div>
              <div style={{ fontFamily: 'Fredoka One', fontSize: 22, color, lineHeight: 1 }}>{loading ? '…' : value}</div>
              <div style={{ fontSize: 12, color: 'var(--text-secondary)', fontWeight: 600 }}>{label}</div>
            </div>
          </Card>
        ))}
      </div>

      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ fontFamily: 'Fredoka One', fontSize: 20 }}>Game Library</div>
        <button style={{
          display: 'flex', alignItems: 'center', gap: 8, padding: '10px 20px',
          borderRadius: 12, background: 'linear-gradient(135deg, var(--primary), var(--primary-light))',
          color: '#fff', border: 'none', cursor: 'pointer', fontFamily: 'Nunito', fontWeight: 800, fontSize: 14,
          boxShadow: '0 4px 16px rgba(108,60,225,0.35)'
        }}>
          <Plus size={16} /> Add Game
        </button>
      </div>

      {/* Games Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 20 }}>
        {games.map(([key, meta]) => {
          const stats          = leaderboard.filter(l => l.game_type === key);
          const totalGamePlays = stats.reduce((a, b) => a + (b.games_played || 0), 0);
          const gameTopScore   = stats.length ? Math.max(...stats.map(l => l.high_score || 0)) : 0;
          const gameTotalXp    = stats.reduce((a, b) => a + (b.total_xp    || 0), 0);

          return (
            <Card key={key} style={{ padding: 0, overflow: 'hidden' }}>
              {/* Banner */}
              <div style={{
                height: 90,
                background: `linear-gradient(135deg, ${meta.color}, ${meta.color}99)`,
                display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 20px'
              }}>
                <div>
                  <div style={{ fontFamily: 'Fredoka One', fontSize: 16, color: '#fff' }}>{meta.title}</div>
                  <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.7)', fontWeight: 700, marginTop: 2 }}>{meta.type}</div>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div style={{
                    display: 'inline-block', padding: '3px 10px', borderRadius: 8, marginBottom: 4,
                    background: 'rgba(255,255,255,0.2)', fontSize: 11, fontWeight: 800, color: '#fff'
                  }}>{meta.subject}</div>
                  <br />
                  <span style={{
                    fontSize: 10, fontWeight: 800, padding: '2px 8px', borderRadius: 6,
                    background: 'rgba(255,255,255,0.15)', color: '#fff'
                  }}>{meta.difficulty}</span>
                </div>
              </div>

              <div style={{ padding: '14px 18px' }}>
                {/* Stats */}
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8, marginBottom: 12 }}>
                  {[
                    { label: 'Plays',     value: loading ? '…' : totalGamePlays, color: meta.color },
                    { label: 'Top Score', value: loading ? '…' : gameTopScore,   color: '#10B981'  },
                    { label: 'Total XP',  value: loading ? '…' : gameTotalXp,    color: '#F59E0B'  },
                  ].map(({ label, value, color }) => (
                    <div key={label} style={{ textAlign: 'center', padding: '8px 4px', background: 'var(--bg)', borderRadius: 8 }}>
                      <div style={{ fontFamily: 'Fredoka One', fontSize: 15, color }}>{value}</div>
                      <div style={{ fontSize: 9, fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: 0.3 }}>{label}</div>
                    </div>
                  ))}
                </div>

                {/* Top Players */}
                {!loading && stats.length > 0 && (
                  <div style={{ marginBottom: 12 }}>
                    <div style={{ fontSize: 10, fontWeight: 800, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: 0.5, marginBottom: 6 }}>Top Players</div>
                    {stats.slice(0, 3).map((s, i) => (
                      <div key={i} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '5px 0', borderBottom: i < 2 ? '1px solid var(--border)' : 'none' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                          <span style={{ fontFamily: 'Fredoka One', fontSize: 13, color: i === 0 ? '#F59E0B' : i === 1 ? '#9CA3AF' : '#CD7C2F' }}>#{i + 1}</span>
                          <span style={{ fontSize: 12, fontWeight: 700 }}>{s.player_name || 'Unknown'}</span>
                        </div>
                        <span style={{ fontSize: 12, fontWeight: 800, color: meta.color }}>{s.high_score} pts</span>
                      </div>
                    ))}
                  </div>
                )}

                {!loading && stats.length === 0 && (
                  <div style={{ fontSize: 12, color: 'var(--text-muted)', fontWeight: 600, marginBottom: 12, textAlign: 'center', padding: '8px', background: 'var(--bg)', borderRadius: 8 }}>
                    No plays yet
                  </div>
                )}

                {/* Live badge only */}
                <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
                  <div style={{
                    display: 'flex', alignItems: 'center', gap: 4, padding: '8px 12px', borderRadius: 10,
                    background: 'rgba(16,185,129,0.1)', fontSize: 11, fontWeight: 800,
                    color: 'var(--accent-green)',
                  }}>
                    <div style={{ width: 6, height: 6, borderRadius: '50%', background: 'var(--accent-green)' }} />
                    Live
                  </div>
                </div>
              </div>
            </Card>
          );
        })}
      </div>

      {/* Full Leaderboard */}
      <Card style={{ padding: 0, overflow: 'hidden' }}>
        <div style={{ padding: '20px 24px', borderBottom: '1px solid var(--border)', display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: 10 }}>
          <div style={{ fontFamily: 'Fredoka One', fontSize: 18 }}>Overall Leaderboard</div>
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            {[
              { val: 'all',                label: 'All'           },
              { val: 'guess_game',         label: 'Guess Game'    },
              { val: 'word_scramble',      label: 'Word Scramble' },
              { val: 'true_or_false',      label: 'True/False'    },
              { val: 'speed_quiz',         label: 'Speed Quiz'    },
              { val: 'escape_the_program', label: 'Escape'        },
              { val: 'flash_cards',        label: 'Flash Cards'   },
              { val: 'memory_match',       label: 'Memory Match'  },
            ].map(({ val, label }) => (
              <button key={val} onClick={() => setActiveTab(val)} style={{
                padding: '6px 12px', borderRadius: 8, border: 'none', cursor: 'pointer',
                fontFamily: 'Nunito', fontWeight: 700, fontSize: 11,
                background: activeTab === val ? 'var(--primary)' : 'var(--bg)',
                color: activeTab === val ? '#fff' : 'var(--text-secondary)',
                transition: 'all 0.15s'
              }}>{label}</button>
            ))}
          </div>
        </div>

        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ background: 'var(--bg)' }}>
              {['Rank', 'Player', 'Game', 'High Score', 'Total XP', 'Plays'].map(h => (
                <th key={h} style={{ padding: '12px 24px', textAlign: 'left', fontSize: 12, fontWeight: 800, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: 0.5 }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={6} style={{ padding: 32, textAlign: 'center', color: 'var(--text-muted)', fontWeight: 600 }}>Loading…</td></tr>
            ) : filteredLeaderboard.length === 0 ? (
              <tr><td colSpan={6} style={{ padding: 32, textAlign: 'center', color: 'var(--text-muted)', fontWeight: 600 }}>No data yet.</td></tr>
            ) : (
              filteredLeaderboard.map((l, i) => (
                <tr key={i}
                  style={{ borderTop: '1px solid var(--border)', transition: 'background 0.12s' }}
                  onMouseOver={e => e.currentTarget.style.background = 'rgba(108,60,225,0.03)'}
                  onMouseOut={e => e.currentTarget.style.background = 'transparent'}
                >
                  <td style={{ padding: '14px 24px' }}>
                    <span style={{ fontFamily: 'Fredoka One', fontSize: 16, color: i === 0 ? '#F59E0B' : i === 1 ? '#9CA3AF' : i === 2 ? '#CD7C2F' : 'var(--text-muted)' }}>
                      #{i + 1}
                    </span>
                  </td>
                  <td style={{ padding: '14px 24px', fontWeight: 800, fontSize: 14 }}>{l.player_name || 'Unknown'}</td>
                  <td style={{ padding: '14px 24px' }}>
                    <span style={{
                      fontSize: 11, fontWeight: 800, padding: '3px 10px', borderRadius: 6,
                      background: gameColors[l.game_type]?.bg   || 'rgba(0,0,0,0.05)',
                      color:      gameColors[l.game_type]?.color || 'var(--text-muted)',
                    }}>
                      {GAME_META[l.game_type]?.title || l.game_type}
                    </span>
                  </td>
                  <td style={{ padding: '14px 24px', fontFamily: 'Fredoka One', fontSize: 16, color: 'var(--primary)'   }}>{l.high_score}</td>
                  <td style={{ padding: '14px 24px', fontFamily: 'Fredoka One', fontSize: 16, color: 'var(--secondary)' }}>{l.total_xp}</td>
                  <td style={{ padding: '14px 24px', fontSize: 13, fontWeight: 700 }}>{l.games_played}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </Card>
    </div>
  );
}