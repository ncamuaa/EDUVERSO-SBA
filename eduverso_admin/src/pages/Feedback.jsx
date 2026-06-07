import { useState, useEffect } from 'react';
import { Star, Search, MessageSquare, Trophy, AlertTriangle, User, ChevronLeft, ChevronRight } from 'lucide-react';
import Card from '../components/Card';
import { supabase } from '../lib/supabase';

function Stars({ rating, size = 14 }) {
  return (
    <div style={{ display: 'flex', gap: 2 }}>
      {[1, 2, 3, 4, 5].map(i => (
        <Star key={i} size={size} color={i <= rating ? 'var(--secondary)' : 'var(--border)'} fill={i <= rating ? 'var(--secondary)' : 'none'} />
      ))}
    </div>
  );
}

const PER_PAGE = 4;

export default function Feedback() {
  const [feedbacks, setFeedbacks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all');
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);

  useEffect(() => {
    const fetchFeedback = async () => {
      try {
        const { data, error } = await supabase
          .from('feedback')
          .select('*, users(full_name, course, section)')
          .order('created_at', { ascending: false });

        if (!error) setFeedbacks(data.map(f => ({
          ...f,
          student_name: f.users?.full_name,
          course: f.users?.course,
          section: f.users?.section,
        })));
      } catch (err) {
        console.error('Failed to fetch feedback:', err);
      } finally {
        setLoading(false);
      }
    };
    fetchFeedback();
  }, []);

  useEffect(() => { setPage(1); }, [filter, search]);

  const filtered = feedbacks.filter(f =>
    (filter === 'all' || f.rating === parseInt(filter)) &&
    (f.student_name?.toLowerCase().includes(search.toLowerCase()) ||
     f.body?.toLowerCase().includes(search.toLowerCase()))
  );

  const totalPages = Math.ceil(filtered.length / PER_PAGE);
  const paginated = filtered.slice((page - 1) * PER_PAGE, page * PER_PAGE);

  const avgRating = feedbacks.length
    ? (feedbacks.reduce((a, b) => a + b.rating, 0) / feedbacks.length).toFixed(1)
    : '0.0';

  return (
    <div style={{ padding: 32, display: 'flex', flexDirection: 'column', gap: 24 }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16 }}>
        {[
          { label: 'Total Feedback', value: feedbacks.length, icon: <MessageSquare size={24} color="var(--primary)" />, bg: 'rgba(108,60,225,0.1)', color: 'var(--primary)' },
          { label: 'Avg. Rating', value: avgRating, icon: <Star size={24} color="var(--secondary)" fill="var(--secondary)" />, bg: 'rgba(245,158,11,0.1)', color: 'var(--secondary)' },
          { label: '5-Star Reviews', value: feedbacks.filter(f => f.rating === 5).length, icon: <Trophy size={24} color="var(--accent-green)" />, bg: 'rgba(16,185,129,0.1)', color: 'var(--accent-green)' },
          { label: 'Need Attention', value: feedbacks.filter(f => f.rating <= 3).length, icon: <AlertTriangle size={24} color="var(--danger)" />, bg: 'rgba(239,68,68,0.1)', color: 'var(--danger)' },
        ].map(({ label, value, icon, bg, color }) => (
          <Card key={label} style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <div style={{ width: 48, height: 48, borderRadius: 12, background: bg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              {icon}
            </div>
            <div>
              <div style={{ fontFamily: 'Fredoka One', fontSize: 24, color, lineHeight: 1 }}>{value}</div>
              <div style={{ fontSize: 12, color: 'var(--text-secondary)', fontWeight: 600 }}>{label}</div>
            </div>
          </Card>
        ))}
      </div>

      <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, background: 'var(--card-bg)', borderRadius: 12, padding: '9px 14px', border: '1.5px solid var(--border)', flex: 1, maxWidth: 260 }}>
          <Search size={14} color="var(--text-muted)" />
          <input
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Search feedback..."
            style={{ border: 'none', background: 'transparent', outline: 'none', fontSize: 13, fontFamily: 'Nunito', fontWeight: 600 }}
          />
        </div>
        {[
          { val: 'all', label: 'All' },
          { val: '5', label: '5 Stars' },
          { val: '4', label: '4 Stars' },
          { val: '3', label: '3 & below' },
        ].map(({ val, label }) => (
          <button key={val} onClick={() => setFilter(val)} style={{
            padding: '9px 18px', borderRadius: 10, border: 'none', cursor: 'pointer',
            fontFamily: 'Nunito', fontWeight: 700, fontSize: 13, transition: 'all 0.15s',
            background: filter === val ? 'var(--primary)' : 'var(--card-bg)',
            color: filter === val ? '#fff' : 'var(--text-secondary)',
            boxShadow: filter === val ? '0 4px 12px rgba(108,60,225,0.3)' : 'var(--shadow)'
          }}>{label}</button>
        ))}
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: 40, color: 'var(--text-muted)', fontWeight: 600 }}>Loading feedback…</div>
      ) : filtered.length === 0 ? (
        <div style={{ textAlign: 'center', padding: 40, color: 'var(--text-muted)', fontWeight: 600 }}>No feedback found.</div>
      ) : (
        <>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
            {paginated.map(f => (
              <Card key={f.id} style={{ borderTop: `3px solid ${f.rating === 5 ? 'var(--accent-green)' : f.rating <= 3 ? 'var(--danger)' : 'var(--primary)'}` }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 12 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <div style={{ width: 38, height: 38, borderRadius: 10, background: 'rgba(108,60,225,0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <User size={18} color="var(--primary)" />
                    </div>
                    <div>
                      <div style={{ fontWeight: 800, fontSize: 14 }}>{f.student_name || 'Anonymous'}</div>
                      <div style={{ fontSize: 12, color: 'var(--text-muted)', fontWeight: 600 }}>
                        {f.course || f.section || 'Student'}
                      </div>
                    </div>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <Stars rating={f.rating} />
                    <div style={{ fontSize: 11, color: 'var(--text-muted)', fontWeight: 600, marginTop: 4 }}>
                      {new Date(f.created_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                    </div>
                  </div>
                </div>
                <p style={{ fontSize: 13, color: 'var(--text-secondary)', lineHeight: 1.7, fontWeight: 600 }}>
                  "{f.body}"
                </p>
              </Card>
            ))}
          </div>

          {totalPages > 1 && (
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
              <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1}
                style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', width: 36, height: 36, borderRadius: 10, border: '1.5px solid var(--border)', background: 'var(--card-bg)', cursor: page === 1 ? 'not-allowed' : 'pointer', opacity: page === 1 ? 0.4 : 1 }}>
                <ChevronLeft size={16} color="var(--text-secondary)" />
              </button>
              {Array.from({ length: totalPages }, (_, i) => i + 1).map(n => (
                <button key={n} onClick={() => setPage(n)} style={{
                  width: 36, height: 36, borderRadius: 10, border: '1.5px solid',
                  borderColor: page === n ? 'var(--primary)' : 'var(--border)',
                  background: page === n ? 'var(--primary)' : 'var(--card-bg)',
                  color: page === n ? '#fff' : 'var(--text-secondary)',
                  fontFamily: 'Nunito', fontWeight: 700, fontSize: 13, cursor: 'pointer'
                }}>{n}</button>
              ))}
              <button onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page === totalPages}
                style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', width: 36, height: 36, borderRadius: 10, border: '1.5px solid var(--border)', background: 'var(--card-bg)', cursor: page === totalPages ? 'not-allowed' : 'pointer', opacity: page === totalPages ? 0.4 : 1 }}>
                <ChevronRight size={16} color="var(--text-secondary)" />
              </button>
              <span style={{ fontSize: 13, color: 'var(--text-muted)', fontWeight: 600, marginLeft: 8 }}>
                Page {page} of {totalPages} · {filtered.length} total
              </span>
            </div>
          )}
        </>
      )}
    </div>
  );
}