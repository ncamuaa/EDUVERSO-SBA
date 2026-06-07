import { useState } from 'react';
import { User, Bell, Shield, Palette, Globe, Save, ChevronRight } from 'lucide-react';
import Card from '../components/Card';

function Toggle({ value, onChange }) {
  return (
    <div onClick={() => onChange(!value)} style={{
      width: 48, height: 26, borderRadius: 99, background: value ? 'var(--primary)' : 'var(--border)',
      cursor: 'pointer', position: 'relative', transition: 'background 0.2s'
    }}>
      <div style={{
        position: 'absolute', top: 3, left: value ? 25 : 3, width: 20, height: 20,
        borderRadius: '50%', background: '#fff', transition: 'left 0.2s',
        boxShadow: '0 2px 4px rgba(0,0,0,0.2)'
      }} />
    </div>
  );
}

export default function Settings() {
  const [settings, setSettings] = useState({
    emailNotifs: true, pushNotifs: true, weeklyReport: false, newStudentAlert: true,
    feedbackAlert: true, twoFactor: false, activityLog: true,
    darkMode: false, compactMode: false,
  });

  const toggle = key => setSettings(s => ({ ...s, [key]: !s[key] }));

  const sections = [
    {
      icon: User, label: 'Profile', color: 'var(--primary)',
      content: (
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
          {[['Full Name', 'EduVerso Admin'], ['Email', 'admin@eduverso.ph'], ['Role', 'Super Admin'], ['School', 'EduVerso Learning Center']].map(([label, val]) => (
            <div key={label}>
              <label style={{ fontSize: 12, fontWeight: 800, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: 0.5, display: 'block', marginBottom: 6 }}>{label}</label>
              <input defaultValue={val} style={{
                width: '100%', padding: '10px 14px', borderRadius: 10, border: '1.5px solid var(--border)',
                fontSize: 13, fontFamily: 'Nunito', fontWeight: 700, background: 'var(--bg)', color: 'var(--text-primary)', outline: 'none'
              }} />
            </div>
          ))}
        </div>
      )
    },
    {
      icon: Bell, label: 'Notifications', color: 'var(--accent-pink)',
      content: (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          {[
            ['emailNotifs', 'Email Notifications', 'Receive updates via email'],
            ['pushNotifs', 'Push Notifications', 'Mobile push alerts'],
            ['weeklyReport', 'Weekly Report', 'Get summary every Monday'],
            ['newStudentAlert', 'New Student Alerts', 'When a student registers'],
            ['feedbackAlert', 'Feedback Alerts', 'When new feedback arrives'],
          ].map(([key, label, sub]) => (
            <div key={key} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div>
                <div style={{ fontWeight: 800, fontSize: 14 }}>{label}</div>
                <div style={{ fontSize: 12, color: 'var(--text-muted)', fontWeight: 600 }}>{sub}</div>
              </div>
              <Toggle value={settings[key]} onChange={() => toggle(key)} />
            </div>
          ))}
        </div>
      )
    },
    {
      icon: Shield, label: 'Security', color: 'var(--accent-green)',
      content: (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          {[
            ['twoFactor', 'Two-Factor Authentication', 'Extra security for your account'],
            ['activityLog', 'Activity Logging', 'Log all admin actions'],
          ].map(([key, label, sub]) => (
            <div key={key} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div>
                <div style={{ fontWeight: 800, fontSize: 14 }}>{label}</div>
                <div style={{ fontSize: 12, color: 'var(--text-muted)', fontWeight: 600 }}>{sub}</div>
              </div>
              <Toggle value={settings[key]} onChange={() => toggle(key)} />
            </div>
          ))}
          <button style={{
            padding: '10px 20px', borderRadius: 10, background: 'rgba(239,68,68,0.1)', color: 'var(--danger)',
            border: '1.5px solid rgba(239,68,68,0.2)', cursor: 'pointer', fontFamily: 'Nunito', fontWeight: 800, fontSize: 13, alignSelf: 'flex-start'
          }}>Change Password</button>
        </div>
      )
    },
    {
      icon: Palette, label: 'Appearance', color: 'var(--secondary)',
      content: (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          {[
            ['darkMode', 'Dark Mode', 'Coming soon'],
            ['compactMode', 'Compact Mode', 'Denser layout for more info'],
          ].map(([key, label, sub]) => (
            <div key={key} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div>
                <div style={{ fontWeight: 800, fontSize: 14 }}>{label}</div>
                <div style={{ fontSize: 12, color: 'var(--text-muted)', fontWeight: 600 }}>{sub}</div>
              </div>
              <Toggle value={settings[key]} onChange={() => toggle(key)} />
            </div>
          ))}
          <div>
            <div style={{ fontWeight: 800, fontSize: 14, marginBottom: 10 }}>Theme Color</div>
            <div style={{ display: 'flex', gap: 10 }}>
              {['#6C3CE1', '#3B82F6', '#10B981', '#F97316', '#EC4899'].map(c => (
                <div key={c} onClick={() => {}} style={{
                  width: 32, height: 32, borderRadius: 10, background: c, cursor: 'pointer',
                  border: c === '#6C3CE1' ? '3px solid rgba(0,0,0,0.2)' : '3px solid transparent',
                  transition: 'transform 0.15s', transform: c === '#6C3CE1' ? 'scale(1.1)' : 'scale(1)'
                }} />
              ))}
            </div>
          </div>
        </div>
      )
    },
  ];

  return (
    <div style={{ padding: 32, display: 'flex', flexDirection: 'column', gap: 20, maxWidth: 820 }}>
      {sections.map(({ icon: Icon, label, color, content }) => (
        <Card key={label}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 20, paddingBottom: 16, borderBottom: '1px solid var(--border)' }}>
            <div style={{ width: 36, height: 36, borderRadius: 10, background: `${color}15`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Icon size={18} color={color} />
            </div>
            <div style={{ fontFamily: 'Fredoka One', fontSize: 18 }}>{label}</div>
          </div>
          {content}
        </Card>
      ))}

      <button style={{
        display: 'flex', alignItems: 'center', gap: 8, padding: '12px 28px', borderRadius: 14,
        background: 'linear-gradient(135deg, var(--primary), var(--primary-light))',
        color: '#fff', border: 'none', cursor: 'pointer', fontFamily: 'Nunito', fontWeight: 800, fontSize: 15,
        boxShadow: '0 4px 20px rgba(108,60,225,0.35)', alignSelf: 'flex-start'
      }}>
        <Save size={16} /> Save Changes
      </button>
    </div>
  );
}
