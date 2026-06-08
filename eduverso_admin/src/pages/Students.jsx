import { useState, useEffect } from 'react';
import { Search, Plus, MoreHorizontal, Users, Wifi, Star, Zap, ChevronLeft, ChevronRight } from 'lucide-react';
import Card from '../components/Card';
import { supabase } from '../lib/supabase';

function Avatar({ student, index }) {
  const colors = [
    '#6C3CE1', '#3B82F6', '#10B981', '#F97316',
    '#EC4899', '#8B5CF6', '#06B6D4', '#84CC16'
  ];
  const bg = colors[index % colors.length];
  const initials = student.full_name
    ? student.full_name.split(' ').map(n => n[0]).join('').slice(0, 2).toUpperCase()
    : '?';

  const imgSrc = student.profileImage
    ? student.profileImage.startsWith('data:')
      ? student.profileImage
      : `data:image/jpeg;base64,${student.profileImage}`
    : null;

  if (imgSrc) {
    return (
      <img
        src={imgSrc}
        alt={student.full_name}
        style={{
          width: 38, height: 38, borderRadius: 10,
          objectFit: 'cover', flexShrink: 0, display: 'block',
        }}
      />
    );
  }

  return (
    <div style={{
      width: 38, height: 38, borderRadius: 10, background: bg, flexShrink: 0,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      color: '#fff', fontWeight: 800, fontSize: 13, fontFamily: 'Nunito',
    }}>
      {initials}
    </div>
  );
}

const PAGE_SIZE = 10;

