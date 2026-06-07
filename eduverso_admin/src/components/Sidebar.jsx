import { NavLink, useLocation } from 'react-router-dom';
import {
  LayoutDashboard, Users, BookOpen, Gamepad2, BarChart3,
  Megaphone, MessageSquare, Settings, GraduationCap, LogOut, Sparkles
} from 'lucide-react';

const nav = [
  { to: '/', icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/students', icon: Users, label: 'Students' },
  { to: '/modules', icon: BookOpen, label: 'Modules' },
  { to: '/games', icon: Gamepad2, label: 'Games' },
  { to: '/stats', icon: BarChart3, label: 'Stats' },
  { to: '/announcements', icon: Megaphone, label: 'Announcements' },
  { to: '/feedback', icon: MessageSquare, label: 'Feedback' },
  { to: '/settings', icon: Settings, label: 'Settings' },
];

export default function Sidebar() {
  return (
    <aside style={{
      width: 240, minWidth: 240, minHeight: '100vh', background: 'var(--sidebar-bg)',
      display: 'flex', flexDirection: 'column', padding: '24px 0',
      position: 'sticky', top: 0, height: '100vh', flexShrink: 0,
      boxShadow: '4px 0 32px rgba(108,60,225,0.18)'
    }}>
      {/* Logo */}
      <div style={{ padding: '0 20px 20px', display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 44, height: 44, borderRadius: 14,
          background: 'linear-gradient(135deg, var(--primary), var(--accent-pink))',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 4px 16px rgba(108,60,225,0.5)'
        }}>
          <GraduationCap size={24} color="#fff" />
        </div>
        <div>
          <div style={{ fontFamily: 'Fredoka One', fontSize: 20, color: '#fff', lineHeight: 1 }}>EduVerso</div>
          <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.4)', fontWeight: 600, letterSpacing: 1 }}>ADMIN PANEL</div>
        </div>
      </div>

      {/* Nav */}
      <nav style={{ flex: 1, padding: '0 10px', display: 'flex', flexDirection: 'column', gap: 2 }}>
        {nav.map(({ to, icon: Icon, label }) => (
          <NavLink key={to} to={to} end={to === '/'} style={({ isActive }) => ({
            display: 'flex', alignItems: 'center', gap: 12,
            padding: '9px 12px', borderRadius: 10, textDecoration: 'none',
            fontWeight: 700, fontSize: 14, transition: 'all 0.18s',
            background: isActive ? 'linear-gradient(90deg, var(--primary), var(--primary-light))' : 'transparent',
            color: isActive ? '#fff' : 'rgba(255,255,255,0.55)',
            boxShadow: isActive ? '0 4px 16px rgba(108,60,225,0.4)' : 'none',
          })}>
            <Icon size={18} />
            {label}
          </NavLink>
        ))}
      </nav>

      {/* Bottom */}
      <div style={{ padding: '12px 10px 0' }}>
        <div style={{
          margin: '0 0 10px', padding: '12px', borderRadius: 14,
          background: 'linear-gradient(135deg, rgba(108,60,225,0.5), rgba(236,72,153,0.3))',
          border: '1px solid rgba(255,255,255,0.1)'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
            <Sparkles size={14} color="var(--secondary)" />
            <span style={{ fontSize: 12, fontWeight: 800, color: '#fff' }}>Pro Tip</span>
          </div>
          <p style={{ fontSize: 11, color: 'rgba(255,255,255,0.6)', lineHeight: 1.5 }}>
            Send announcements to boost student engagement this week!
          </p>
        </div>
        <button
  onClick={() => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    window.location.href = '/login';
  }}
  style={{
    display: 'flex', alignItems: 'center', gap: 10, width: '100%',
    padding: '11px 14px', borderRadius: 12, background: 'transparent',
    border: 'none', cursor: 'pointer', color: 'rgba(255,255,255,0.4)',
    fontWeight: 700, fontSize: 13, fontFamily: 'Nunito', transition: 'all 0.18s'
  }}
  onMouseOver={e => e.currentTarget.style.color = '#fff'}
  onMouseOut={e => e.currentTarget.style.color = 'rgba(255,255,255,0.4)'}
>
  <LogOut size={16} /> Log Out
</button>
      </div>
    </aside>
  );
}

