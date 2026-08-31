import { useState, useRef, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../lib/AuthContext";
import { useTheme } from "../lib/ThemeContext";

/* Generate up to 2-letter initials from a display name */
function getInitials(name) {
  if (!name) return "?";
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

function Avatar({ name, size = 40 }) {
  return (
    <div
      className="upm-avatar"
      style={{ width: size, height: size, minWidth: size, fontSize: Math.round(size * 0.36) }}
      aria-hidden="true"
    >
      {getInitials(name)}
    </div>
  );
}

/* Sun icon (light mode) */
const SunIcon = () => (
  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
    <circle cx="12" cy="12" r="5"/>
    <line x1="12" y1="1" x2="12" y2="3"/>
    <line x1="12" y1="21" x2="12" y2="23"/>
    <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/>
    <line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/>
    <line x1="1" y1="12" x2="3" y2="12"/>
    <line x1="21" y1="12" x2="23" y2="12"/>
    <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/>
    <line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/>
  </svg>
);

/* Moon icon (dark mode) */
const MoonIcon = () => (
  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
    <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>
  </svg>
);

export default function UserProfileMenu({ collapsed }) {
  const { session, profile, signOut } = useAuth();
  const { isDark, toggle } = useTheme();
  const navigate = useNavigate();
  const [open, setOpen] = useState(false);
  const [confirmSignOut, setConfirmSignOut] = useState(false);
  const menuRef = useRef(null);

  const displayName =
    profile?.display_name ||
    session?.user?.user_metadata?.full_name ||
    session?.user?.email?.split("@")[0] ||
    "User";
  const email = session?.user?.email || "";

  /* Close on outside click */
  useEffect(() => {
    if (!open) return;
    const handler = (e) => {
      if (menuRef.current && !menuRef.current.contains(e.target)) {
        setOpen(false);
        setConfirmSignOut(false);
      }
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, [open]);

  /* Close on Escape */
  useEffect(() => {
    if (!open) return;
    const handler = (e) => {
      if (e.key === "Escape") { setOpen(false); setConfirmSignOut(false); }
    };
    document.addEventListener("keydown", handler);
    return () => document.removeEventListener("keydown", handler);
  }, [open]);

  const close = () => { setOpen(false); setConfirmSignOut(false); };

  const handleSignOut = () => {
    if (!confirmSignOut) { setConfirmSignOut(true); return; }
    signOut();
    close();
  };

  if (!session) return null;

  const menuOpenUp = true; // menu always opens upward from sidebar bottom

  return (
    <div className={"upm-wrap" + (collapsed ? " upm-wrap--collapsed" : "")} ref={menuRef}>
      {/* Profile trigger button */}
      <button
        className={"upm-trigger" + (open ? " upm-trigger--open" : "")}
        onClick={() => { setOpen((o) => !o); setConfirmSignOut(false); }}
        aria-haspopup="true"
        aria-expanded={open}
        aria-label="Open user account menu"
      >
        <Avatar name={displayName} size={36} />
        {!collapsed && (
          <>
            <div className="upm-trigger-text">
              <span className="upm-name">{displayName}</span>
              <span className="upm-email">{email}</span>
            </div>
            <svg
              className={"upm-chevron" + (open ? " upm-chevron--up" : "")}
              width="12" height="12" viewBox="0 0 24 24" fill="none"
              stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"
              aria-hidden="true"
            >
              <polyline points="6 9 12 15 18 9"/>
            </svg>
          </>
        )}
      </button>

      {/* Dropdown menu — opens above the trigger */}
      {open && (
        <div className={"upm-menu" + (collapsed ? " upm-menu--popover" : "")} role="menu">
          {/* User header */}
          <div className="upm-menu-header">
            <Avatar name={displayName} size={34} />
            <div className="upm-menu-header-text">
              <span className="upm-menu-name">{displayName}</span>
              <span className="upm-menu-email">{email}</span>
              {profile?.role && profile.role !== "learner" && (
                <span className="upm-role-badge">{profile.role}</span>
              )}
            </div>
          </div>

          <div className="upm-divider" />

          {/* My Progress / Profile */}
          <button
            className="upm-item"
            role="menuitem"
            onClick={() => { navigate("/progress"); close(); }}
          >
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
              <circle cx="12" cy="7" r="4"/>
            </svg>
            My Progress
          </button>

          {/* Dark mode toggle */}
          <button
            className="upm-item upm-item--toggle"
            role="menuitem"
            onClick={toggle}
            aria-pressed={isDark}
          >
            {isDark ? <SunIcon /> : <MoonIcon />}
            <span className="upm-item-label">Dark Mode</span>
            <span className="upm-toggle-track" aria-hidden="true">
              <span className={"upm-toggle-thumb" + (isDark ? " upm-toggle-thumb--on" : "")} />
            </span>
          </button>

          <div className="upm-divider" />

          {/* Sign out */}
          <button
            className={"upm-item upm-item--danger" + (confirmSignOut ? " upm-item--confirm" : "")}
            role="menuitem"
            onClick={handleSignOut}
          >
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
              <polyline points="16 17 21 12 16 7"/>
              <line x1="21" y1="12" x2="9" y2="12"/>
            </svg>
            {confirmSignOut ? "Confirm — click again" : "Sign out"}
          </button>
        </div>
      )}
    </div>
  );
}
