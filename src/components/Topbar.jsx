import { useState, useEffect, useRef } from 'react';
import { Bell, Search, ChevronDown, Settings, LogOut, User, X } from 'lucide-react';
import { useLocation, useNavigate } from 'react-router-dom';

const titles = {
  '/': 'Dashboard',
  '/students': 'Students',
  '/modules': 'Modules',
  '/games': 'Games',
  '/stats': 'Stats & Analytics',
  '/announcements': 'Announcements',
  '/feedback': 'Feedback',
  '/settings': 'Settings',
};

// Static mock notifications — swap for a real API call if you have one
const MOCK_NOTIFICATIONS = [
  { id: 1, type: 'badge',    icon: '🏆', title: 'New badge earned',        body: 'Juan dela Cruz earned the Gold Star badge',  time: '2 min ago',  unread: true  },
  { id: 2, type: 'student',  icon: '👤', title: 'New student joined',       body: 'Maria Santos enrolled in Module 3',          time: '18 min ago', unread: true  },
  { id: 3, type: 'game',     icon: '🎮', title: 'Game milestone reached',   body: '36 total games played today',                time: '1 hr ago',   unread: true  },
  { id: 4, type: 'module',   icon: '📚', title: 'Module completed',         body: 'Module 2: Algebra finished by 4 students',   time: '3 hrs ago',  unread: false },
  { id: 5, type: 'feedback', icon: '💬', title: 'New feedback received',    body: 'A student left a comment on Module 1',       time: 'Yesterday',  unread: false },
];