export default function Students() {
  const [students, setStudents] = useState([]);
  const [stats, setStats] = useState({ total: 0, onlineNow: 0, avgXp: 0 });
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState('all');
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const { data, error } = await supabase
          .from('users')
          .select('*')
          .neq('role', 'admin');

        if (error) throw error;

        const students = data || [];
        const onlineNow = students.filter(s => s.is_online === true).length;
        const avgXp = students.length
          ? Math.round(students.reduce((a, b) => a + (b.xp || 0), 0) / students.length * 10) / 10
          : 0;

        setStudents(students);
        setStats({ total: students.length, onlineNow, avgXp });
      } catch (err) {
        console.error('Failed to fetch students:', err);
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, []);

  // Reset to page 1 whenever search or filter changes
  useEffect(() => {
    setPage(1);
  }, [search, filter]);

  const filtered = students.filter(s => {
    const matchSearch = s.full_name?.toLowerCase().includes(search.toLowerCase()) ||
                        s.email?.toLowerCase().includes(search.toLowerCase());
    const isActive = s.is_online === true;
    if (filter === 'active') return matchSearch && isActive;
    if (filter === 'inactive') return matchSearch && !isActive;
    return matchSearch;
  });

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const paginated = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);

  const statCards = [
    { label: 'Total Enrolled', value: loading ? '…' : stats.total.toLocaleString(), icon: Users,  color: 'var(--primary)',      bg: 'rgba(108,60,225,0.1)'  },
    { label: 'Online Now',     value: loading ? '…' : stats.onlineNow.toLocaleString(), icon: Wifi, color: 'var(--accent-green)', bg: 'rgba(16,185,129,0.1)'  },
    { label: 'Avg. XP',        value: loading ? '…' : stats.avgXp, icon: Star,  color: 'var(--secondary)',    bg: 'rgba(245,158,11,0.1)'  },
  ];

  return (
    <div style={{ padding: 32, display: 'flex', flexDirection: 'column', gap: 24 }}>

      {/* Stat Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16 }}>
        {statCards.map(({ label, value, icon: Icon, color, bg }) => (
          <Card key={label} style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
            <div style={{ width: 48, height: 48, borderRadius: 12, background: bg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              <Icon size={22} color={color} />
            </div>
            <div>
              <div style={{ fontFamily: 'Fredoka One', fontSize: 26, color, lineHeight: 1 }}>{value}</div>
              <div style={{ fontSize: 13, color: 'var(--text-secondary)', fontWeight: 600 }}>{label}</div>
            </div>
          </Card>
        ))}
      </div>

      {/* Table */}
      <Card style={{ padding: 0, overflow: 'hidden' }}>
        <div style={{ padding: '20px 24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', borderBottom: '1px solid var(--border)' }}>
          <div style={{ fontFamily: 'Fredoka One', fontSize: 18 }}>All Students</div>
          <div style={{ display: 'flex', gap: 10 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, background: 'var(--bg)', borderRadius: 10, padding: '8px 14px', border: '1.5px solid var(--border)' }}>
              <Search size={14} color="var(--text-muted)" />
              <input
                value={search}
                onChange={e => setSearch(e.target.value)}
                placeholder="Search students..."
                style={{ border: 'none', background: 'transparent', outline: 'none', fontSize: 13, fontFamily: 'Nunito', fontWeight: 600, width: 150 }}
              />
            </div>
            {['all', 'active', 'inactive'].map(f => (
              <button key={f} onClick={() => setFilter(f)} style={{
                padding: '8px 16px', borderRadius: 10, border: 'none', cursor: 'pointer',
                fontFamily: 'Nunito', fontWeight: 700, fontSize: 13,
                background: filter === f ? 'var(--primary)' : 'var(--bg)',
                color: filter === f ? '#fff' : 'var(--text-secondary)',
                transition: 'all 0.15s'
              }}>{f.charAt(0).toUpperCase() + f.slice(1)}</button>
            ))}
            <button style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '8px 16px', borderRadius: 10, background: 'var(--primary)', color: '#fff', border: 'none', cursor: 'pointer', fontFamily: 'Nunito', fontWeight: 700, fontSize: 13 }}>
              <Plus size={14} /> Add Student
            </button>
          </div>
        </div>

        {loading ? (
          <div style={{ padding: 40, textAlign: 'center', color: 'var(--text-muted)', fontWeight: 600 }}>Loading students…</div>
        ) : filtered.length === 0 ? (
          <div style={{ padding: 40, textAlign: 'center', color: 'var(--text-muted)', fontWeight: 600 }}>No students found.</div>
        ) : (
          <>
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr style={{ background: 'var(--bg)' }}>
                  {['Student', 'Grade', 'XP', 'Streak', 'Status', ''].map(h => (
                    <th key={h} style={{ padding: '12px 24px', textAlign: 'left', fontSize: 12, fontWeight: 800, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: 0.5 }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {paginated.map((s, i) => {
                  const isActive = s.is_online === true;
                  return (
                    <tr key={s.id} style={{ borderTop: '1px solid var(--border)', transition: 'background 0.12s' }}
                      onMouseOver={e => e.currentTarget.style.background = 'rgba(108,60,225,0.03)'}
                      onMouseOut={e => e.currentTarget.style.background = 'transparent'}
                    >
                      <td style={{ padding: '14px 24px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                          <Avatar student={s} index={(page - 1) * PAGE_SIZE + i} />
                          <div>
                            <div style={{ fontWeight: 800, fontSize: 14 }}>{s.full_name || 'Unknown'}</div>
                            <div style={{ fontSize: 12, color: 'var(--text-muted)', fontWeight: 600 }}>{s.email}</div>
                          </div>
                        </div>
                      </td>
                      <td style={{ padding: '14px 24px', fontSize: 13, fontWeight: 700 }}>{s.grade_level || s.course || '—'}</td>
                      <td style={{ padding: '14px 24px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                          <div style={{ flex: 1, height: 6, background: 'var(--border)', borderRadius: 99, maxWidth: 60 }}>
                            <div style={{ width: `${Math.min(s.xp || 0, 100)}%`, height: '100%', borderRadius: 99, background: (s.xp || 0) >= 80 ? 'var(--accent-green)' : 'var(--primary)' }} />
                          </div>
                          <span style={{ fontSize: 13, fontWeight: 800 }}>{s.xp || 0}</span>
                        </div>
                      </td>
                      <td style={{ padding: '14px 24px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                          <Zap size={13} color="#F97316" />
                          <span style={{ fontSize: 13, fontWeight: 700 }}>{s.streak || 0} days</span>
                        </div>
                      </td>
                      <td style={{ padding: '14px 24px' }}>
                        <span style={{
                          fontSize: 12, fontWeight: 800, padding: '4px 10px', borderRadius: 8,
                          background: isActive ? 'rgba(16,185,129,0.1)' : 'rgba(156,163,175,0.15)',
                          color: isActive ? 'var(--accent-green)' : 'var(--text-muted)'
                        }}>{isActive ? 'active' : 'inactive'}</span>
                      </td>
                      <td style={{ padding: '14px 24px' }}>
                        <button style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-muted)' }}>
                          <MoreHorizontal size={18} />
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>

            {/* Pagination Footer */}
            <div style={{
              padding: '14px 24px',
              borderTop: '1px solid var(--border)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
            }}>
              <span style={{ fontSize: 13, color: 'var(--text-muted)', fontWeight: 600 }}>
                Showing {((page - 1) * PAGE_SIZE) + 1}–{Math.min(page * PAGE_SIZE, filtered.length)} of {filtered.length} students
              </span>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <button
                  onClick={() => setPage(p => Math.max(1, p - 1))}
                  disabled={page === 1}
                  style={{
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    width: 32, height: 32, borderRadius: 8, border: '1.5px solid var(--border)',
                    background: 'var(--bg)', cursor: page === 1 ? 'not-allowed' : 'pointer',
                    color: page === 1 ? 'var(--text-muted)' : 'var(--text-secondary)',
                    opacity: page === 1 ? 0.5 : 1, transition: 'all 0.15s',
                  }}
                >
                  <ChevronLeft size={15} />
                </button>

                {Array.from({ length: totalPages }, (_, i) => i + 1)
                  .filter(p => p === 1 || p === totalPages || Math.abs(p - page) <= 1)
                  .reduce((acc, p, idx, arr) => {
                    if (idx > 0 && p - arr[idx - 1] > 1) acc.push('…');
                    acc.push(p);
                    return acc;
                  }, [])
                  .map((p, idx) =>
                    p === '…' ? (
                      <span key={`ellipsis-${idx}`} style={{ fontSize: 13, color: 'var(--text-muted)', padding: '0 4px' }}>…</span>
                    ) : (
                      <button
                        key={p}
                        onClick={() => setPage(p)}
                        style={{
                          width: 32, height: 32, borderRadius: 8, border: '1.5px solid',
                          borderColor: page === p ? 'var(--primary)' : 'var(--border)',
                          background: page === p ? 'var(--primary)' : 'var(--bg)',
                          color: page === p ? '#fff' : 'var(--text-secondary)',
                          fontFamily: 'Nunito', fontWeight: 700, fontSize: 13,
                          cursor: 'pointer', transition: 'all 0.15s',
                        }}
                      >{p}</button>
                    )
                  )
                }

                <button
                  onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                  disabled={page === totalPages}
                  style={{
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    width: 32, height: 32, borderRadius: 8, border: '1.5px solid var(--border)',
                    background: 'var(--bg)', cursor: page === totalPages ? 'not-allowed' : 'pointer',
                    color: page === totalPages ? 'var(--text-muted)' : 'var(--text-secondary)',
                    opacity: page === totalPages ? 0.5 : 1, transition: 'all 0.15s',
                  }}
                >
                  <ChevronRight size={15} />
                </button>
              </div>
            </div>
          </>
        )}
      </Card>
    </div>
  );
}