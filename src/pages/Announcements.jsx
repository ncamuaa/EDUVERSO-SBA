import { useState, useEffect } from 'react';
import { Plus, Send, Megaphone, Users, Clock, Eye, Trash2, Pin, Check, AlertCircle, X } from 'lucide-react';
import { createClient } from '@supabase/supabase-js';
import Card from '../components/Card';

// ── Supabase client ─────────────────────────────────────────────────────────
const SUPABASE_URL      = import.meta.env.VITE_SUPABASE_URL;
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY;
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// ── Type config ──────────────────────────────────────────────────────────────
const TYPE_OPTIONS = [
  { value: 'Feature',     label: '✨ Feature',     color: '#6C3CE1' },
  { value: 'Achievement', label: '🏆 Achievement', color: '#F59E0B' },
  { value: 'System',      label: '⚙️ System',      color: '#EF4444' },
  { value: 'Tips',        label: '💡 Tips',         color: '#10B981' },
];

const typeColor = (tag) => TYPE_OPTIONS.find(t => t.value === tag)?.color ?? '#6C3CE1';
const typeLabel = (tag) => TYPE_OPTIONS.find(t => t.value === tag)?.label ?? tag;

const DEPARTMENTS = [
  'All Students',
  'College of Engineering',
  'College of Arts and Sciences',
  'College of Business',
  'College of Education',
  'College of Nursing',
  'College of Information Technology',
];

const YEAR_LEVELS = ['All Years', '1st Year', '2nd Year', '3rd Year', '4th Year'];

