import { useState, useEffect } from 'react';
import { User, Bell, Shield, Palette, Save } from 'lucide-react';
import Card from '../components/Card';
import { supabase } from '../lib/supabase';

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

const THEMES = ['#6C3CE1', '#3B82F6', '#10B981', '#F97316', '#EC4899'];

const defaultProfile = { fullName: 'EduVerso Admin', email: 'admin@eduverso.ph', role: 'Super Admin', school: 'EduVerso Learning Center' };
const defaultNotifs = { emailNotifs: true, pushNotifs: true, weeklyReport: false, newStudentAlert: true, feedbackAlert: true };
const defaultSecurity = { twoFactor: false, activityLog: true };
const defaultAppearance = { darkMode: false, compactMode: false, themeColor: '#6C3CE1' };

function load(key, fallback) {
  try { return JSON.parse(localStorage.getItem(key)) ?? fallback; } catch { return fallback; }
}

function applyTheme(color, dark, compact) {
  const root = document.documentElement;
  root.style.setProperty('--primary', color);
  // derive a lighter shade
  root.style.setProperty('--primary-light', color + 'bb');

  if (dark) {
    root.style.setProperty('--bg', '#0f0f1a');
    root.style.setProperty('--surface', '#1a1a2e');
    root.style.setProperty('--text-primary', '#f1f1f1');
    root.style.setProperty('--text-secondary', '#a0a0b0');
    root.style.setProperty('--text-muted', '#606080');
    root.style.setProperty('--border', '#2a2a3a');
  } else {
    root.style.setProperty('--bg', '#f8f7ff');
    root.style.setProperty('--surface', '#ffffff');
    root.style.setProperty('--text-primary', '#1a1a2e');
    root.style.setProperty('--text-secondary', '#4a4a6a');
    root.style.setProperty('--text-muted', '#9090a0');
    root.style.setProperty('--border', '#e8e6f0');
  }

  document.body.style.fontSize = compact ? '13px' : '';
}

