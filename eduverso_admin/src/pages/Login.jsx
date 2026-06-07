import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { GraduationCap, LogIn } from "lucide-react";
import { createClient } from "@supabase/supabase-js";

const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
);

export default function Login() {
  const [form, setForm] = useState({ email: "", password: "" });
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleChange = (e) => {
    setForm({ ...form, [e.target.name]: e.target.value });
    setError("");
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError("");

    try {
      const { data, error: authError } = await supabase.auth.signInWithPassword({
        email: form.email,
        password: form.password,
      });

      if (authError) {
        setError("Invalid email or password.");
        return;
      }

      localStorage.setItem("token", data.session.access_token);
      localStorage.setItem("user", JSON.stringify(data.user));
      navigate("/");
    } catch (err) {
      setError("Unable to connect. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={styles.page}>
      <div style={styles.blob1} />
      <div style={styles.blob2} />

      <div style={styles.card}>
        <div style={styles.logoRow}>
          <div style={styles.logoCircle}>
            <GraduationCap size={22} color="#fff" />
          </div>
          <div>
            <div style={styles.logoText}>EduVerso</div>
            <div style={styles.logoSub}>ADMIN PANEL</div>
          </div>
        </div>

        <h1 style={styles.heading}>Welcome back</h1>
        <p style={styles.sub}>Sign in to access your admin dashboard</p>

        <form onSubmit={handleSubmit} style={styles.form}>
          <div style={styles.field}>
            <label style={styles.label}>Email address</label>
            <input
              type="email"
              name="email"
              value={form.email}
              onChange={handleChange}
              placeholder="admin@eduverso.com"
              required
              style={styles.input}
              onFocus={e => e.target.style.borderColor = '#6c3ce1'}
              onBlur={e => e.target.style.borderColor = 'rgba(255,255,255,0.1)'}
            />
          </div>

          <div style={styles.field}>
            <label style={styles.label}>Password</label>
            <input
              type="password"
              name="password"
              value={form.password}
              onChange={handleChange}
              placeholder="••••••••"
              required
              style={styles.input}
              onFocus={e => e.target.style.borderColor = '#6c3ce1'}
              onBlur={e => e.target.style.borderColor = 'rgba(255,255,255,0.1)'}
            />
          </div>

          {error && (
            <div style={styles.error}>
              ⚠ {error}
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            style={{ ...styles.btn, opacity: loading ? 0.7 : 1 }}
            onMouseOver={e => !loading && (e.currentTarget.style.background = 'linear-gradient(135deg, #7c4df0, #ec4899)')}
            onMouseOut={e => e.currentTarget.style.background = 'linear-gradient(135deg, #6c3ce1, #d946a8)'}
          >
            {loading ? "Signing in…" : (
              <span style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
                <LogIn size={16} /> Sign in
              </span>
            )}
          </button>
        </form>

        <p style={styles.footer}>
          Admin access only · Contact your system administrator for access
        </p>
      </div>
    </div>
  );
}

const styles = {
  page: {
    minHeight: "100vh",
    width: "100vw",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    background: "#0f0a1e",
    fontFamily: "'Nunito', sans-serif",
    padding: "1rem",
    position: "relative",
    overflow: "hidden",
  },
  blob1: {
    position: "absolute",
    width: 500,
    height: 500,
    borderRadius: "50%",
    background: "radial-gradient(circle, rgba(108,60,225,0.25) 0%, transparent 70%)",
    top: -100,
    left: -100,
    pointerEvents: "none",
  },
  blob2: {
    position: "absolute",
    width: 400,
    height: 400,
    borderRadius: "50%",
    background: "radial-gradient(circle, rgba(236,72,153,0.15) 0%, transparent 70%)",
    bottom: -80,
    right: -80,
    pointerEvents: "none",
  },
  card: {
    background: "rgba(255,255,255,0.04)",
    borderRadius: "24px",
    border: "1px solid rgba(255,255,255,0.1)",
    padding: "2.5rem 2rem",
    width: "100%",
    maxWidth: "420px",
    backdropFilter: "blur(20px)",
    boxShadow: "0 8px 48px rgba(0,0,0,0.4), 0 0 0 1px rgba(108,60,225,0.2)",
    position: "relative",
    zIndex: 1,
  },
  logoRow: {
    display: "flex",
    alignItems: "center",
    gap: 12,
    marginBottom: "2rem",
  },
  logoCircle: {
    width: 44,
    height: 44,
    borderRadius: 14,
    background: "linear-gradient(135deg, #6c3ce1, #ec4899)",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    boxShadow: "0 4px 16px rgba(108,60,225,0.5)",
  },
  logoText: {
    fontFamily: "'Fredoka One', cursive",
    fontSize: 20,
    color: "#fff",
    lineHeight: 1,
  },
  logoSub: {
    fontSize: 10,
    color: "rgba(255,255,255,0.4)",
    fontWeight: 700,
    letterSpacing: 1.5,
    marginTop: 2,
  },
  heading: {
    margin: "0 0 6px",
    fontSize: "26px",
    fontWeight: 800,
    color: "#fff",
    letterSpacing: "-0.5px",
  },
  sub: {
    margin: "0 0 2rem",
    fontSize: "14px",
    color: "rgba(255,255,255,0.45)",
  },
  form: {
    display: "flex",
    flexDirection: "column",
    gap: "1.1rem",
  },
  field: {
    display: "flex",
    flexDirection: "column",
    gap: "7px",
  },
  label: {
    fontSize: "13px",
    fontWeight: 700,
    color: "rgba(255,255,255,0.6)",
    letterSpacing: "0.3px",
  },
  input: {
    padding: "11px 14px",
    borderRadius: "10px",
    border: "1px solid rgba(255,255,255,0.1)",
    fontSize: "14px",
    fontFamily: "'Nunito', sans-serif",
    color: "#fff",
    outline: "none",
    background: "rgba(255,255,255,0.07)",
    transition: "border-color 0.2s",
  },
  error: {
    padding: "10px 14px",
    background: "rgba(239,68,68,0.15)",
    border: "1px solid rgba(239,68,68,0.3)",
    borderRadius: "10px",
    color: "#fca5a5",
    fontSize: "13px",
    fontWeight: 600,
  },
  btn: {
    marginTop: "4px",
    padding: "12px",
    borderRadius: "10px",
    border: "none",
    background: "linear-gradient(135deg, #6c3ce1, #d946a8)",
    color: "#fff",
    fontSize: "15px",
    fontWeight: 800,
    fontFamily: "'Nunito', sans-serif",
    cursor: "pointer",
    transition: "all 0.2s",
    boxShadow: "0 4px 20px rgba(108,60,225,0.4)",
  },
  footer: {
    marginTop: "1.5rem",
    fontSize: "12px",
    color: "rgba(255,255,255,0.25)",
    textAlign: "center",
    lineHeight: "1.5",
  },
};