function formatDisplay(raw) {
  const dt = new Date(raw);
  if (isNaN(dt)) return raw;
  return dt.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

export default function Announcements() {
  const [announcements, setAnnouncements] = useState([]);
  const [loadingList, setLoadingList]     = useState(true);
  const [listError, setListError]         = useState(null);

  const [showForm, setShowForm]     = useState(false);
  const [title, setTitle]           = useState('');
  const [body, setBody]             = useState('');
  const [department, setDepartment] = useState('All Students');
  const [yearLevel, setYearLevel]   = useState('All Years');
  const [type, setType]             = useState('Feature');
  const [pinned, setPinned]         = useState(false);
  const [sending, setSending]       = useState(false);
  const [sent, setSent]             = useState(false);
  const [formError, setFormError]   = useState(null);
  const [deleteId, setDeleteId]     = useState(null);

  useEffect(() => { fetchAnnouncements(); }, []);

  async function fetchAnnouncements() {
    setLoadingList(true); setListError(null);
    const { data, error } = await supabase
      .from('announcements')
      .select('*')
      .order('created_at', { ascending: false });
    if (error) setListError(error.message);
    else setAnnouncements(data ?? []);
    setLoadingList(false);
  }

  function resetForm() {
    setTitle(''); setBody('');
    setDepartment('All Students'); setYearLevel('All Years');
    setType('Feature'); setPinned(false);
    setFormError(null); setSent(false);
  }

  // Build the audience label that goes into badge / audience column
  function getAudienceLabel() {
    if (department === 'All Students') return 'All Students';
    if (yearLevel === 'All Years') return department;
    return `${department} – ${yearLevel}`;
  }

  async function handleSend() {
    if (!title.trim()) { setFormError('Title is required.');   return; }
    if (!body.trim())  { setFormError('Message is required.'); return; }
    setSending(true); setFormError(null);

    const audienceLabel = getAudienceLabel();

    const payload = {
      tag:      type,
      badge:    pinned ? 'Pinned' : audienceLabel,
      title:    title.trim(),
      body:     body.trim(),
      audience: audienceLabel,
      pinned,
    };

    const { data, error } = await supabase
      .from('announcements')
      .insert([payload])
      .select()
      .single();

    if (error) {
      setFormError(error.message);
      setSending(false);
      return;
    }

    setAnnouncements(prev => [data, ...prev]);
    setSent(true);
    setTimeout(() => { setShowForm(false); resetForm(); }, 1000);
    setSending(false);
  }

  async function handleDelete(id) {
    setAnnouncements(prev => prev.filter(a => a.id !== id));
    setDeleteId(null);
    await supabase.from('announcements').delete().eq('id', id);
  }

  const sorted = [...announcements].sort((a, b) => (b.pinned ? 1 : 0) - (a.pinned ? 1 : 0));

  return (
    <div style={{ padding: 32, display: 'flex', flexDirection: 'column', gap: 24 }}>
      <style>{`
        @keyframes slideDown { from{opacity:0;transform:translateY(-8px)} to{opacity:1;transform:translateY(0)} }
        @keyframes pulse     { 0%,100%{opacity:.6} 50%{opacity:.3} }
      `}</style>

      {/* ── Header ── */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ fontFamily: 'Fredoka One', fontSize: 20, color: 'var(--text-primary)' }}>All Announcements</div>
        <button onClick={() => { setShowForm(v => !v); if (showForm) resetForm(); }} style={{
          display: 'flex', alignItems: 'center', gap: 8, padding: '10px 20px', borderRadius: 12,
          background: showForm ? 'var(--bg)' : 'linear-gradient(135deg, var(--primary), var(--primary-light))',
          color: showForm ? 'var(--text-secondary)' : '#fff',
          border: showForm ? '1.5px solid var(--border)' : 'none',
          cursor: 'pointer', fontFamily: 'Nunito', fontWeight: 800, fontSize: 14,
          boxShadow: showForm ? 'none' : '0 4px 16px rgba(108,60,225,0.35)', transition: 'all 0.2s',
        }}>
          {showForm ? <><X size={15} /> Cancel</> : <><Plus size={16} /> New Announcement</>}
        </button>
      </div>

      {/* ── Compose Form ── */}
      {showForm && (
        <Card style={{
          border: '2px solid rgba(108,60,225,0.2)',
          background: 'linear-gradient(135deg, rgba(108,60,225,0.03), rgba(236,72,153,0.02))',
          animation: 'slideDown 0.2s ease',
        }}>
          <div style={{ fontFamily: 'Fredoka One', fontSize: 18, marginBottom: 20, display: 'flex', alignItems: 'center', gap: 8, color: 'var(--text-primary)' }}>
            <Megaphone size={20} color="var(--primary)" /> Compose Announcement
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>

            {/* Title */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              <label style={{ fontSize: 11, fontWeight: 800, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: 0.6 }}>
                Title <span style={{ color: '#ef4444' }}>*</span>
              </label>
              <input value={title} onChange={e => setTitle(e.target.value)} placeholder="Announcement title…"
                style={{ padding: '12px 16px', borderRadius: 12, border: '1.5px solid var(--border)', fontSize: 14, fontFamily: 'Nunito', fontWeight: 700, outline: 'none', background: 'var(--card-bg)', color: 'var(--text-primary)' }}
                onFocus={e => e.target.style.borderColor = '#6C3CE1'}
                onBlur={e  => e.target.style.borderColor = 'var(--border)'} />
            </div>

            {/* Message */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              <label style={{ fontSize: 11, fontWeight: 800, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: 0.6 }}>
                Message <span style={{ color: '#ef4444' }}>*</span>
              </label>
              <textarea value={body} onChange={e => setBody(e.target.value)} placeholder="Write your message here…" rows={4}
                style={{ padding: '12px 16px', borderRadius: 12, border: '1.5px solid var(--border)', fontSize: 14, fontFamily: 'Nunito', fontWeight: 600, outline: 'none', resize: 'vertical', background: 'var(--card-bg)', color: 'var(--text-primary)', lineHeight: 1.6 }}
                onFocus={e => e.target.style.borderColor = '#6C3CE1'}
                onBlur={e  => e.target.style.borderColor = 'var(--border)'} />
            </div>

            {/* Type selector */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              <label style={{ fontSize: 11, fontWeight: 800, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: 0.6 }}>
                Type&nbsp;
                <span style={{ fontSize: 10, fontWeight: 600, textTransform: 'none', letterSpacing: 0, color: 'var(--text-muted)' }}>
                  → appears as <code>tag</code> badge on mobile
                </span>
              </label>
              <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                {TYPE_OPTIONS.map(({ value, label, color }) => (
                  <button key={value} onClick={() => setType(value)} style={{
                    padding: '7px 14px', borderRadius: 10,
                    border: `1.5px solid ${type === value ? color : 'var(--border)'}`,
                    background: type === value ? `${color}15` : 'var(--card-bg)',
                    color: type === value ? color : 'var(--text-secondary)',
                    fontSize: 13, fontWeight: 800, fontFamily: 'Nunito', cursor: 'pointer', transition: 'all 0.15s',
                  }}>{label}</button>
                ))}
              </div>
            </div>

            {/* Department + Year Level + Pin */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr auto', gap: 16, alignItems: 'end' }}>

              {/* Department */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                <label style={{ fontSize: 11, fontWeight: 800, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: 0.6 }}>
                  Department
                </label>
                <select value={department} onChange={e => { setDepartment(e.target.value); setYearLevel('All Years'); }} style={{
                  padding: '10px 14px', borderRadius: 10, border: '1.5px solid var(--border)', fontSize: 13,
                  fontFamily: 'Nunito', fontWeight: 700, background: 'var(--card-bg)', color: 'var(--text-primary)', outline: 'none', cursor: 'pointer',
                }}>
                  {DEPARTMENTS.map(d => <option key={d}>{d}</option>)}
                </select>
              </div>

              {/* Year Level */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                <label style={{ fontSize: 11, fontWeight: 800, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: 0.6 }}>
                  Year Level
                </label>
                <select
                  value={yearLevel}
                  onChange={e => setYearLevel(e.target.value)}
                  disabled={department === 'All Students'}
                  style={{
                    padding: '10px 14px', borderRadius: 10, border: '1.5px solid var(--border)', fontSize: 13,
                    fontFamily: 'Nunito', fontWeight: 700, background: 'var(--card-bg)',
                    color: department === 'All Students' ? 'var(--text-muted)' : 'var(--text-primary)',
                    outline: 'none',
                    cursor: department === 'All Students' ? 'not-allowed' : 'pointer',
                    opacity: department === 'All Students' ? 0.5 : 1,
                  }}>
                  {YEAR_LEVELS.map(y => <option key={y}>{y}</option>)}
                </select>
              </div>

              {/* Pin toggle */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: 6, alignItems: 'center' }}>
                <label style={{ fontSize: 11, fontWeight: 800, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: 0.6 }}>Pin</label>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <button onClick={() => setPinned(v => !v)} style={{
                    width: 48, height: 26, borderRadius: 13, border: 'none', cursor: 'pointer',
                    background: pinned ? '#6C3CE1' : 'var(--border)', position: 'relative', transition: 'background 0.2s',
                  }}>
                    <span style={{
                      position: 'absolute', top: 3, left: pinned ? 25 : 3,
                      width: 20, height: 20, borderRadius: '50%', background: '#fff',
                      transition: 'left 0.2s', boxShadow: '0 1px 4px rgba(0,0,0,0.25)',
                    }} />
                  </button>
                  <Pin size={14} color={pinned ? '#6C3CE1' : 'var(--text-muted)'} />
                </div>
              </div>
            </div>

            {/* Mobile preview */}
            <div style={{ padding: '10px 14px', borderRadius: 10, background: 'rgba(108,60,225,0.06)', border: '1px solid rgba(108,60,225,0.15)', display: 'flex', alignItems: 'center', gap: 10 }}>
              <span style={{ fontSize: 18 }}>📱</span>
              <div style={{ fontSize: 12, color: 'var(--text-secondary)', fontWeight: 600, lineHeight: 1.5 }}>
                Mobile will show — <strong style={{ color: typeColor(type) }}>tag: {type}</strong>
                {' · '}
                <strong style={{ color: '#6C3CE1' }}>badge: {pinned ? 'Pinned' : getAudienceLabel()}</strong>
              </div>
            </div>

            {/* Error */}
            {formError && (
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '10px 14px', borderRadius: 10, background: 'rgba(239,68,68,0.08)', border: '1px solid rgba(239,68,68,0.2)' }}>
                <AlertCircle size={14} color="#ef4444" />
                <span style={{ fontSize: 13, fontWeight: 700, color: '#ef4444' }}>{formError}</span>
              </div>
            )}

            {/* Send */}
            <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
              <button onClick={handleSend} disabled={sending || sent} style={{
                display: 'flex', alignItems: 'center', gap: 8, padding: '11px 28px', borderRadius: 12,
                background: sent ? '#10B981' : 'linear-gradient(135deg, var(--primary), var(--primary-light))',
                color: '#fff', border: 'none', cursor: sending || sent ? 'default' : 'pointer',
                fontFamily: 'Nunito', fontWeight: 800, fontSize: 14,
                boxShadow: sent ? '0 4px 16px rgba(16,185,129,0.35)' : '0 4px 16px rgba(108,60,225,0.35)',
                opacity: sending ? 0.75 : 1, transition: 'all 0.2s',
              }}>
                {sent ? <><Check size={15} /> Sent!</> : sending ? 'Sending…' : <><Send size={15} /> Send Now</>}
              </button>
            </div>
          </div>
        </Card>
      )}

      {/* ── Announcement list ── */}
      {loadingList ? (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          {Array(3).fill(0).map((_, i) => (
            <div key={i} style={{ height: 120, borderRadius: 16, background: 'var(--card-bg)', border: '1px solid var(--border)', animation: 'pulse 1.5s ease-in-out infinite' }} />
          ))}
        </div>
      ) : listError ? (
        <Card style={{ padding: 32, textAlign: 'center' }}>
          <div style={{ fontSize: 32, marginBottom: 8 }}>⚠️</div>
          <div style={{ fontWeight: 700, color: '#ef4444', marginBottom: 12 }}>{listError}</div>
          <button onClick={fetchAnnouncements} style={{ padding: '8px 20px', borderRadius: 10, background: 'var(--primary)', color: '#fff', border: 'none', cursor: 'pointer', fontFamily: 'Nunito', fontWeight: 700 }}>
            Retry
          </button>
        </Card>
      ) : sorted.length === 0 ? (
        <Card style={{ padding: 48, textAlign: 'center' }}>
          <div style={{ fontSize: 40, marginBottom: 12 }}>📭</div>
          <div style={{ fontWeight: 700, color: 'var(--text-primary)', marginBottom: 4 }}>No announcements yet</div>
          <div style={{ fontSize: 13, color: 'var(--text-muted)', fontWeight: 600 }}>Create your first announcement above</div>
        </Card>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          {sorted.map(a => {
            const color = typeColor(a.tag);
            return (
              <Card key={a.id} style={{
                display: 'flex', gap: 16, padding: '20px 24px',
                borderLeft: `4px solid ${color}`,
                position: 'relative',
              }}>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8, flexWrap: 'wrap' }}>
                    <span style={{ fontSize: 11, fontWeight: 800, color, background: `${color}15`, padding: '3px 8px', borderRadius: 6 }}>
                      {typeLabel(a.tag)}
                    </span>
                    {a.badge && (
                      <span style={{ fontSize: 11, fontWeight: 800, color: '#6C3CE1', background: 'rgba(108,60,225,0.1)', padding: '3px 8px', borderRadius: 6, display: 'flex', alignItems: 'center', gap: 4 }}>
                        {a.badge === 'Pinned'
                          ? <><Pin size={10} /> Pinned</>
                          : <><Users size={10} /> {a.badge}</>}
                      </span>
                    )}
                  </div>

                  <h3 style={{ fontFamily: 'Fredoka One', fontSize: 17, marginBottom: 6, color: 'var(--text-primary)' }}>{a.title}</h3>
                  <p style={{ fontSize: 13, color: 'var(--text-secondary)', fontWeight: 600, lineHeight: 1.6, marginBottom: 12 }}>{a.body}</p>

                  <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 5, fontSize: 12, fontWeight: 700, color: 'var(--text-muted)' }}>
                      <Clock size={12} /> {formatDisplay(a.created_at)}
                    </div>
                    {a.views != null && (
                      <div style={{ display: 'flex', alignItems: 'center', gap: 5, fontSize: 12, fontWeight: 700, color: 'var(--text-muted)' }}>
                        <Eye size={12} /> {(a.views ?? 0).toLocaleString()} views
                      </div>
                    )}
                  </div>
                </div>

                {deleteId === a.id ? (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 6, alignSelf: 'flex-start', alignItems: 'flex-end' }}>
                    <span style={{ fontSize: 11, fontWeight: 700, color: 'var(--text-muted)' }}>Delete?</span>
                    <div style={{ display: 'flex', gap: 6 }}>
                      <button onClick={() => handleDelete(a.id)} style={{ padding: '4px 10px', borderRadius: 7, background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.2)', color: '#ef4444', fontSize: 12, fontWeight: 800, fontFamily: 'Nunito', cursor: 'pointer' }}>Yes</button>
                      <button onClick={() => setDeleteId(null)} style={{ padding: '4px 10px', borderRadius: 7, background: 'var(--bg)', border: '1px solid var(--border)', color: 'var(--text-secondary)', fontSize: 12, fontWeight: 800, fontFamily: 'Nunito', cursor: 'pointer' }}>No</button>
                    </div>
                  </div>
                ) : (
                  <button onClick={() => setDeleteId(a.id)}
                    style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#ef4444', opacity: 0.4, alignSelf: 'flex-start', padding: 4, transition: 'opacity 0.15s' }}
                    onMouseOver={e => e.currentTarget.style.opacity = 1}
                    onMouseOut={e  => e.currentTarget.style.opacity = 0.4}>
                    <Trash2 size={16} />
                  </button>
                )}
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}