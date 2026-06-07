import { useState, useEffect } from 'react';
import { Users, BookOpen, Gamepad2, TrendingUp, Star, Zap, Award } from 'lucide-react';
import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer, BarChart, Bar } from 'recharts';
import { useNavigate } from 'react-router-dom';
import Card from '../components/Card';
import { supabase } from '../lib/supabase';

const BADGES = ['🏆', '⭐', '🎯', '🔥', '💎'];

function getGreeting() {
  const h = new Date().getHours();
  if (h < 12) return 'Good morning 🌤️';
  if (h < 18) return 'Good afternoon ☀️';
  return 'Good evening 🌙';
}

export default function Dashboard() {
  const [stats, setStats]             = useState(null);
  const [activity, setActivity]       = useState([]);
  const [topStudents, setTopStudents] = useState([]);
  const [modules, setModules]         = useState([]);
  const [loading, setLoading]         = useState(true);
  const [hoveredStudent, setHoveredStudent] = useState(null);
  const [newBadges, setNewBadges]     = useState(0);
  const navigate = useNavigate();

  useEffect(() => {
    async function fetchAll() {
      try {
        // Total students
        const { count: totalStudents } = await supabase
          .from('users')
          .select('*', { count: 'exact', head: true })
          .neq('role', 'admin');

        // Active now (is_online)
        const { count: activeNow } = await supabase
          .from('users')
          .select('*', { count: 'exact', head: true })
          .eq('is_online', true);

        // Active modules
        const { count: activeModules } = await supabase
          .from('modules')
          .select('*', { count: 'exact', head: true });

        // Games played
        const { count: gamesPlayed } = await supabase
          .from('game_sessions')
          .select('*', { count: 'exact', head: true });

        // Avg score
        const { data: scoreData } = await supabase
          .from('game_scores')
          .select('score');
        const avgScore = scoreData?.length
          ? Math.round(scoreData.reduce((a, b) => a + b.score, 0) / scoreData.length)
          : 0;

        // New badges this week (xp_history entries in last 7 days as proxy)
        const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
        const { count: badgeCount } = await supabase
          .from('xp_history')
          .select('*', { count: 'exact', head: true })
          .gte('created_at', weekAgo);

        setNewBadges(badgeCount || 0);
        setStats({ totalStudents, activeModules, gamesPlayed, avgScore, activeNow: activeNow || 0 });

        // Top students by XP
        const { data: top } = await supabase
          .from('users')
          .select('full_name, xp, course')
          .neq('role', 'admin')
          .order('xp', { ascending: false })
          .limit(5);
        setTopStudents(top || []);

        // Module completion chart
        const { data: mods } = await supabase
          .from('modules')
          .select('id, title');

        const { data: progress } = await supabase
          .from('user_progress')
          .select('module_id');

        const completionMap = {};
        progress?.forEach(p => {
          completionMap[p.module_id] = (completionMap[p.module_id] || 0) + 1;
        });

        setModules(mods?.map(m => ({
          name: m.title?.slice(0, 10),
          completions: completionMap[m.id] || 0
        })) || []);

        // Weekly activity — count game_sessions per day of week
        const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        const { data: sessions } = await supabase
          .from('game_sessions')
          .select('created_at, user_id');

        const activityMap = {};
        const studentMap  = {};
        sessions?.forEach(s => {
          const day = days[new Date(s.created_at).getDay()];
          activityMap[day] = (activityMap[day] || 0) + 1;
          if (!studentMap[day]) studentMap[day] = new Set();
          studentMap[day].add(s.user_id);
        });

        setActivity(days.map(d => ({
          day: d,
          games:    activityMap[d] || 0,
          students: studentMap[d]?.size || 0,
        })));

      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    }
    fetchAll();
  }, []);

  const statCards = stats ? [
    { label: 'Total Students', value: stats.totalStudents?.toLocaleString(), icon: Users,      color: 'var(--primary)',      bg: 'rgba(108,60,225,0.1)'  },
    { label: 'Active Modules', value: stats.activeModules,                   icon: BookOpen,   color: 'var(--accent-green)', bg: 'rgba(16,185,129,0.1)'  },
    { label: 'Games Played',   value: stats.gamesPlayed?.toLocaleString(),   icon: Gamepad2,   color: 'var(--accent-pink)',  bg: 'rgba(236,72,153,0.1)'  },
    { label: 'Avg. Score',     value: stats.avgScore + '%',                  icon: TrendingUp, color: 'var(--secondary)',    bg: 'rgba(245,158,11,0.1)'  },
  ] : [];

  return (
    <div style={{ padding: '20px 24px', display: 'flex', flexDirection: 'column', gap: 16, width: '100%', boxSizing: 'border-box' }}>

      {/* Welcome Banner */}
      <div style={{
        borderRadius: 16, padding: '20px 24px',
        background: 'linear-gradient(135deg, var(--primary-dark) 0%, var(--primary) 50%, var(--primary-light) 100%)',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        boxShadow: '0 8px 32px rgba(108,60,225,0.35)', position: 'relative', overflow: 'hidden'
      }}>
        <div style={{ position: 'absolute', top: -30, right: 120, width: 200, height: 200, borderRadius: '50%', background: 'rgba(255,255,255,0.05)' }} />
        <div style={{ position: 'absolute', bottom: -40, right: 60, width: 160, height: 160, borderRadius: '50%', background: 'rgba(255,255,255,0.05)' }} />
        <div>
          <div style={{ fontSize: 13, fontWeight: 700, color: 'rgba(255,255,255,0.7)', marginBottom: 6, textTransform: 'uppercase', letterSpacing: 1 }}>
            {getGreeting()}
          </div>
          <h2 style={{ fontFamily: 'Fredoka One', fontSize: 26, color: '#fff', marginBottom: 6 }}>
            Welcome back, Admin!
          </h2>
          <p style={{ color: 'rgba(255,255,255,0.7)', fontSize: 14, fontWeight: 600 }}>
            Students are making great progress today. Keep up the awesome work!
          </p>
        </div>
        <div style={{ display: 'flex', gap: 16 }}>
          {[
            { icon: Zap,   label: loading ? '… Active Now' : `${stats?.activeNow ?? 0} Active Now`, color: 'var(--secondary)' },
            { icon: Award, label: loading ? '… New Badges' : `${newBadges} New Badges`,              color: 'var(--accent-pink)' },
          ].map(({ icon: Icon, label, color }) => (
            <div key={label} style={{
              background: 'rgba(255,255,255,0.12)', borderRadius: 14, padding: '14px 20px',
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
              backdropFilter: 'blur(8px)', border: '1px solid rgba(255,255,255,0.2)'
            }}>
              <Icon size={22} color={color} />
              <span style={{ fontSize: 12, fontWeight: 700, color: '#fff', whiteSpace: 'nowrap' }}>{label}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Stat Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 14 }}>
        {loading ? (
          Array(4).fill(0).map((_, i) => (
            <Card key={i} style={{ padding: 18, height: 100, background: 'var(--card)' }} />
          ))
        ) : statCards.map(({ label, value, icon: Icon, color, bg }) => (
          <Card key={label} style={{ display: 'flex', flexDirection: 'column', gap: 10, padding: 18 }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div style={{ width: 38, height: 38, borderRadius: 10, background: bg, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Icon size={18} color={color} />
              </div>
            </div>
            <div>
              <div style={{ fontFamily: 'Fredoka One', fontSize: 24, color: 'var(--text-primary)', lineHeight: 1 }}>{value}</div>
              <div style={{ fontSize: 12, color: 'var(--text-secondary)', fontWeight: 600, marginTop: 3 }}>{label}</div>
            </div>
          </Card>
        ))}
      </div>

      {/* Charts Row */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
        <Card>
          <div style={{ fontFamily: 'Fredoka One', fontSize: 16, marginBottom: 14, color: 'var(--text-primary)' }}>Weekly Activity</div>
          {activity.every(d => d.games === 0 && d.students === 0) ? (
            <div style={{ height: 180, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-muted)', fontWeight: 600, fontSize: 13 }}>
              No game sessions recorded yet.
            </div>
          ) : (
            <ResponsiveContainer width="100%" height={180}>
              <AreaChart data={activity}>
                <defs>
                  <linearGradient id="gStudents" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%"  stopColor="var(--primary)"     stopOpacity={0.3} />
                    <stop offset="95%" stopColor="var(--primary)"     stopOpacity={0}   />
                  </linearGradient>
                  <linearGradient id="gGames" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%"  stopColor="var(--accent-pink)" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="var(--accent-pink)" stopOpacity={0}   />
                  </linearGradient>
                </defs>
                <XAxis dataKey="day" axisLine={false} tickLine={false} tick={{ fontSize: 12, fontWeight: 700, fill: '#9CA3AF' }} />
                <YAxis hide allowDecimals={false} />
                <Tooltip contentStyle={{ borderRadius: 12, border: 'none', boxShadow: '0 4px 20px rgba(0,0,0,0.1)', fontFamily: 'Nunito', fontWeight: 700 }} />
                <Area type="monotone" dataKey="students" stroke="var(--primary)"     strokeWidth={2.5} fill="url(#gStudents)" name="Students" />
                <Area type="monotone" dataKey="games"    stroke="var(--accent-pink)" strokeWidth={2.5} fill="url(#gGames)"    name="Games"    />
              </AreaChart>
            </ResponsiveContainer>
          )}
        </Card>

        <Card>
          <div style={{ fontFamily: 'Fredoka One', fontSize: 16, marginBottom: 14, color: 'var(--text-primary)' }}>Module Completion</div>
          {modules.every(m => m.completions === 0) ? (
            <div style={{ height: 180, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-muted)', fontWeight: 600, fontSize: 13 }}>
              No completions recorded yet.
            </div>
          ) : (
            <ResponsiveContainer width="100%" height={180}>
              <BarChart data={modules} barSize={32}>
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fontSize: 12, fontWeight: 700, fill: '#9CA3AF' }} />
                <YAxis hide allowDecimals={false} />
                <Tooltip contentStyle={{ borderRadius: 12, border: 'none', fontFamily: 'Nunito', fontWeight: 700 }} />
                <Bar dataKey="completions" fill="var(--primary)" radius={[8, 8, 0, 0]} name="Completions" />
              </BarChart>
            </ResponsiveContainer>
          )}
        </Card>
      </div>

      {/* Top Students */}
      <Card>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
          <div style={{ fontFamily: 'Fredoka One', fontSize: 16, color: 'var(--text-primary)' }}>Top Students This Week</div>
          <button
            onClick={() => navigate('/students')}
            style={{
              fontSize: 13, fontWeight: 700, color: 'var(--primary)',
              background: 'rgba(108,60,225,0.08)', border: '1.5px solid rgba(108,60,225,0.15)',
              cursor: 'pointer', padding: '6px 14px', borderRadius: 10, transition: 'all 0.15s',
            }}
            onMouseEnter={e => { e.currentTarget.style.background = 'rgba(108,60,225,0.15)'; e.currentTarget.style.transform = 'translateY(-1px)'; }}
            onMouseLeave={e => { e.currentTarget.style.background = 'rgba(108,60,225,0.08)'; e.currentTarget.style.transform = 'translateY(0)'; }}
          >
            View All →
          </button>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          {loading ? (
            <div style={{ padding: 20, textAlign: 'center', color: 'var(--text-muted)', fontWeight: 600 }}>Loading…</div>
          ) : topStudents.length === 0 ? (
            <div style={{ padding: 20, textAlign: 'center', color: 'var(--text-muted)', fontWeight: 600 }}>No student data yet.</div>
          ) : topStudents.map((s, i) => (
            <div
              key={s.full_name}
              onClick={() => navigate('/students')}
              onMouseEnter={() => setHoveredStudent(i)}
              onMouseLeave={() => setHoveredStudent(null)}
              style={{
                display: 'flex', alignItems: 'center', gap: 12, padding: '9px 12px',
                borderRadius: 10, cursor: 'pointer',
                background: hoveredStudent === i ? 'rgba(108,60,225,0.08)' : i === 0 ? 'rgba(108,60,225,0.05)' : 'transparent',
                transition: 'background 0.15s, transform 0.15s',
                transform: hoveredStudent === i ? 'translateX(3px)' : 'translateX(0)',
              }}>
              <div style={{
                width: 36, height: 36, borderRadius: 10,
                background: `hsl(${i * 60}, 70%, 90%)`,
                display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 16
              }}>{BADGES[i % BADGES.length]}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 800, fontSize: 14, color: 'var(--text-primary)' }}>{s.full_name}</div>
                <div style={{ fontSize: 12, color: 'var(--text-muted)', fontWeight: 600 }}>{s.course || '—'}</div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                <Star size={14} color="var(--secondary)" fill="var(--secondary)" />
                <span style={{ fontWeight: 800, fontSize: 14, color: 'var(--text-primary)' }}>{s.xp} XP</span>
              </div>
            </div>
          ))}
        </div>
      </Card>
    </div>
  );
}