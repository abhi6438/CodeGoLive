import { useState } from "react";
import { Link, useLocation } from "react-router-dom";
import { useAuth } from "../lib/AuthContext";
import UserProfileMenu from "./UserProfileMenu";

export default function Sidebar({ collapsed, onToggle }) {
  const { session, profile } = useAuth();
  const { pathname } = useLocation();

  const isAdminRoute = pathname.startsWith("/admin");

  const navLink = (to, label, icon, exact = false) => {
    const active = exact ? pathname === to : pathname.startsWith(to);
    return (
      <Link to={to} className={"sidebar-link" + (active ? " active" : "")}>
        <span className="sidebar-link-icon">{icon}</span>
        {!collapsed && <span className="sidebar-link-label">{label}</span>}
      </Link>
    );
  };

  if (isAdminRoute) return null;

  return (
    <aside className={"sidebar" + (collapsed ? " sidebar--collapsed" : "")}>
      {/* Brand */}
      <div className="sidebar-brand">
        {collapsed ? (
          <button className="sidebar-collapse-btn sidebar-collapse-btn--center" onClick={onToggle} title="Expand sidebar">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <polyline points="9 18 15 12 9 6"/>
            </svg>
          </button>
        ) : (
          <>
            <Link to="/" className="sidebar-brand-link">
              <span className="sidebar-brand-dot" />
              <span className="sidebar-brand-name">CodeGoLive</span>
            </Link>
            <button className="sidebar-collapse-btn" onClick={onToggle} title="Collapse sidebar">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                <polyline points="15 18 9 12 15 6"/>
              </svg>
            </button>
          </>
        )}
      </div>

      {/* Main nav */}
      <nav className="sidebar-nav">
        {!collapsed && <div className="sidebar-section-label">Menu</div>}
        {navLink("/", "Course", "📚", true)}
        {navLink("/community", "Community", "💬")}
        {session && navLink("/certificate", "Certificate", "🎓")}
      </nav>

      {/* Admin shortcut */}
      {(profile?.role === "admin" || profile?.role === "moderator") && (
        <nav className="sidebar-nav sidebar-nav--admin">
          {!collapsed && <div className="sidebar-section-label">Admin</div>}
          {navLink("/admin", "Admin Console", "⚙️", true)}
        </nav>
      )}

      {/* Bottom — user profile / sign in */}
      <div className="sidebar-bottom">
        {session ? (
          <UserProfileMenu collapsed={collapsed} />
        ) : (
          <Link to="/login" className="sidebar-link">
            <span className="sidebar-link-icon">
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/>
                <polyline points="10 17 15 12 10 7"/>
                <line x1="15" y1="12" x2="3" y2="12"/>
              </svg>
            </span>
            {!collapsed && <span className="sidebar-link-label">Sign in</span>}
          </Link>
        )}
      </div>
    </aside>
  );
}
