import { useState, useEffect, useRef } from "react";
import { useTheme } from "../lib/ThemeContext";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../lib/AuthContext";
import NotificationBell from "./NotificationBell";
import { useMobileBar } from "../lib/MobileBarContext";
import { api } from "../lib/api";

/* ── debounced search hook ─────────────────────────────────────────────── */
function useDebouncedSearch(query, delay = 300) {
  const [results, setResults] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const q = query.trim();
    if (!q) { setResults(null); setLoading(false); return; }

    setLoading(true);
    const timer = setTimeout(async () => {
      try {
        const data = await api.get(`/api/topics/search?q=${encodeURIComponent(q)}`);
        setResults(Array.isArray(data) ? data : []);
      } catch {
        setResults([]);
      } finally {
        setLoading(false);
      }
    }, delay);

    return () => {
      clearTimeout(timer);
      setLoading(false);      // cancel in-flight spinner on keystroke
    };
  }, [query, delay]);

  return { results, loading };
}

/* ── theme hook moved to ThemeContext ── */

/* ── component ─────────────────────────────────────────────────────────── */
export default function TopBar({ onMobileMenuToggle }) {
  const { isDark, toggle } = useTheme();
  const { bar } = useMobileBar() || {};
  const navigate = useNavigate();

  const [searchQuery, setSearchQuery] = useState("");
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const searchWrapRef = useRef(null);
  const inputRef = useRef(null);

  const { results, loading } = useDebouncedSearch(searchQuery);

  // open dropdown when results arrive
  useEffect(() => {
    if (results !== null) setDropdownOpen(true);
  }, [results]);

  // close on outside click
  useEffect(() => {
    const handler = (e) => {
      if (!searchWrapRef.current?.contains(e.target)) setDropdownOpen(false);
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  const handleKey = (e) => {
    if (e.key === "Enter" && searchQuery.trim()) {
      setDropdownOpen(false);
      navigate(`/search?q=${encodeURIComponent(searchQuery.trim())}`);
    }
    if (e.key === "Escape") {
      setDropdownOpen(false);
      inputRef.current?.blur();
    }
  };

  const clearSearch = () => {
    setSearchQuery("");
    setDropdownOpen(false);
    inputRef.current?.focus();
  };

  const handleResultClick = () => {
    setSearchQuery("");
    setDropdownOpen(false);
  };

  /* icons */
  const moonIcon = (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>
    </svg>
  );
  const sunIcon = (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="5"/>
      <line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/>
      <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/>
      <line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/>
      <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/>
    </svg>
  );
  const menuIcon = (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="3" y1="6" x2="21" y2="6"/>
      <line x1="3" y1="12" x2="21" y2="12"/>
      <line x1="3" y1="18" x2="21" y2="18"/>
    </svg>
  );

  return (
    <header className="topbar">
      {/* ── Left ─────────────────────────────────────── */}
      {bar ? (
        <div className="topbar-course-left">
          <Link to={bar.backTo || "/"} className="topbar-back-btn" aria-label="Back">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <polyline points="15 18 9 12 15 6"/>
            </svg>
          </Link>
          <span className="topbar-course-title">{bar.title}</span>
          <button className="topbar-hamburger topbar-module-btn" onClick={bar.onToggle} aria-label="Modules">
            {menuIcon}
          </button>
        </div>
      ) : (
        <button className="topbar-hamburger" onClick={onMobileMenuToggle} aria-label="Menu">
          {menuIcon}
        </button>
      )}

      {/* ── Center Search ─────────────────────────────── */}
      <div className="topbar-search-wrap" ref={searchWrapRef}>
        <div className={"topbar-search-box" + (dropdownOpen ? " focused" : "")}>
          <svg className="topbar-search-icon" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
            <circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/>
          </svg>
          <input
            ref={inputRef}
            type="text"
            className="topbar-search-input"
            placeholder="Search topics, code, errors…"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            onKeyDown={handleKey}
            onFocus={() => results !== null && setDropdownOpen(true)}
            autoComplete="off"
          />
          {loading && <span className="topbar-search-spinner" />}
          {searchQuery && !loading && (
            <button className="topbar-search-clear" onClick={clearSearch} title="Clear">×</button>
          )}
        </div>

        {/* Dropdown */}
        {dropdownOpen && results !== null && (
          <div className="topbar-search-dropdown">
            {results.length === 0 ? (
              <div className="topbar-search-empty">No results for "<strong>{searchQuery}</strong>"</div>
            ) : (
              <>
                <div className="topbar-search-dropdown-header">
                  <span>{results.length} result{results.length !== 1 ? "s" : ""}</span>
                  <button
                    className="topbar-search-see-all"
                    onClick={() => { setDropdownOpen(false); navigate(`/search?q=${encodeURIComponent(searchQuery.trim())}`); }}
                  >See all →</button>
                </div>
                {results.slice(0, 7).map((r) => (
                  <button
                    key={r.slug}
                    className="topbar-search-result"
                    data-initial={(r.title || "?").charAt(0).toUpperCase()}
                    onClick={() => {
                      setDropdownOpen(false);
                      navigate(`/search?q=${encodeURIComponent(searchQuery.trim())}`);
                    }}
                  >
                    <div>
                      <div className="topbar-search-result-title">{r.title}</div>
                      {r.snippet && (
                        <div className="topbar-search-result-snippet">{r.snippet}</div>
                      )}
                    </div>
                  </button>
                ))}
                {results.length > 7 && (
                  <button
                    className="topbar-search-see-all-bottom"
                    onClick={() => { setDropdownOpen(false); navigate(`/search?q=${encodeURIComponent(searchQuery.trim())}`); }}
                  >+ {results.length - 7} more results →</button>
                )}
              </>
            )}
          </div>
        )}
      </div>

      {/* ── Right ─────────────────────────────────────── */}
      <div className="topbar-right">
        <NotificationBell />
        <button className="topbar-icon-btn" onClick={toggle} title={isDark ? "Light mode" : "Dark mode"} aria-label="Toggle theme">
          {isDark ? sunIcon : moonIcon}
        </button>
        <Link to="/community?ask=1" className="btn btn-primary topbar-ask-btn">
          Ask a Doubt
        </Link>
      </div>
    </header>
  );
}
