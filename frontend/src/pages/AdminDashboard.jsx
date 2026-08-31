import { useEffect, useState } from "react";
import AdminShell from "../components/AdminShell";
import { api } from "../lib/api";
import { Link } from "react-router-dom";
import SEO from "../components/SEO";

function StatCard({ label, value, sub, color, to }) {
  const inner = (
    <div className="admin-stat-card" style={{ "--stat-color": color }}>
      <div className="admin-stat-value">{value ?? "—"}</div>
      <div className="admin-stat-label">{label}</div>
      {sub && <div className="admin-stat-sub">{sub}</div>}
    </div>
  );
  return to ? <Link to={to} className="admin-stat-link">{inner}</Link> : inner;
}

export default function AdminDashboard() {
  const [stats, setStats] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    api.get("/api/admin/stats")
      .then(setStats)
      .catch((e) => setError(e.message));
  }, []);

  const QUICK_LINKS = [
    { label: "Add Course", to: "/admin/courses?action=new", icon: "+" },
    { label: "Add Topic", to: "/admin/topics?action=new", icon: "+" },
    { label: "Review Queue", to: "/admin/moderation", icon: "🛡️" },
    { label: "Manage Users", to: "/admin/users", icon: "👥" },
  ];

  return (
    <AdminShell breadcrumbs={[{ label: "Admin" }, { label: "Dashboard" }]}>
      <SEO title="Admin Dashboard" robots="noindex, nofollow" />
      <div className="admin-page">
        <div className="admin-page-header">
          <h1 className="admin-page-title">Dashboard</h1>
          <p className="admin-page-desc">Platform overview</p>
        </div>

        {error && (
          <div className="admin-alert admin-alert--error">
            Failed to load stats: {error}
          </div>
        )}

        {/* Stats grid */}
        <div className="admin-stats-grid">
          {stats ? (
            <>
              <StatCard label="Courses" value={stats.courses} sub={`${stats.active_courses} active`} color="var(--blue-500)" to="/admin/courses" />
              <StatCard label="Modules" value={stats.modules} color="var(--indigo-500)" />
              <StatCard label="Topics" value={stats.topics} sub={`${stats.published_topics} published · ${stats.draft_topics} draft`} color="var(--violet-500)" to="/admin/topics" />
              <StatCard label="Users" value={stats.users} sub={`${stats.admins} admin · ${stats.moderators} mod`} color="var(--slate-500)" to="/admin/users" />
            </>
          ) : !error ? (
            [0,1,2,3].map((i) => (
              <div key={i} className="admin-stat-card admin-stat-card--loading">
                <div className="admin-skeleton admin-skeleton--lg" />
                <div className="admin-skeleton" style={{ width: "60%" }} />
              </div>
            ))
          ) : null}
        </div>

        {/* Content breakdown */}
        {stats && (
          <div className="admin-section">
            <div className="admin-section-header">
              <h2 className="admin-section-title">Content Status</h2>
              <Link to="/admin/topics" className="admin-link-sm">View all topics →</Link>
            </div>
            <div className="admin-progress-row">
              <span className="admin-progress-label">Published topics</span>
              <div className="admin-progress-bar">
                <div
                  className="admin-progress-fill admin-progress-fill--green"
                  style={{ width: stats.topics ? `${(stats.published_topics / stats.topics) * 100}%` : "0%" }}
                />
              </div>
              <span className="admin-progress-val">{stats.published_topics}/{stats.topics}</span>
            </div>
            <div className="admin-progress-row">
              <span className="admin-progress-label">Active courses</span>
              <div className="admin-progress-bar">
                <div
                  className="admin-progress-fill admin-progress-fill--blue"
                  style={{ width: stats.courses ? `${(stats.active_courses / stats.courses) * 100}%` : "0%" }}
                />
              </div>
              <span className="admin-progress-val">{stats.active_courses}/{stats.courses}</span>
            </div>
          </div>
        )}

        {/* Quick links */}
        <div className="admin-section">
          <h2 className="admin-section-title">Quick Actions</h2>
          <div className="admin-quick-links">
            {QUICK_LINKS.map((ql) => (
              <Link key={ql.to} to={ql.to} className="admin-quick-link">
                <span className="admin-quick-icon">{ql.icon}</span>
                {ql.label}
              </Link>
            ))}
          </div>
        </div>
      </div>
    </AdminShell>
  );
}
