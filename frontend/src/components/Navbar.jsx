import { useState, useEffect, useRef } from "react";
import { Link, useLocation } from "react-router-dom";
import { useAuth } from "../lib/AuthContext";
import NotificationBell from "./NotificationBell";

function useTheme() {
  const [theme, setTheme] = useState(() => {
    return localStorage.getItem("ztd-theme") || "system";
  });

  useEffect(() => {
    const root = document.documentElement;
    if (theme === "dark") {
      root.setAttribute("data-theme", "dark");
    } else if (theme === "light") {
      root.setAttribute("data-theme", "light");
    } else {
      root.removeAttribute("data-theme");
    }
    localStorage.setItem("ztd-theme", theme);
  }, [theme]);

  const toggle = () =>
    setTheme((t) => {
      if (t === "system") {
        const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
        return prefersDark ? "light" : "dark";
      }
      return t === "dark" ? "light" : "dark";
    });

  const isDark =
    theme === "dark" ||
    (theme === "system" && window.matchMedia("(prefers-color-scheme: dark)").matches);

  return { theme, isDark, toggle };
}

function SunIcon() {
  return (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="5"/>
      <line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/>
      <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/>
      <line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/>
      <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/>
    </svg>
  );
}

function MoonIcon() {
  return (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>
    </svg>
  );
}

export default function Navbar() {
  const { session, profile, signOut } = useAuth();
  const { pathname } = useLocation();
  const { isDark, toggle } = useTheme();
  const [menuOpen, setMenuOpen] = useState(false);
  const menuRef = useRef(null);

  useEffect(() => {
    const handler = (e) => {
      if (menuRef.current && !menuRef.current.contains(e.target)) setMenuOpen(false);
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  const navLink = (to, label, exact = false) => {
    const active = exact ? pathname === to : pathname.startsWith(to);
    return (
      <Link to={to} className={"nav-link" + (active ? " active" : "")} onClick={() => setMenuOpen(false)}>
        {label}
      </Link>
    );
  };

  return (
    <header className="navbar">
      <div className="navbar-inner container">

        {/* LEFT: Brand + Nav */}
        <div className="navbar-left">
          <Link to="/" className="brand">
            <span className="brand-dot" />
            CodeGoLive
          </Link>
          <nav className="nav-links">
            {navLink("/", "Course", true)}
            {navLink("/community", "Community")}
            {profile?.role === "admin" && navLink("/admin", "Admin")}
            {profile?.role === "moderator" && (
              <Link
                to="/admin/moderation"
                className={"nav-link" + (pathname.startsWith("/admin/moderation") ? " active" : "")}
              >
                Moderate
              </Link>
            )}
          </nav>
        </div>

        {/* RIGHT: Actions */}
        <div className="nav-actions">
          <Link to="/search" className="nav-icon-btn" title="Search" aria-label="Search">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/>
            </svg>
          </Link>

          {session && (
            <Link to="/progress" className="nav-icon-btn" title="My Progress" aria-label="My Progress">
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M18 20V10M12 20V4M6 20v-6"/>
              </svg>
            </Link>
          )}

          {session && (
            <Link to="/certificate" className="nav-icon-btn" title="My Certificate" aria-label="My Certificate">
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
                <circle cx="12" cy="8" r="5"/>
                <path d="M8 18c0-2.2 1.8-4 4-4s4 1.8 4 4"/>
                <path d="M9 20l1.5-2.5L12 19l1.5-2.5L15 20"/>
              </svg>
            </Link>
          )}

          <NotificationBell />

          {/* Theme toggle */}
          <button
            className="nav-icon-btn nav-theme-toggle"
            onClick={toggle}
            title={isDark ? "Switch to light mode" : "Switch to dark mode"}
            aria-label="Toggle theme"
          >
            {isDark ? <SunIcon /> : <MoonIcon />}
          </button>

          <Link to="/community" className="btn btn-primary nav-ask-btn">
            Ask a Doubt
          </Link>

          {session ? (
            <button className="nav-signout-btn" onClick={signOut}>Sign out</button>
          ) : (
            <Link to="/login" className="btn btn-outline nav-signin-btn">Sign in</Link>
          )}
        </div>

        {/* Mobile hamburger */}
        <button
          className={"nav-hamburger" + (menuOpen ? " open" : "")}
          aria-label="Menu"
          onClick={() => setMenuOpen((o) => !o)}
        >
          <span /><span /><span />
        </button>
      </div>

      {/* Mobile dropdown */}
      {menuOpen && (
        <div className="nav-mobile-menu" ref={menuRef}>
          {navLink("/", "Course", true)}
          {navLink("/community", "Community")}
          {navLink("/search", "Search")}
          {session && navLink("/progress", "My Progress")}
          {session && navLink("/certificate", "My Certificate")}
          {profile?.role === "admin" && navLink("/admin", "Admin")}
          {profile?.role === "moderator" && (
            <Link to="/admin/moderation" className="nav-link" onClick={() => setMenuOpen(false)}>Moderate</Link>
          )}
          <div className="nav-mobile-divider">
            <button className="nav-link nav-mobile-theme-btn" onClick={toggle}>
              {isDark ? <SunIcon /> : <MoonIcon />}
              {isDark ? "Light mode" : "Dark mode"}
            </button>
            {session ? (
              <button className="nav-link" style={{ width: "100%", textAlign: "left" }}
                onClick={() => { signOut(); setMenuOpen(false); }}>
                Sign out
              </button>
            ) : (
              <Link to="/login" className="nav-link" onClick={() => setMenuOpen(false)}>Sign in</Link>
            )}
          </div>
        </div>
      )}
    </header>
  );
}
