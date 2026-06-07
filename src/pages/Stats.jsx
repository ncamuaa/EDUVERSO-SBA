import Card from '../components/Card';
import { AreaChart, Area, BarChart, Bar, LineChart, Line, PieChart, Pie, Cell, XAxis, YAxis, Tooltip, ResponsiveContainer, Legend } from 'recharts';

const monthlyData = [
  { month: 'Jan', students: 2100, sessions: 8400, games: 12000 },
  { month: 'Feb', students: 2250, sessions: 9100, games: 13500 },
  { month: 'Mar', students: 2400, sessions: 9800, games: 14200 },
  { month: 'Apr', students: 2350, sessions: 9400, games: 13800 },
  { month: 'May', students: 2600, sessions: 10500, games: 16000 },
  { month: 'Jun', students: 2847, sessions: 11200, games: 18492 },
];

const subjectData = [
  { subject: 'Math', avg: 78, high: 95, low: 45 },
  { subject: 'English', avg: 83, high: 98, low: 52 },
  { subject: 'Science', avg: 71, high: 92, low: 38 },
  { subject: 'Filipino', avg: 87, high: 99, low: 60 },
  { subject: 'History', avg: 74, high: 91, low: 42 },
  { subject: 'MAPEH', avg: 90, high: 100, low: 68 },
];

const pieData = [
  { name: 'Grade 3', value: 480, color: '#6C3CE1' },
  { name: 'Grade 4', value: 620, color: '#EC4899' },
  { name: 'Grade 5', value: 890, color: '#3B82F6' },
  { name: 'Grade 6', value: 857, color: '#10B981' },
];

const timeData = [
  { time: '6am', active: 12 }, { time: '8am', active: 145 }, { time: '10am', active: 389 },
  { time: '12pm', active: 480 }, { time: '2pm', active: 520 }, { time: '4pm', active: 690 },
  { time: '6pm', active: 820 }, { time: '8pm', active: 580 }, { time: '10pm', active: 120 },
];

