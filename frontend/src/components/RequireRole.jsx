import { useAuth } from "../lib/AuthContext";
import { Link } from "react-router-dom";

function AccessPage({ icon, title, subtitle, action }) {
  return (
    <div className="rr-shell">
      <div className="rr-card">
        <div className="rr-icon">{icon}</div>
        <h1 className="rr-title">{title}</h1>
        <p className="rr-subtitle">{subtitle}</p>
        {action}
      </div>
    </div>
  );
}

export default function RequireRole({ roles, children }) {
  const { session, profile, loading } = useAuth();

  if (loading) return (
    <div className="rr-shell">
      <div className="rr-loader">
        <div className="rr-spinner" />
        <p className="rr-loader-text">Loading…</p>
      </div>
    </div>
  );

  if (!session) return (
    <AccessPage
      icon={
        <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
          <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
          <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
        </svg>
      }
      title="Sign in required"
      subtitle="This page is only available to signed-in users. Please sign in to continue."
      action={
        <Link to="/login" className="rr-btn rr-btn-primary">Sign in to CodeGoLive</Link>
      }
    />
  );

  if (!profile || !roles.includes(profile.role)) return (
    <AccessPage
      icon={
        <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
          <circle cx="12" cy="12" r="10"/>
          <line x1="4.93" y1="4.93" x2="19.07" y2="19.07"/>
        </svg>
      }
      title="Access denied"
      subtitle="You don't have permission to view this page. This area is restricted to administrators."
      action={
        <Link to="/" className="rr-btn rr-btn-secondary">Back to Dashboard</Link>
      }
    />
  );

  return children;
}
