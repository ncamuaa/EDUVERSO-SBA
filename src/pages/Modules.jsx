import { useState, useEffect, useRef } from 'react';
import { Plus, Edit2, Eye, Search, X, RefreshCw, BookOpen, ChevronRight, Save, AlertCircle, Check } from 'lucide-react';
import Card from '../components/Card';

const COLORS = ['#6C3CE1', '#10B981', '#F59E0B', '#3B82F6', '#EC4899', '#F97316', '#8B5CF6', '#06B6D4'];
const EMOJIS = ['📚', '🔬', '🔢', '✏️', '🏛️', '🎨', '💻', '🧪', '🌍', '📖'];

function colorForId(id) { return COLORS[id % COLORS.length]; }
function emojiForSubject(subject = '') {
  const s = subject.toLowerCase();
  if (s.includes('math'))    return '🔢';
  if (s.includes('science')) return '🔬';
  if (s.includes('english')) return '✏️';
  if (s.includes('filipino') || s.includes('wika')) return '📚';
  if (s.includes('history') || s.includes('araling')) return '🏛️';
  if (s.includes('music') || s.includes('art') || s.includes('mapeh')) return '🎨';
  if (s.includes('it') || s.includes('computer') || s.includes('tech')) return '💻';
  if (s.includes('nursing') || s.includes('health')) return '🏥';
  if (s.includes('business') || s.includes('account')) return '💼';
  if (s.includes('engineering')) return '⚙️';
  return EMOJIS[Math.abs(subject.charCodeAt(0) || 0) % EMOJIS.length];
}

// ── Modal backdrop ─────────────────────────────────────────────────────────
function Modal({ children, onClose }) {
  useEffect(() => {
    const handler = e => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [onClose]);

  return (
    <div onClick={onClose} style={{
      position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.45)',
      backdropFilter: 'blur(4px)', zIndex: 1000,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      padding: 24, animation: 'fadeIn 0.15s ease',
    }}>
      <div onClick={e => e.stopPropagation()} style={{
        background: 'var(--card-bg)', borderRadius: 20,
        border: '1.5px solid var(--border)',
        boxShadow: '0 24px 64px rgba(0,0,0,0.25)',
        width: '100%', maxWidth: 600, maxHeight: '88vh',
        overflowY: 'auto', animation: 'slideUp 0.2s ease',
      }}>
        {children}
      </div>
    </div>
  );
}

