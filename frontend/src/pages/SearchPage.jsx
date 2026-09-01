import { useState, useEffect, useRef } from "react";
import { useSearchParams, useNavigate } from "react-router-dom";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { Prism as SyntaxHighlighter } from "react-syntax-highlighter";
import { vscDarkPlus } from "react-syntax-highlighter/dist/esm/styles/prism";
import { api } from "../lib/api";
import SEO from "../components/SEO";
import QuoteBanner from "../components/QuoteBanner";
import { QUOTES } from "../constants/quotes";

/* ── badge color cycle (like module colors) ────────────────── */
const COURSE_LABELS = {
  "sap-btp": { label: "SAP BTP", color: "#0070F3" },
  "sap-ai":  { label: "SAP AI",  color: "#7C3AED" },
};

const BADGE_COLORS = ["#6366f1","#ec4899","#f97316","#10b981","#3b82f6","#8b5cf6","#f59e0b"];
function badgeColor(str = "") {
  let h = 0;
  for (let c of str) h = (h * 31 + c.charCodeAt(0)) & 0xffffff;
  return BADGE_COLORS[Math.abs(h) % BADGE_COLORS.length];
}

/* ── highlight matched text ─────────────────────────────────── */
function Highlight({ text = "", query = "" }) {
  if (!query) return <>{text}</>;
  const esc = query.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const parts = text.split(new RegExp(`(${esc})`, "gi"));
  return <>{parts.map((p, i) =>
    p.toLowerCase() === query.toLowerCase()
      ? <mark key={i} className="srp-mark">{p}</mark>
      : p
  )}</>;
}

/* ── markdown code block ───────────────────────────────────── */
const mdComponents = {
  code({ node, inline, className, children, ...props }) {
    const lang = /language-(\w+)/.exec(className || "")?.[1];
    return !inline && lang ? (
      <SyntaxHighlighter style={vscDarkPlus} language={lang} PreTag="div" {...props}>
        {String(children).replace(/\n$/, "")}
      </SyntaxHighlighter>
    ) : (
      <code className={className} {...props}>{children}</code>
    );
  },
};