export default function Stats() {
  return (
    <div style={{ padding: 32, display: 'flex', flexDirection: 'column', gap: 24 }}>
      {/* KPI Row */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16 }}>
        {[
          { label: 'Monthly Growth', value: '+12.3%', sub: 'vs last month', color: 'var(--accent-green)', emoji: '📈' },
          { label: 'Retention Rate', value: '87.4%', sub: '30-day active', color: 'var(--primary)', emoji: '🔄' },
          { label: 'Completion Rate', value: '72.8%', sub: 'module average', color: 'var(--secondary)', emoji: '✅' },
          { label: 'Avg Session', value: '24 min', sub: 'per student', color: 'var(--accent-pink)', emoji: '⏱️' },
        ].map(({ label, value, sub, color, emoji }) => (
          <Card key={label}>
            <div style={{ fontSize: 28, marginBottom: 8 }}>{emoji}</div>
            <div style={{ fontFamily: 'Fredoka One', fontSize: 26, color, lineHeight: 1, marginBottom: 4 }}>{value}</div>
            <div style={{ fontWeight: 800, fontSize: 13, color: 'var(--text-primary)' }}>{label}</div>
            <div style={{ fontSize: 12, color: 'var(--text-muted)', fontWeight: 600 }}>{sub}</div>
          </Card>
        ))}
      </div>

      {/* Growth Chart */}
      <Card>
        <div style={{ fontFamily: 'Fredoka One', fontSize: 18, marginBottom: 20 }}>Platform Growth (2024)</div>
        <ResponsiveContainer width="100%" height={220}>
          <AreaChart data={monthlyData}>
            <defs>
              {[['students', '#6C3CE1'], ['sessions', '#10B981'], ['games', '#EC4899']].map(([key, color]) => (
                <linearGradient key={key} id={`g-${key}`} x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor={color} stopOpacity={0.25} />
                  <stop offset="95%" stopColor={color} stopOpacity={0} />
                </linearGradient>
              ))}
            </defs>
            <XAxis dataKey="month" axisLine={false} tickLine={false} tick={{ fontSize: 12, fontWeight: 700, fill: '#9CA3AF' }} />
            <YAxis hide />
            <Tooltip contentStyle={{ borderRadius: 12, border: 'none', fontFamily: 'Nunito', fontWeight: 700 }} />
            <Legend wrapperStyle={{ fontFamily: 'Nunito', fontWeight: 700, fontSize: 12 }} />
            <Area type="monotone" dataKey="students" stroke="#6C3CE1" strokeWidth={2.5} fill="url(#g-students)" name="Students" />
            <Area type="monotone" dataKey="sessions" stroke="#10B981" strokeWidth={2.5} fill="url(#g-sessions)" name="Sessions" />
            <Area type="monotone" dataKey="games" stroke="#EC4899" strokeWidth={2.5} fill="url(#g-games)" name="Games" />
          </AreaChart>
        </ResponsiveContainer>
      </Card>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
        {/* Subject Performance */}
        <Card>
          <div style={{ fontFamily: 'Fredoka One', fontSize: 18, marginBottom: 20 }}>Subject Avg. Scores</div>
          <ResponsiveContainer width="100%" height={220}>
            <BarChart data={subjectData} barSize={28}>
              <XAxis dataKey="subject" axisLine={false} tickLine={false} tick={{ fontSize: 11, fontWeight: 700, fill: '#9CA3AF' }} />
              <YAxis hide domain={[0, 100]} />
              <Tooltip contentStyle={{ borderRadius: 12, border: 'none', fontFamily: 'Nunito', fontWeight: 700 }} />
              <Bar dataKey="avg" fill="var(--primary)" radius={[8, 8, 0, 0]} name="Avg Score" />
            </BarChart>
          </ResponsiveContainer>
        </Card>

        {/* Grade Distribution */}
        <Card>
          <div style={{ fontFamily: 'Fredoka One', fontSize: 18, marginBottom: 20 }}>Students by Grade</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 24 }}>
            <ResponsiveContainer width="50%" height={200}>
              <PieChart>
                <Pie data={pieData} cx="50%" cy="50%" innerRadius={55} outerRadius={80} dataKey="value" strokeWidth={0}>
                  {pieData.map((entry) => <Cell key={entry.name} fill={entry.color} />)}
                </Pie>
              </PieChart>
            </ResponsiveContainer>
            <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 10 }}>
              {pieData.map(({ name, value, color }) => (
                <div key={name} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <div style={{ width: 10, height: 10, borderRadius: 3, background: color }} />
                    <span style={{ fontSize: 13, fontWeight: 700 }}>{name}</span>
                  </div>
                  <span style={{ fontSize: 13, fontWeight: 800, color }}>{value}</span>
                </div>
              ))}
            </div>
          </div>
        </Card>
      </div>

      {/* Active Hours */}
      <Card>
        <div style={{ fontFamily: 'Fredoka One', fontSize: 18, marginBottom: 20 }}>Peak Active Hours (Today)</div>
        <ResponsiveContainer width="100%" height={160}>
          <AreaChart data={timeData}>
            <defs>
              <linearGradient id="active-grad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="var(--secondary)" stopOpacity={0.4} />
                <stop offset="95%" stopColor="var(--secondary)" stopOpacity={0} />
              </linearGradient>
            </defs>
            <XAxis dataKey="time" axisLine={false} tickLine={false} tick={{ fontSize: 12, fontWeight: 700, fill: '#9CA3AF' }} />
            <YAxis hide />
            <Tooltip contentStyle={{ borderRadius: 12, border: 'none', fontFamily: 'Nunito', fontWeight: 700 }} />
            <Area type="monotone" dataKey="active" stroke="var(--secondary)" strokeWidth={3} fill="url(#active-grad)" name="Active Students" />
          </AreaChart>
        </ResponsiveContainer>
      </Card>
    </div>
  );
}