// ── View Modal ─────────────────────────────────────────────────────────────
function ViewModal({ module: m, onClose, onEdit, token }) {
  const [lessons, setLessons]   = useState([]);
  const [loading, setLoading]   = useState(true);
  const color = colorForId(m.id);
  const emoji = emojiForSubject(m.subject);

  useEffect(() => {
    fetch(`${import.meta.env.VITE_API_URL}/api/lessons/module/${m.id}`,
      { headers: { Authorization: `Bearer ${token}` } })
      .then(r => r.json())
      .then(d => { if (d.success) setLessons(d.lessons); })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [m.id]);

  return (
    <Modal onClose={onClose}>
      {/* Header */}
      <div style={{
        padding: '24px 24px 20px',
        background: `linear-gradient(135deg, ${color}18, ${color}30)`,
        borderBottom: `3px solid ${color}33`,
        borderRadius: '18px 18px 0 0',
        display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 12,
      }}>
        <div style={{ display: 'flex', gap: 14, alignItems: 'flex-start' }}>
          <div style={{ fontSize: 42, lineHeight: 1 }}>{emoji}</div>
          <div>
            <div style={{ fontSize: 11, fontWeight: 800, color, textTransform: 'uppercase', letterSpacing: 0.8, marginBottom: 4 }}>{m.subject}</div>
            <div style={{ fontFamily: 'Fredoka One', fontSize: 22, color: 'var(--text-primary)', lineHeight: 1.2, marginBottom: 6 }}>{m.title}</div>
            <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
              {[m.grade_level, m.course].filter(Boolean).map(tag => (
                <span key={tag} style={{ fontSize: 11, fontWeight: 800, padding: '3px 10px', borderRadius: 20, background: `${color}18`, color, border: `1px solid ${color}33` }}>{tag}</span>
              ))}
            </div>
          </div>
        </div>
        <div style={{ display: 'flex', gap: 8, flexShrink: 0 }}>
          <button onClick={() => { onClose(); onEdit(m); }} style={{
            display: 'flex', alignItems: 'center', gap: 6, padding: '8px 14px',
            borderRadius: 10, background: `${color}15`, border: `1.5px solid ${color}30`,
            cursor: 'pointer', fontSize: 13, fontWeight: 700, color, fontFamily: 'Nunito',
          }}><Edit2 size={13} /> Edit</button>
          <button onClick={onClose} style={{
            width: 34, height: 34, borderRadius: 10, background: 'rgba(0,0,0,0.08)',
            border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}><X size={15} color="var(--text-secondary)" /></button>
        </div>
      </div>

      {/* Description */}
      {m.description && (
        <div style={{ padding: '16px 24px 0', fontSize: 14, color: 'var(--text-secondary)', fontWeight: 600, lineHeight: 1.6 }}>
          {m.description}
        </div>
      )}

      {/* Lessons */}
      <div style={{ padding: '16px 24px 24px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
          <BookOpen size={15} color={color} />
          <span style={{ fontFamily: 'Fredoka One', fontSize: 15, color: 'var(--text-primary)' }}>
            Lessons {!loading && <span style={{ fontSize: 13, fontWeight: 700, color: 'var(--text-muted)' }}>({lessons.length})</span>}
          </span>
        </div>

        {loading ? (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {Array(4).fill(0).map((_, i) => (
              <div key={i} style={{ height: 48, borderRadius: 10, background: 'var(--bg)', animation: 'pulse 1.5s ease-in-out infinite' }} />
            ))}
          </div>
        ) : lessons.length === 0 ? (
          <div style={{ padding: '24px', textAlign: 'center', color: 'var(--text-muted)', fontSize: 13, fontWeight: 600 }}>
            No lessons added yet.
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
            {lessons.map((l, i) => (
              <div key={l.id} style={{
                display: 'flex', alignItems: 'center', gap: 12,
                padding: '10px 14px', borderRadius: 10,
                background: 'var(--bg)', border: '1px solid var(--border)',
              }}>
                <div style={{
                  width: 26, height: 26, borderRadius: 8, flexShrink: 0,
                  background: `${color}18`, display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 12, fontWeight: 800, color,
                }}>{i + 1}</div>
                <span style={{ flex: 1, fontSize: 13, fontWeight: 700, color: 'var(--text-primary)' }}>{l.title}</span>
                <ChevronRight size={14} color="var(--text-muted)" />
              </div>
            ))}
          </div>
        )}
      </div>
    </Modal>
  );
}

// ── Edit Modal ─────────────────────────────────────────────────────────────
function EditModal({ module: m, onClose, onSaved, token }) {
  const [form, setForm]     = useState({
    title:       m.title       || '',
    description: m.description || '',
    subject:     m.subject     || '',
    grade_level: m.grade_level || '',
    course:      m.course      || '',
    order_index: m.order_index ?? 0,
  });
  const [saving, setSaving]   = useState(false);
  const [error, setError]     = useState(null);
  const [saved, setSaved]     = useState(false);
  const color = colorForId(m.id);

  function set(key, val) { setForm(f => ({ ...f, [key]: val })); }

  async function handleSave() {
    if (!form.title.trim()) { setError('Title is required.'); return; }
    setSaving(true); setError(null);
    try {
      const res = await fetch(`${import.meta.env.VITE_API_URL}/api/modules/${m.id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify(form),
      });
      const data = await res.json();
      if (!data.success) throw new Error(data.message || 'Save failed');
      setSaved(true);
      setTimeout(() => { onSaved({ ...m, ...form }); onClose(); }, 900);
    } catch (e) {
      setError(e.message);
    } finally {
      setSaving(false);
    }
  }

  const Field = ({ label, field, multiline = false, type = 'text' }) => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      <label style={{ fontSize: 12, fontWeight: 800, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: 0.6 }}>{label}</label>
      {multiline ? (
        <textarea value={form[field]} onChange={e => set(field, e.target.value)} rows={3}
          style={{ padding: '10px 14px', borderRadius: 10, border: '1.5px solid var(--border)', background: 'var(--bg)', color: 'var(--text-primary)', fontFamily: 'Nunito', fontSize: 14, fontWeight: 600, outline: 'none', resize: 'vertical', lineHeight: 1.5 }}
          onFocus={e => e.target.style.borderColor = color}
          onBlur={e => e.target.style.borderColor = 'var(--border)'} />
      ) : (
        <input type={type} value={form[field]} onChange={e => set(field, e.target.value)}
          style={{ padding: '10px 14px', borderRadius: 10, border: '1.5px solid var(--border)', background: 'var(--bg)', color: 'var(--text-primary)', fontFamily: 'Nunito', fontSize: 14, fontWeight: 600, outline: 'none' }}
          onFocus={e => e.target.style.borderColor = color}
          onBlur={e => e.target.style.borderColor = 'var(--border)'} />
      )}
    </div>
  );

  return (
    <Modal onClose={onClose}>
      {/* Header */}
      <div style={{ padding: '20px 24px', borderBottom: '1px solid var(--border)', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ fontFamily: 'Fredoka One', fontSize: 18, color: 'var(--text-primary)' }}>Edit Module</div>
        <button onClick={onClose} style={{ width: 32, height: 32, borderRadius: 8, background: 'var(--bg)', border: '1px solid var(--border)', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <X size={14} color="var(--text-secondary)" />
        </button>
      </div>

      {/* Form */}
      <div style={{ padding: '20px 24px', display: 'flex', flexDirection: 'column', gap: 16 }}>
        <Field label="Title *"       field="title" />
        <Field label="Description"   field="description" multiline />
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
          <Field label="Subject"     field="subject" />
          <Field label="Grade Level" field="grade_level" />
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
          <Field label="Course"      field="course" />
          <Field label="Order Index" field="order_index" type="number" />
        </div>

        {error && (
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '10px 14px', borderRadius: 10, background: 'rgba(239,68,68,0.08)', border: '1px solid rgba(239,68,68,0.2)' }}>
            <AlertCircle size={14} color="#ef4444" />
            <span style={{ fontSize: 13, fontWeight: 700, color: '#ef4444' }}>{error}</span>
          </div>
        )}
      </div>

      {/* Footer */}
      <div style={{ padding: '0 24px 20px', display: 'flex', gap: 10, justifyContent: 'flex-end' }}>
        <button onClick={onClose} style={{ padding: '10px 20px', borderRadius: 12, background: 'var(--bg)', border: '1.5px solid var(--border)', cursor: 'pointer', fontFamily: 'Nunito', fontWeight: 700, fontSize: 14, color: 'var(--text-secondary)' }}>
          Cancel
        </button>
        <button onClick={handleSave} disabled={saving || saved} style={{
          display: 'flex', alignItems: 'center', gap: 8, padding: '10px 24px',
          borderRadius: 12, border: 'none', cursor: saving || saved ? 'default' : 'pointer',
          fontFamily: 'Nunito', fontWeight: 800, fontSize: 14, color: '#fff',
          background: saved ? '#10B981' : `linear-gradient(135deg, ${color}, ${color}cc)`,
          opacity: saving ? 0.7 : 1, transition: 'all 0.2s',
          boxShadow: `0 4px 16px ${color}44`,
        }}>
          {saved ? <><Check size={15} /> Saved!</> : saving ? 'Saving…' : <><Save size={15} /> Save Changes</>}
        </button>
      </div>
    </Modal>
  );
}

// ── Create Modal ───────────────────────────────────────────────────────────
function CreateModal({ onClose, onCreated, token }) {
  const [form, setForm] = useState({
    title: '', description: '', subject: '',
    grade_level: '', course: '', order_index: 0,
  });
  const [saving, setSaving] = useState(false);
  const [error, setError]   = useState(null);
  const [saved, setSaved]   = useState(false);
  const color = '#6C3CE1';

  function set(key, val) { setForm(f => ({ ...f, [key]: val })); }

  async function handleCreate() {
    if (!form.title.trim())   { setError('Title is required.');   return; }
    if (!form.subject.trim()) { setError('Subject is required.'); return; }
    setSaving(true); setError(null);
    try {
      const res = await fetch(`${import.meta.env.VITE_API_URL}/api/modules', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify(form),
      });
      const data = await res.json();
      if (!data.success) throw new Error(data.message || 'Create failed');
      setSaved(true);
      setTimeout(() => { onCreated(data.module); onClose(); }, 900);
    } catch (e) {
      setError(e.message);
    } finally {
      setSaving(false);
    }
  }

  const Field = ({ label, field, multiline = false, type = 'text', required = false }) => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      <label style={{ fontSize: 12, fontWeight: 800, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: 0.6 }}>
        {label}{required && <span style={{ color: '#ef4444', marginLeft: 2 }}>*</span>}
      </label>
      {multiline ? (
        <textarea value={form[field]} onChange={e => set(field, e.target.value)} rows={3}
          style={{ padding: '10px 14px', borderRadius: 10, border: '1.5px solid var(--border)', background: 'var(--bg)', color: 'var(--text-primary)', fontFamily: 'Nunito', fontSize: 14, fontWeight: 600, outline: 'none', resize: 'vertical', lineHeight: 1.5 }}
          onFocus={e => e.target.style.borderColor = color}
          onBlur={e => e.target.style.borderColor = 'var(--border)'} />
      ) : (
        <input type={type} value={form[field]} onChange={e => set(field, e.target.value)}
          style={{ padding: '10px 14px', borderRadius: 10, border: '1.5px solid var(--border)', background: 'var(--bg)', color: 'var(--text-primary)', fontFamily: 'Nunito', fontSize: 14, fontWeight: 600, outline: 'none' }}
          onFocus={e => e.target.style.borderColor = color}
          onBlur={e => e.target.style.borderColor = 'var(--border)'} />
      )}
    </div>
  );

  return (
    <Modal onClose={onClose}>
      {/* Header */}
      <div style={{
        padding: '20px 24px',
        background: 'linear-gradient(135deg, #6C3CE115, #6C3CE130)',
        borderBottom: '3px solid #6C3CE133',
        borderRadius: '18px 18px 0 0',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{ width: 36, height: 36, borderRadius: 10, background: 'linear-gradient(135deg, #6C3CE1, #8B5CF6)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18 }}>✨</div>
          <div style={{ fontFamily: 'Fredoka One', fontSize: 20, color: 'var(--text-primary)' }}>Create New Module</div>
        </div>
        <button onClick={onClose} style={{ width: 32, height: 32, borderRadius: 8, background: 'rgba(0,0,0,0.08)', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <X size={14} color="var(--text-secondary)" />
        </button>
      </div>

      {/* Form */}
      <div style={{ padding: '20px 24px', display: 'flex', flexDirection: 'column', gap: 16 }}>
        <Field label="Title"       field="title"       required />
        <Field label="Description" field="description" multiline />
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
          <Field label="Subject"     field="subject"     required />
          <Field label="Grade Level" field="grade_level" />
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
          <Field label="Course"      field="course" />
          <Field label="Order Index" field="order_index" type="number" />
        </div>

        {error && (
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '10px 14px', borderRadius: 10, background: 'rgba(239,68,68,0.08)', border: '1px solid rgba(239,68,68,0.2)' }}>
            <AlertCircle size={14} color="#ef4444" />
            <span style={{ fontSize: 13, fontWeight: 700, color: '#ef4444' }}>{error}</span>
          </div>
        )}
      </div>

      {/* Footer */}
      <div style={{ padding: '0 24px 20px', display: 'flex', gap: 10, justifyContent: 'flex-end' }}>
        <button onClick={onClose} style={{ padding: '10px 20px', borderRadius: 12, background: 'var(--bg)', border: '1.5px solid var(--border)', cursor: 'pointer', fontFamily: 'Nunito', fontWeight: 700, fontSize: 14, color: 'var(--text-secondary)' }}>
          Cancel
        </button>
        <button onClick={handleCreate} disabled={saving || saved} style={{
          display: 'flex', alignItems: 'center', gap: 8, padding: '10px 24px',
          borderRadius: 12, border: 'none', cursor: saving || saved ? 'default' : 'pointer',
          fontFamily: 'Nunito', fontWeight: 800, fontSize: 14, color: '#fff',
          background: saved ? '#10B981' : 'linear-gradient(135deg, #6C3CE1, #8B5CF6)',
          opacity: saving ? 0.7 : 1, transition: 'all 0.2s',
          boxShadow: '0 4px 16px rgba(108,60,225,0.44)',
        }}>
          {saved ? <><Check size={15} /> Created!</> : saving ? 'Creating…' : <><Plus size={15} /> Create Module</>}
        </button>
      </div>
    </Modal>
  );
}

// ── Main Page ──────────────────────────────────────────────────────────────
export default function Modules() {
  const [view, setView]         = useState('grid');
  const [modules, setModules]   = useState([]);
  const [filters, setFilters]   = useState({ subjects: [], grades: [], courses: [] });
  const [loading, setLoading]   = useState(true);
  const [error, setError]       = useState(null);
  const [search, setSearch]     = useState('');
  const [filterSubject, setSubject] = useState('');
  const [filterGrade, setGrade]     = useState('');
  const [filterCourse, setCourse]   = useState('');
  const [viewing, setViewing]   = useState(null);
  const [editing, setEditing]   = useState(null);
  const [creating, setCreating] = useState(false); // ← new

  const token = localStorage.getItem('token');

  async function fetchModules() {
    setLoading(true); setError(null);
    try {
      const params = new URLSearchParams();
      if (filterSubject) params.set('subject', filterSubject);
      if (filterGrade)   params.set('grade',   filterGrade);
      if (filterCourse)  params.set('course',  filterCourse);
      const res  = await fetch(`${import.meta.env.VITE_API_URL}/api/modules?${params}`,
        { headers: { Authorization: `Bearer ${token}` } });
      const data = await res.json();
      if (!data.success) throw new Error(data.message || 'Failed to load modules');
      setModules(data.modules);
      if (data.filters) setFilters(data.filters);
    } catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { fetchModules(); }, [filterSubject, filterGrade, filterCourse]);

  function handleSaved(updated) {
    setModules(prev => prev.map(m => m.id === updated.id ? { ...m, ...updated } : m));
  }

  function handleCreated(newModule) { // ← new
    setModules(prev => [newModule, ...prev]);
  }

  const displayed = modules.filter(m =>
    !search || m.title?.toLowerCase().includes(search.toLowerCase()) ||
    m.subject?.toLowerCase().includes(search.toLowerCase()) ||
    m.course?.toLowerCase().includes(search.toLowerCase())
  );

  const hasFilters = filterSubject || filterGrade || filterCourse || search;

  function clearFilters() { setSearch(''); setSubject(''); setGrade(''); setCourse(''); }

  return (
    <div style={{ padding: '20px 24px', display: 'flex', flexDirection: 'column', gap: 16 }}>
      <style>{`
        @keyframes fadeIn  { from{opacity:0} to{opacity:1} }
        @keyframes slideUp { from{opacity:0;transform:translateY(16px)} to{opacity:1;transform:translateY(0)} }
        @keyframes pulse   { 0%,100%{opacity:.6} 50%{opacity:.3} }
      `}</style>

      {/* Toolbar */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12, flexWrap: 'wrap' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
          {['grid', 'list'].map(v => (
            <button key={v} onClick={() => setView(v)} style={{
              padding: '8px 16px', borderRadius: 10, border: 'none', cursor: 'pointer',
              fontFamily: 'Nunito', fontWeight: 700, fontSize: 13,
              background: view === v ? 'var(--primary)' : 'var(--card-bg)',
              color: view === v ? '#fff' : 'var(--text-secondary)',
              boxShadow: view === v ? '0 2px 8px rgba(108,60,225,0.3)' : 'var(--shadow)'
            }}>{v.charAt(0).toUpperCase() + v.slice(1)}</button>
          ))}
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, background: 'var(--card-bg)', border: '1.5px solid var(--border)', borderRadius: 10, padding: '7px 12px' }}>
            <Search size={13} color="var(--text-muted)" />
            <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search modules…"
              style={{ border: 'none', background: 'transparent', outline: 'none', fontSize: 13, fontFamily: 'Nunito', fontWeight: 600, color: 'var(--text-primary)', width: 160 }} />
            {search && <button onClick={() => setSearch('')} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0, display: 'flex' }}><X size={12} color="var(--text-muted)" /></button>}
          </div>
          {[
            { label: 'Subject', value: filterSubject, set: setSubject, options: filters.subjects },
            { label: 'Grade',   value: filterGrade,   set: setGrade,   options: filters.grades   },
            { label: 'Course',  value: filterCourse,  set: setCourse,  options: filters.courses  },
          ].map(({ label, value, set, options }) => (
            <select key={label} value={value} onChange={e => set(e.target.value)} style={{
              padding: '8px 12px', borderRadius: 10, border: `1.5px solid ${value ? 'var(--primary)' : 'var(--border)'}`,
              background: value ? 'rgba(108,60,225,0.08)' : 'var(--card-bg)',
              color: value ? 'var(--primary)' : 'var(--text-secondary)',
              fontFamily: 'Nunito', fontWeight: 700, fontSize: 13, cursor: 'pointer', outline: 'none',
            }}>
              <option value="">{label}</option>
              {options.map(o => <option key={o} value={o}>{o}</option>)}
            </select>
          ))}
          {hasFilters && (
            <button onClick={clearFilters} style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '8px 12px', borderRadius: 10, background: 'rgba(239,68,68,0.08)', border: '1.5px solid rgba(239,68,68,0.2)', color: '#ef4444', fontFamily: 'Nunito', fontWeight: 700, fontSize: 13, cursor: 'pointer' }}>
              <X size={12} /> Clear
            </button>
          )}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          {!loading && <span style={{ fontSize: 13, fontWeight: 700, color: 'var(--text-muted)' }}>{displayed.length} module{displayed.length !== 1 ? 's' : ''}</span>}
          <button onClick={fetchModules} style={{ width: 36, height: 36, borderRadius: 10, background: 'var(--card-bg)', border: '1.5px solid var(--border)', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <RefreshCw size={14} color="var(--text-muted)" />
          </button>
          {/* ← wired up */}
          <button onClick={() => setCreating(true)} style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '10px 20px', borderRadius: 12, background: 'linear-gradient(135deg, var(--primary), var(--primary-light))', color: '#fff', border: 'none', cursor: 'pointer', fontFamily: 'Nunito', fontWeight: 800, fontSize: 14, boxShadow: '0 4px 16px rgba(108,60,225,0.35)' }}>
            <Plus size={16} /> Create Module
          </button>
        </div>
      </div>

      {/* Loading skeletons */}
      {loading && (
        <div style={{ display: 'grid', gridTemplateColumns: view === 'grid' ? 'repeat(3, 1fr)' : '1fr', gap: 16 }}>
          {Array(6).fill(0).map((_, i) => (
            <div key={i} style={{ height: view === 'grid' ? 280 : 72, borderRadius: 16, background: 'var(--card-bg)', border: '1px solid var(--border)', animation: 'pulse 1.5s ease-in-out infinite' }} />
          ))}
        </div>
      )}

      {/* Error */}
      {error && (
        <Card style={{ padding: 32, textAlign: 'center' }}>
          <div style={{ fontSize: 32, marginBottom: 12 }}>⚠️</div>
          <div style={{ fontWeight: 700, color: 'var(--text-primary)', marginBottom: 6 }}>{error}</div>
          <button onClick={fetchModules} style={{ marginTop: 8, padding: '8px 20px', borderRadius: 10, background: 'var(--primary)', color: '#fff', border: 'none', cursor: 'pointer', fontFamily: 'Nunito', fontWeight: 700 }}>Retry</button>
        </Card>
      )}

      {/* Empty */}
      {!loading && !error && displayed.length === 0 && (
        <Card style={{ padding: 48, textAlign: 'center' }}>
          <div style={{ fontSize: 40, marginBottom: 12 }}>📭</div>
          <div style={{ fontWeight: 700, color: 'var(--text-primary)', marginBottom: 4 }}>No modules found</div>
          <div style={{ fontSize: 13, color: 'var(--text-muted)', fontWeight: 600 }}>Try adjusting your filters</div>
          {hasFilters && <button onClick={clearFilters} style={{ marginTop: 12, padding: '8px 20px', borderRadius: 10, background: 'var(--primary)', color: '#fff', border: 'none', cursor: 'pointer', fontFamily: 'Nunito', fontWeight: 700 }}>Clear Filters</button>}
        </Card>
      )}

      {/* Grid View */}
      {!loading && !error && displayed.length > 0 && view === 'grid' && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 20 }}>
          {displayed.map(m => <ModuleCard key={m.id} module={m} onView={() => setViewing(m)} onEdit={() => setEditing(m)} />)}
        </div>
      )}

      {/* List View */}
      {!loading && !error && displayed.length > 0 && view === 'list' && (
        <Card style={{ padding: 0, overflow: 'hidden' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ borderBottom: '1px solid var(--border)' }}>
                {['Module', 'Subject', 'Grade', 'Course', 'Actions'].map(h => (
                  <th key={h} style={{ padding: '12px 16px', textAlign: 'left', fontSize: 11, fontWeight: 800, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: 0.8 }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {displayed.map((m, i) => {
                const color = colorForId(m.id);
                return (
                  <tr key={m.id} style={{ borderBottom: i < displayed.length - 1 ? '1px solid var(--border)' : 'none', transition: 'background 0.15s' }}
                    onMouseEnter={e => e.currentTarget.style.background = 'rgba(108,60,225,0.04)'}
                    onMouseLeave={e => e.currentTarget.style.background = 'transparent'}>
                    <td style={{ padding: '12px 16px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                        <div style={{ width: 36, height: 36, borderRadius: 10, background: `${color}22`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18, flexShrink: 0 }}>
                          {emojiForSubject(m.subject)}
                        </div>
                        <div>
                          <div style={{ fontWeight: 800, fontSize: 14, color: 'var(--text-primary)' }}>{m.title}</div>
                          <div style={{ fontSize: 11, color: 'var(--text-muted)', fontWeight: 600, marginTop: 1 }}>{m.description?.slice(0, 60)}{m.description?.length > 60 ? '…' : ''}</div>
                        </div>
                      </div>
                    </td>
                    <td style={{ padding: '12px 16px', fontSize: 13, fontWeight: 700, color }}>{m.subject}</td>
                    <td style={{ padding: '12px 16px', fontSize: 13, fontWeight: 600, color: 'var(--text-secondary)' }}>{m.grade_level}</td>
                    <td style={{ padding: '12px 16px' }}>
                      <span style={{ fontSize: 11, fontWeight: 800, padding: '3px 8px', borderRadius: 8, background: `${color}18`, color }}>{m.course}</span>
                    </td>
                    <td style={{ padding: '12px 16px' }}>
                      <div style={{ display: 'flex', gap: 6 }}>
                        <button onClick={() => setViewing(m)} style={{ padding: '6px 10px', borderRadius: 8, background: 'var(--bg)', border: 'none', cursor: 'pointer', fontSize: 12, fontWeight: 700, color: 'var(--text-secondary)', fontFamily: 'Nunito', display: 'flex', alignItems: 'center', gap: 4 }}>
                          <Eye size={12} /> View
                        </button>
                        <button onClick={() => setEditing(m)} style={{ padding: '6px 10px', borderRadius: 8, background: `${color}15`, border: 'none', cursor: 'pointer', fontSize: 12, fontWeight: 700, color, fontFamily: 'Nunito', display: 'flex', alignItems: 'center', gap: 4 }}>
                          <Edit2 size={12} /> Edit
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </Card>
      )}

      {/* Modals */}
      {viewing  && <ViewModal   module={viewing}  onClose={() => setViewing(null)}  onEdit={m => setEditing(m)} token={token} />}
      {editing  && <EditModal   module={editing}  onClose={() => setEditing(null)}  onSaved={handleSaved}       token={token} />}
      {creating && <CreateModal                   onClose={() => setCreating(false)} onCreated={handleCreated}   token={token} />}
    </div>
  );
}

// ── Module Card ────────────────────────────────────────────────────────────
function ModuleCard({ module: m, onView, onEdit }) {
  const color = colorForId(m.id);
  const emoji = emojiForSubject(m.subject);
  return (
    <Card style={{ padding: 0, overflow: 'hidden', transition: 'transform 0.2s, box-shadow 0.2s' }}
      onMouseOver={e => { e.currentTarget.style.transform = 'translateY(-3px)'; e.currentTarget.style.boxShadow = '0 12px 32px rgba(0,0,0,0.12)'; }}
      onMouseOut={e => { e.currentTarget.style.transform = ''; e.currentTarget.style.boxShadow = ''; }}>
      <div style={{ height: 90, background: `linear-gradient(135deg, ${color}22, ${color}44)`, display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '16px 20px', borderBottom: `3px solid ${color}33` }}>
        <div style={{ fontSize: 38 }}>{emoji}</div>
        <span style={{ fontSize: 11, fontWeight: 800, padding: '4px 10px', borderRadius: 8, background: 'rgba(16,185,129,0.15)', color: 'var(--accent-green)', border: '1px solid rgba(16,185,129,0.3)' }}>published</span>
      </div>
      <div style={{ padding: 20 }}>
        <div style={{ fontSize: 11, fontWeight: 800, color, textTransform: 'uppercase', letterSpacing: 0.5, marginBottom: 4 }}>{m.subject}</div>
        <div style={{ fontFamily: 'Fredoka One', fontSize: 17, color: 'var(--text-primary)', marginBottom: 4, lineHeight: 1.2 }}>{m.title}</div>
        <div style={{ fontSize: 12, color: 'var(--text-muted)', fontWeight: 600, marginBottom: 8 }}>{m.grade_level} · {m.course}</div>
        <div style={{ fontSize: 12, color: 'var(--text-secondary)', fontWeight: 600, lineHeight: 1.4, marginBottom: 14, minHeight: 36 }}>
          {m.description?.slice(0, 80)}{m.description?.length > 80 ? '…' : ''}
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button onClick={onView} style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 5, padding: '8px', borderRadius: 10, background: 'var(--bg)', border: 'none', cursor: 'pointer', fontSize: 12, fontWeight: 700, color: 'var(--text-secondary)', fontFamily: 'Nunito' }}>
            <Eye size={13} /> View
          </button>
          <button onClick={onEdit} style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 5, padding: '8px', borderRadius: 10, background: `${color}15`, border: 'none', cursor: 'pointer', fontSize: 12, fontWeight: 700, color, fontFamily: 'Nunito' }}>
            <Edit2 size={13} /> Edit
          </button>
        </div>
      </div>
    </Card>
  );
}