export default function Topbar() {
  const { pathname } = useLocation();
  const navigate = useNavigate();
  const title = titles[pathname] || 'EduVerso';

  // ── Search state ──────────────────────────────────────────────
  const [query, setQuery]             = useState('');
  const [searchResults, setResults]   = useState([]);
  const [searchOpen, setSearchOpen]   = useState(false);
  const [searchLoading, setSearchLoading] = useState(false);
  const searchRef = useRef(null);

  // ── Notification state ────────────────────────────────────────
  const [notifOpen, setNotifOpen]     = useState(false);
  const [notifications, setNotifications] = useState(MOCK_NOTIFICATIONS);
  const unreadCount = notifications.filter(n => n.unread).length;
  const notifRef = useRef(null);

  // ── Admin dropdown state ──────────────────────────────────────
  const [adminOpen, setAdminOpen]     = useState(false);
  const adminRef = useRef(null);

  // ── Close dropdowns on outside click ─────────────────────────
  useEffect(() => {
    function handleClick(e) {
      if (searchRef.current && !searchRef.current.contains(e.target)) setSearchOpen(false);
      if (notifRef.current  && !notifRef.current.contains(e.target))  setNotifOpen(false);
      if (adminRef.current  && !adminRef.current.contains(e.target))  setAdminOpen(false);
    }
    document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, []);

  // ── Live search (debounced, calls your backend) ───────────────
  useEffect(() => {
    if (!query.trim()) { setResults([]); setSearchOpen(false); return; }
    setSearchLoading(true);
    setSearchOpen(true);
    const timer = setTimeout(async () => {
      const token = localStorage.getItem('token');
      try {
        const res = await fetch(
          `${import.meta.env.VITE_API_URL}/api/search?q=${encodeURIComponent(query.trim())}`,
          { headers: { Authorization: `Bearer ${token}` } }
        );
        const data = await res.json();
        if (data.success) setResults(data.results);
        else              setResults([]);
      } catch {
        // Fallback: local static results so the UI still responds gracefully
        setResults([]);
      } finally {
        setSearchLoading(false);
      }
    }, 280);
    return () => clearTimeout(timer);
  }, [query]);

  function handleSearchSelect(result) {
    setQuery('');
    setSearchOpen(false);
    if (result.type === 'student') navigate('/students');
    if (result.type === 'module')  navigate('/modules');
    if (result.type === 'game')    navigate('/games');
  }

  function markAllRead() {
    setNotifications(prev => prev.map(n => ({ ...n, unread: false })));
  }

  function dismissNotif(id) {
    setNotifications(prev => prev.filter(n => n.id !== id));
  }

  function handleLogout() {
    localStorage.removeItem('token');
    navigate('/login');
  }

  const dropdownBase = {
    position: 'absolute', top: 'calc(100% + 10px)', right: 0,
    background: 'var(--card-bg)', border: '1.5px solid var(--border)',
    borderRadius: 16, boxShadow: '0 12px 40px rgba(108,60,225,0.18)',
    zIndex: 999, animation: 'fadeSlideDown 0.18s ease',
  };

  return (
    <>
      <style>{`
        @keyframes fadeSlideDown {
          from { opacity: 0; transform: translateY(-6px); }
          to   { opacity: 1; transform: translateY(0); }
        }
        .topbar-notif-item:hover  { background: rgba(108,60,225,0.06) !important; }
        .topbar-admin-item:hover  { background: rgba(108,60,225,0.08) !important; }
        .topbar-search-item:hover { background: rgba(108,60,225,0.07) !important; }
        .topbar-notif-dismiss:hover { opacity: 1 !important; }
      `}</style>

      <header style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '14px 24px', background: 'var(--card-bg)',
        borderBottom: '1px solid var(--border)', position: 'sticky', top: 0, zIndex: 100,
        width: '100%', boxSizing: 'border-box',
        boxShadow: '0 2px 12px rgba(108,60,225,0.06)'
      }}>
        {/* Title */}
        <div>
          <h1 style={{ fontFamily: 'Fredoka One', fontSize: 22, color: 'var(--text-primary)', lineHeight: 1 }}>{title}</h1>
          <p style={{ fontSize: 12, color: 'var(--text-secondary)', fontWeight: 600, marginTop: 2 }}>
            {new Date().toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}
          </p>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>

          {/* ── Search ─────────────────────────────────────────── */}
          <div ref={searchRef} style={{ position: 'relative' }}>
            <div style={{
              display: 'flex', alignItems: 'center', gap: 8,
              background: 'var(--bg)', borderRadius: 12, padding: '9px 16px',
              border: `1.5px solid ${searchOpen ? 'var(--primary)' : 'var(--border)'}`,
              transition: 'border-color 0.2s',
            }}>
              <Search size={15} color="var(--text-muted)" />
              <input
                placeholder="Search students, modules…"
                value={query}
                onChange={e => setQuery(e.target.value)}
                onFocus={() => query && setSearchOpen(true)}
                style={{
                  border: 'none', background: 'transparent', outline: 'none',
                  fontSize: 13, fontFamily: 'Nunito', color: 'var(--text-primary)',
                  width: 190, fontWeight: 600
                }}
              />
              {query && (
                <button onClick={() => { setQuery(''); setSearchOpen(false); }}
                  style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0, display: 'flex', alignItems: 'center' }}>
                  <X size={13} color="var(--text-muted)" />
                </button>
              )}
            </div>

            {searchOpen && (
              <div style={{ ...dropdownBase, width: 320, maxHeight: 360, overflowY: 'auto' }}>
                {searchLoading ? (
                  <div style={{ padding: '20px 16px', textAlign: 'center', color: 'var(--text-muted)', fontSize: 13, fontWeight: 600 }}>
                    Searching…
                  </div>
                ) : searchResults.length === 0 ? (
                  <div style={{ padding: '20px 16px', textAlign: 'center', color: 'var(--text-muted)', fontSize: 13, fontWeight: 600 }}>
                    No results for <strong>"{query}"</strong>
                  </div>
                ) : (
                  <>
                    {['student', 'module', 'game'].map(type => {
                      const group = searchResults.filter(r => r.type === type);
                      if (!group.length) return null;
                      const label = type === 'student' ? '👤 Students' : type === 'module' ? '📚 Modules' : '🎮 Games';
                      return (
                        <div key={type}>
                          <div style={{ padding: '8px 16px 4px', fontSize: 11, fontWeight: 800, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: 0.8 }}>
                            {label}
                          </div>
                          {group.map(r => (
                            <div key={r.id} className="topbar-search-item"
                              onClick={() => handleSearchSelect(r)}
                              style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '9px 16px', cursor: 'pointer', borderRadius: 0, transition: 'background 0.15s' }}>
                              <div style={{
                                width: 32, height: 32, borderRadius: 8, flexShrink: 0,
                                background: type === 'student' ? 'rgba(108,60,225,0.1)' : type === 'module' ? 'rgba(16,185,129,0.1)' : 'rgba(236,72,153,0.1)',
                                display: 'flex', alignItems: 'center', justifyContent: 'center',
                                fontSize: 15
                              }}>
                                {type === 'student' ? '👤' : type === 'module' ? '📚' : '🎮'}
                              </div>
                              <div>
                                <div style={{ fontWeight: 700, fontSize: 13, color: 'var(--text-primary)' }}>{r.name}</div>
                                {r.subtitle && <div style={{ fontSize: 11, color: 'var(--text-muted)', fontWeight: 600 }}>{r.subtitle}</div>}
                              </div>
                            </div>
                          ))}
                        </div>
                      );
                    })}
                  </>
                )}
              </div>
            )}
          </div>

          {/* ── Notification Bell ──────────────────────────────── */}
          <div ref={notifRef} style={{ position: 'relative' }}>
            <button
              onClick={() => { setNotifOpen(p => !p); setAdminOpen(false); }}
              style={{
                position: 'relative', width: 40, height: 40, borderRadius: 12,
                background: notifOpen ? 'rgba(108,60,225,0.1)' : 'var(--bg)',
                border: `1.5px solid ${notifOpen ? 'var(--primary)' : 'var(--border)'}`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                cursor: 'pointer', transition: 'all 0.2s',
              }}>
              <Bell size={17} color={notifOpen ? 'var(--primary)' : 'var(--text-secondary)'} />
              {unreadCount > 0 && (
                <span style={{
                  position: 'absolute', top: 6, right: 6, width: 8, height: 8,
                  borderRadius: '50%', background: 'var(--accent-pink)',
                  border: '2px solid white'
                }} />
              )}
            </button>

            {notifOpen && (
              <div style={{ ...dropdownBase, width: 340, right: -10 }}>
                {/* Header */}
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '14px 16px 10px', borderBottom: '1px solid var(--border)' }}>
                  <div style={{ fontFamily: 'Fredoka One', fontSize: 15, color: 'var(--text-primary)' }}>
                    Notifications {unreadCount > 0 && (
                      <span style={{ marginLeft: 6, fontSize: 11, fontWeight: 800, background: 'var(--primary)', color: '#fff', padding: '2px 7px', borderRadius: 20 }}>
                        {unreadCount}
                      </span>
                    )}
                  </div>
                  {unreadCount > 0 && (
                    <button onClick={markAllRead} style={{ fontSize: 11, fontWeight: 700, color: 'var(--primary)', background: 'none', border: 'none', cursor: 'pointer' }}>
                      Mark all read
                    </button>
                  )}
                </div>

                {/* Items */}
                <div style={{ maxHeight: 300, overflowY: 'auto' }}>
                  {notifications.length === 0 ? (
                    <div style={{ padding: '24px 16px', textAlign: 'center', color: 'var(--text-muted)', fontSize: 13, fontWeight: 600 }}>
                      You're all caught up! 🎉
                    </div>
                  ) : notifications.map(n => (
                    <div key={n.id} className="topbar-notif-item"
                      style={{
                        display: 'flex', alignItems: 'flex-start', gap: 10, padding: '10px 14px',
                        background: n.unread ? 'rgba(108,60,225,0.04)' : 'transparent',
                        transition: 'background 0.15s', position: 'relative', cursor: 'default',
                        borderLeft: n.unread ? '3px solid var(--primary)' : '3px solid transparent',
                      }}>
                      <div style={{
                        width: 34, height: 34, borderRadius: 10, flexShrink: 0,
                        background: 'rgba(108,60,225,0.08)',
                        display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 16
                      }}>{n.icon}</div>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ fontWeight: 800, fontSize: 13, color: 'var(--text-primary)', lineHeight: 1.2 }}>{n.title}</div>
                        <div style={{ fontSize: 12, color: 'var(--text-secondary)', fontWeight: 600, marginTop: 2, lineHeight: 1.4 }}>{n.body}</div>
                        <div style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 4, fontWeight: 700 }}>{n.time}</div>
                      </div>
                      <button className="topbar-notif-dismiss"
                        onClick={() => dismissNotif(n.id)}
                        style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 2, opacity: 0.4, transition: 'opacity 0.15s', flexShrink: 0 }}>
                        <X size={12} color="var(--text-muted)" />
                      </button>
                    </div>
                  ))}
                </div>

                {/* Footer */}
                <div style={{ borderTop: '1px solid var(--border)', padding: '10px 16px' }}>
                  <button
                    onClick={() => { navigate('/announcements'); setNotifOpen(false); }}
                    style={{ width: '100%', padding: '8px', borderRadius: 10, background: 'rgba(108,60,225,0.08)', border: 'none', cursor: 'pointer', fontSize: 13, fontWeight: 700, color: 'var(--primary)' }}>
                    View All Announcements
                  </button>
                </div>
              </div>
            )}
          </div>

          {/* ── Admin Avatar Dropdown ──────────────────────────── */}
          <div ref={adminRef} style={{ position: 'relative' }}>
            <div
              onClick={() => { setAdminOpen(p => !p); setNotifOpen(false); }}
              style={{ display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer',
                padding: '6px 10px', borderRadius: 12, transition: 'background 0.15s',
                background: adminOpen ? 'rgba(108,60,225,0.08)' : 'transparent',
              }}>
              <div style={{
                width: 38, height: 38, borderRadius: 12,
                background: 'linear-gradient(135deg, var(--primary), var(--accent-pink))',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontFamily: 'Fredoka One', fontSize: 16, color: '#fff', flexShrink: 0,
              }}>A</div>
              <div>
                <div style={{ fontSize: 13, fontWeight: 800, color: 'var(--text-primary)', lineHeight: 1.2 }}>Admin</div>
                <div style={{ fontSize: 11, color: 'var(--text-muted)', fontWeight: 600 }}>Super Admin</div>
              </div>
              <ChevronDown size={14} color="var(--text-muted)"
                style={{ transform: adminOpen ? 'rotate(180deg)' : 'rotate(0)', transition: 'transform 0.2s' }} />
            </div>

            {adminOpen && (
              <div style={{ ...dropdownBase, width: 210, right: 0 }}>
                {/* Profile info header */}
                <div style={{ padding: '14px 16px 10px', borderBottom: '1px solid var(--border)', display: 'flex', alignItems: 'center', gap: 10 }}>
                  <div style={{
                    width: 42, height: 42, borderRadius: 12,
                    background: 'linear-gradient(135deg, var(--primary), var(--accent-pink))',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontFamily: 'Fredoka One', fontSize: 18, color: '#fff', flexShrink: 0,
                  }}>A</div>
                  <div>
                    <div style={{ fontWeight: 800, fontSize: 14, color: 'var(--text-primary)' }}>Admin</div>
                    <div style={{ fontSize: 11, color: 'var(--text-muted)', fontWeight: 600 }}>Super Admin</div>
                  </div>
                </div>

                {/* Menu items */}
                {[
                  { icon: User,     label: 'My Profile',  action: () => { navigate('/settings'); setAdminOpen(false); } },
                  { icon: Settings, label: 'Settings',    action: () => { navigate('/settings'); setAdminOpen(false); } },
                ].map(({ icon: Icon, label, action }) => (
                  <button key={label} className="topbar-admin-item"
                    onClick={action}
                    style={{
                      width: '100%', display: 'flex', alignItems: 'center', gap: 10,
                      padding: '11px 16px', background: 'none', border: 'none', cursor: 'pointer',
                      fontSize: 13, fontWeight: 700, color: 'var(--text-primary)', textAlign: 'left',
                      transition: 'background 0.15s', borderRadius: 0,
                    }}>
                    <Icon size={15} color="var(--text-secondary)" />
                    {label}
                  </button>
                ))}

                <div style={{ borderTop: '1px solid var(--border)', margin: '4px 0' }} />

                <button className="topbar-admin-item"
                  onClick={handleLogout}
                  style={{
                    width: '100%', display: 'flex', alignItems: 'center', gap: 10,
                    padding: '11px 16px', background: 'none', border: 'none', cursor: 'pointer',
                    fontSize: 13, fontWeight: 700, color: '#ef4444', textAlign: 'left',
                    transition: 'background 0.15s', borderRadius: '0 0 14px 14px',
                  }}>
                  <LogOut size={15} color="#ef4444" />
                  Log Out
                </button>
              </div>
            )}
          </div>
        </div>
      </header>
    </>
  );
}