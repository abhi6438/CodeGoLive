import { useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "../lib/AuthContext";

const NAV = [
  {
    section: "Overview",
    items: [
      { to: "/admin", label: "Dashboard", icon: "◈", exact: true },
    ],
  },
  {
    section: "Content",
    items: [
      { to: "/admin/courses", label: "Courses", icon: "📚" },
      { to: "/admin/topics", label: "Topics", icon: "📝" },
    ],
  },
  {
    section: "Community",
    items: [
      { to: "/admin/moderation", label: "Moderation", icon: "🛡️" },
      { to: "/admin/tags", label: "Tags", icon: "🏷️" },
    ],
  },
  {
    section: "System",
    items: [
      { to: "/admin/users", label: "Users", icon: "👥" },
      { to: "/admin/analytics", label: "Analytics", icon: "📊" },
    ],
  },
];

export default function AdminShell({ children, breadcrumbs }) {
  const { pathname } = useLocation();
  const [mobileNavOpen, setMobileNavOpen] = useState(false);

  const isActive = (to, exact) =>
    exact ? pathname === to : pathname === to || pathname.startsWith(to + "/");

  return (
    <div className="admin-shell">
      {/* Mobile nav toggle */}
      <div className="admin-mobile-bar">
        <button
          className="admin-mobile-toggle"
          onClick={() => setMobileNavOpen((o) => !o)}
          aria-label="Toggle admin nav"
        >
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
            <line x1="3" y1="6" x2="21" y2="6" />
            <line x1="3" y1="12" x2="21" y2="12" />
            <line x1="3" y1="18" x2="21" y2="18" />
          </svg>
          <span>Admin Menu</span>
        </button>
        {breadcrumbs && (
          <nav className="admin-breadcrumb admin-breadcrumb--mobile" aria-label="Breadcrumb">
            {breadcrumbs.map((b, i) => (
              <span key={i} className="admin-bc-item">
                {i > 0 && <span className="admin-bc-sep">/</span>}
                {b.to ? <Link to={b.to}>{b.label}</Link> : <span>{b.label}</span>}
              </span>
            ))}
          </nav>
        )}
      </div>

      <div className="admin-layout">
        {/* Sidebar */}
        <aside className={"admin-sidebar" + (mobileNavOpen ? " admin-sidebar--open" : "")}>
          <div className="admin-sidebar-header">
            <span className="admin-sidebar-badge">Admin</span>
            <Link to="/" className="admin-sidebar-home" title="Back to app">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>
                <polyline points="9 22 9 12 15 12 15 22"/>
              </svg>
              App
            </Link>
          </div>

          {NAV.map((group) => (
            <div key={group.section} className="admin-nav-group">
              <div className="admin-nav-section">{group.section}</div>
              {group.items.map((item) => (
                <Link
                  key={item.to}
                  to={item.to}
                  className={"admin-nav-link" + (isActive(item.to, item.exact) ? " active" : "")}
                  onClick={() => setMobileNavOpen(false)}
                >
                  <span className="admin-nav-icon">{item.icon}</span>
                  {item.label}
                </Link>
              ))}
            </div>
          ))}
        </aside>

        {/* Main content */}
        <main className="admin-content">
          {breadcrumbs && breadcrumbs.length > 0 && (
            <nav className="admin-breadcrumb" aria-label="Breadcrumb">
              {breadcrumbs.map((b, i) => (
                <span key={i} className="admin-bc-item">
                  {i > 0 && <span className="admin-bc-sep">/</span>}
                  {b.to ? <Link to={b.to}>{b.label}</Link> : <span>{b.label}</span>}
                </span>
              ))}
            </nav>
          )}
          {children}
        </main>
      </div>

      {/* Mobile overlay */}
      {mobileNavOpen && (
        <div className="admin-sidebar-overlay" onClick={() => setMobileNavOpen(false)} />
      )}
    </div>
  );
}
