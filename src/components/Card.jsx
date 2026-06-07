export default function Card({ children, style = {}, className = '' }) {
  return (
    <div className={className} style={{
      background: 'var(--card-bg)',
      borderRadius: 'var(--radius)',
      padding: 24,
      boxShadow: 'var(--shadow)',
      border: '1px solid rgba(108,60,225,0.07)',
      ...style
    }}>
      {children}
    </div>
  );
}