export default function Settings() {
  const [profile, setProfile] = useState(() => load('admin_profile', defaultProfile));
  const [notifs, setNotifs] = useState(() => load('admin_notifs', defaultNotifs));
  const [security, setSecurity] = useState(() => load('admin_security', defaultSecurity));
  const [appearance, setAppearance] = useState(() => load('admin_appearance', defaultAppearance));

  const [passwords, setPasswords] = useState({ current: '', newPass: '', confirm: '' });
  const [pwStatus, setPwStatus] = useState('');
  const [saveStatus, setSaveStatus] = useState('');

  // Apply theme on mount
  useEffect(() => {
    applyTheme(appearance.themeColor, appearance.darkMode, appearance.compactMode);
  }, []);

  const handleSave = () => {
    localStorage.setItem('admin_profile', JSON.stringify(profile));
    localStorage.setItem('admin_notifs', JSON.stringify(notifs));
    localStorage.setItem('admin_security', JSON.stringify(security));
    localStorage.setItem('admin_appearance', JSON.stringify(appearance));
    applyTheme(appearance.themeColor, appearance.darkMode, appearance.compactMode);
    setSaveStatus('✅ Settings saved!');
    setTimeout(() => setSaveStatus(''), 2500);
  };

  const handlePasswordChange = async () => {
    if (!passwords.newPass || passwords.newPass !== passwords.confirm) {
      setPwStatus('❌ Passwords do not match.');
      return;
    }
    if (passwords.newPass.length < 6) {
      setPwStatus('❌ Password must be at least 6 characters.');
      return;
    }
    try {
      const { error } = await supabase.auth.updateUser({ password: passwords.newPass });
      if (error) throw error;
      setPwStatus('✅ Password updated successfully.');
      setPasswords({ current: '', newPass: '', confirm: '' });
    } catch (err) {
      setPwStatus(`❌ ${err.message}`);
    }
    setTimeout(() => setPwStatus(''), 3000);
  };

  const inputStyle = {
    width: '100%', padding: '10px 14px', borderRadius: 10,
    border: '1.5px solid var(--border)', fontSize: 13,
    fontFamily: 'Nunito', fontWeight: 700,
    background: 'var(--bg)', color: 'var(--text-primary)', outline: 'none',
    boxSizing: 'border-box',
  };

  const sections = [
    {
      icon: User, label: 'Profile', color: 'var(--primary)',
      content: (
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
          {[
            ['Full Name', 'fullName'],
            ['Email', 'email'],
            ['Role', 'role'],
            ['School', 'school'],
          ].map(([label, key]) => (
            <div key={key}>
              <label style={{ fontSize: 12, fontWeight: 800, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: 0.5, display: 'block', marginBottom: 6 }}>{label}</label>
              <input
                value={profile[key]}
                onChange={e => setProfile(p => ({ ...p, [key]: e.target.value }))}
                style={inputStyle}
              />
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
              <Toggle value={notifs[key]} onChange={v => setNotifs(n => ({ ...n, [key]: v }))} />
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
              <Toggle value={security[key]} onChange={v => setSecurity(s => ({ ...s, [key]: v }))} />
            </div>
          ))}

          <div style={{ borderTop: '1px solid var(--border)', paddingTop: 14, display: 'flex', flexDirection: 'column', gap: 10 }}>
            <div style={{ fontWeight: 800, fontSize: 14 }}>Change Password</div>
            {[
              ['newPass', 'New Password'],
              ['confirm', 'Confirm New Password'],
            ].map(([key, label]) => (
              <div key={key}>
                <label style={{ fontSize: 12, fontWeight: 800, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: 0.5, display: 'block', marginBottom: 4 }}>{label}</label>
                <input
                  type="password"
                  value={passwords[key]}
                  onChange={e => setPasswords(p => ({ ...p, [key]: e.target.value }))}
                  style={inputStyle}
                />
              </div>
            ))}
            {pwStatus && <div style={{ fontSize: 13, fontWeight: 700, color: pwStatus.startsWith('✅') ? 'var(--accent-green)' : 'var(--danger)' }}>{pwStatus}</div>}
            <button onClick={handlePasswordChange} style={{
              padding: '10px 20px', borderRadius: 10,
              background: 'rgba(239,68,68,0.1)', color: 'var(--danger)',
              border: '1.5px solid rgba(239,68,68,0.2)', cursor: 'pointer',
              fontFamily: 'Nunito', fontWeight: 800, fontSize: 13, alignSelf: 'flex-start'
            }}>Update Password</button>
          </div>
        </div>
      )
    },
    {
      icon: Palette, label: 'Appearance', color: 'var(--secondary)',
      content: (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          {[
            ['darkMode', 'Dark Mode', 'Switch to dark theme'],
            ['compactMode', 'Compact Mode', 'Denser layout for more info'],
          ].map(([key, label, sub]) => (
            <div key={key} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div>
                <div style={{ fontWeight: 800, fontSize: 14 }}>{label}</div>
                <div style={{ fontSize: 12, color: 'var(--text-muted)', fontWeight: 600 }}>{sub}</div>
              </div>
              <Toggle
                value={appearance[key]}
                onChange={v => {
                  const updated = { ...appearance, [key]: v };
                  setAppearance(updated);
                  applyTheme(updated.themeColor, updated.darkMode, updated.compactMode);
                }}
              />
            </div>
          ))}
          <div>
            <div style={{ fontWeight: 800, fontSize: 14, marginBottom: 10 }}>Theme Color</div>
            <div style={{ display: 'flex', gap: 10 }}>
              {THEMES.map(c => (
                <div key={c} onClick={() => {
                  const updated = { ...appearance, themeColor: c };
                  setAppearance(updated);
                  applyTheme(c, updated.darkMode, updated.compactMode);
                }} style={{
                  width: 32, height: 32, borderRadius: 10, background: c, cursor: 'pointer',
                  border: appearance.themeColor === c ? '3px solid rgba(0,0,0,0.3)' : '3px solid transparent',
                  transition: 'transform 0.15s',
                  transform: appearance.themeColor === c ? 'scale(1.15)' : 'scale(1)'
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

      {saveStatus && (
        <div style={{ fontSize: 14, fontWeight: 700, color: 'var(--accent-green)' }}>{saveStatus}</div>
      )}

      <button onClick={handleSave} style={{
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