/* ── main component ─────────────────────────────────────────── */
export default function SearchPage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const [query, setQuery] = useState(searchParams.get("q") || "");
  const [results, setResults] = useState(null);
  const [loading, setLoading] = useState(false);
  const [selected, setSelected] = useState(null);      // slug of selected topic
  const [topicData, setTopicData] = useState(null);    // full topic object
  const [topicLoading, setTopicLoading] = useState(false);
  const [courseFilter, setCourseFilter] = useState(null); // null = all
  const inputRef = useRef(null);

  /* ── search ── */
  const doSearch = async (q) => {
    const trimmed = q.trim();
    if (!trimmed) { setResults(null); setSelected(null); setTopicData(null); return; }
    setLoading(true);
    try {
      const data = await api.get(`/api/topics/search?q=${encodeURIComponent(trimmed)}`);
      setResults(Array.isArray(data) ? data : []);
      if (data?.length > 0) {
        setSelected(data[0].slug);
      } else {
        setSelected(null); setTopicData(null);
      }
    } catch { setResults([]); }
    finally { setLoading(false); }
  };

  /* ── load topic content when selected changes ── */
  useEffect(() => {
    if (!selected) { setTopicData(null); return; }
    setTopicLoading(true);
    api.get(`/api/topics/${selected}`)
      .then(d => setTopicData(d))
      .catch(() => setTopicData(null))
      .finally(() => setTopicLoading(false));
  }, [selected]);

  /* ── run on mount / URL change ── */
  useEffect(() => {
    const q = searchParams.get("q") || "";
    if (q) { setQuery(q); doSearch(q); }
    inputRef.current?.focus();
  }, []);

  useEffect(() => {
    const q = searchParams.get("q") || "";
    if (q && q !== query) { setQuery(q); doSearch(q); }
  }, [searchParams]);

  const handleSubmit = (e) => {
    e.preventDefault();
    const q = query.trim();
    setSearchParams(q ? { q } : {});
    doSearch(q);
  };

  const suggestions = ["CORS error","OData binding","cds deploy","routing","XSUAA","f4 dialog","SQLite","approuter","manifest.json","BTP trial"];

  return (
    <div className="srp-shell">
      <SEO title="Search" description="Search lessons and topics across all CodeGoLive SAP development courses." />

      {/* ══ LEFT PANEL ══════════════════════════════════════════ */}
      <div className="srp-left">
        {/* Search bar */}
        <form onSubmit={handleSubmit} className="srp-search-form">
          <div className="srp-search-row">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
              <circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/>
            </svg>
            <input
              ref={inputRef}
              type="text"
              value={query}
              onChange={e => setQuery(e.target.value)}
              placeholder="Search anything…"
              className="srp-search-input"
            />
            {query && (
              <button type="button" className="srp-clear"
                onClick={() => { setQuery(""); setResults(null); setSelected(null); setTopicData(null); inputRef.current?.focus(); }}>
                ×
              </button>
            )}
          </div>
        </form>

        {/* Status */}
        {loading && (
          <div className="srp-status">
            <span className="srp-spinner" /> Searching…
          </div>
        )}
        {results !== null && !loading && (
          <div className="srp-status">
            {results.length === 0
              ? `No results for "${query}"`
              : <><strong>{results.length}</strong> result{results.length !== 1 ? "s" : ""} for "<em>{query}</em>"</>
            }
          </div>
        )}

        {/* Suggestion chips (when no results) */}
        {results === null && !loading && (
          <div className="srp-chips">
            {suggestions.map(s => (
              <button key={s} className="srp-chip"
                onClick={() => { setQuery(s); setSearchParams({ q: s }); doSearch(s); }}>
                {s}
              </button>
            ))}
          </div>
        )}

        {/* Results list */}
        {/* Course filter chips */}
        {results !== null && results.length > 0 && !loading && (() => {
          const availCourses = [...new Set(results.map(r => r.course_id).filter(Boolean))];
          return availCourses.length > 1 ? (
            <div style={{ display:"flex", gap:"0.4rem", flexWrap:"wrap", margin:"0.75rem 0 0.25rem" }}>
              <button className={"srp-chip" + (!courseFilter ? " srp-chip--active" : "")}
                onClick={() => setCourseFilter(null)}>All</button>
              {availCourses.map(cid => {
                const meta = COURSE_LABELS[cid] || { label: cid, color: "#888" };
                return (
                  <button key={cid}
                    className={"srp-chip" + (courseFilter === cid ? " srp-chip--active" : "")}
                    style={courseFilter === cid ? { borderColor: meta.color, color: meta.color } : {}}
                    onClick={() => setCourseFilter(f => f === cid ? null : cid)}>
                    {meta.label}
                  </button>
                );
              })}
            </div>
          ) : null;
        })()}

        {results !== null && results.length > 0 && !loading && (
          <div className="srp-list">
            {results.filter(r => !courseFilter || r.course_id === courseFilter).map((r) => {
              const color = badgeColor(r.slug || r.title);
              const isActive = r.slug === selected;
              return (
                <button
                  key={r.slug}
                  className={"srp-item" + (isActive ? " srp-item--active" : "")}
                  onClick={() => setSelected(r.slug)}
                >
                  <span className="srp-item-badge" style={{ background: color }}>
                    {(r.title || "?").charAt(0).toUpperCase()}
                  </span>
                  <div className="srp-item-body">
                    {(r.course_id || r.module_title) && (
                      <div className="srp-item-breadcrumb">
                        {r.course_id && COURSE_LABELS[r.course_id] && (
                          <span style={{ color: COURSE_LABELS[r.course_id].color, fontWeight: 600 }}>
                            {COURSE_LABELS[r.course_id].label}
                          </span>
                        )}
                        {r.course_id && r.module_title && <span style={{ margin:"0 0.2rem", opacity:0.4 }}>›</span>}
                        {r.module_title && <span>{r.module_title}</span>}
                      </div>
                    )}
                    <div className="srp-item-title">
                      <Highlight text={r.title} query={query} />
                    </div>
                    {r.snippet && (
                      <div className="srp-item-snippet">
                        <Highlight text={r.snippet} query={query} />
                      </div>
                    )}
                  </div>
                </button>
              );
            })}
          </div>
        )}

        {/* Empty state */}
        {results !== null && results.length === 0 && !loading && (
          <div className="srp-chips" style={{ marginTop: "1.5rem" }}>
            {suggestions.map(s => (
              <button key={s} className="srp-chip"
                onClick={() => { setQuery(s); setSearchParams({ q: s }); doSearch(s); }}>
                {s}
              </button>
            ))}
          </div>
        )}
      </div>

      {/* ══ RIGHT PANEL ═════════════════════════════════════════ */}
      <div className="srp-right">
        {/* No query */}
        {results === null && !loading && (
          <div className="srp-empty">
            <QuoteBanner quote={QUOTES.SEARCH_EMPTY} emoji="🔍" variant="default" />
            <div className="srp-empty-icon">⌕</div>
            <p>Type a keyword and press Enter — or pick a suggestion.</p>
          </div>
        )}

        {/* Loading topic */}
        {topicLoading && (
          <div className="srp-empty">
            <span className="srp-spinner" style={{ width:20, height:20 }} />
          </div>
        )}

        {/* Topic content */}
        {topicData && !topicLoading && (
          <div className="srp-content">
            {/* Header */}
            <div className="srp-content-header">
              <div className="srp-content-eyebrow" style={{ display:"flex", alignItems:"center", gap:"0.35rem" }}>
                {topicData.course_id && COURSE_LABELS[topicData.course_id] && (
                  <span style={{ color: COURSE_LABELS[topicData.course_id].color, fontWeight:700 }}>
                    {COURSE_LABELS[topicData.course_id].label}
                  </span>
                )}
                {topicData.course_id && topicData.module_title && <span style={{ opacity:0.35 }}>›</span>}
                <span>{topicData.module_title || topicData.module?.title || topicData.focus || "Topic"}</span>
              </div>
              <h1 className="srp-content-title">{topicData.title}</h1>
              {topicData.description && (
                <p className="srp-content-desc">{topicData.description}</p>
              )}
              <a href={`/course/${topicData.course_id || "sap-btp"}/${topicData.slug}`} className="btn btn-primary srp-open-btn">
                Open full lesson →
              </a>
            </div>

            <hr className="srp-divider" />

            {/* Markdown body */}
            {topicData.content_md ? (
              <div className="lesson-body">
                <ReactMarkdown remarkPlugins={[remarkGfm]} components={mdComponents}>
                  {topicData.content_md}
                </ReactMarkdown>
              </div>
            ) : (
              <div className="srp-no-content">No content preview available.</div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
