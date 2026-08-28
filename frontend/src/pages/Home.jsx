import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../lib/api";
import { useAuth } from "../lib/AuthContext";

const MODULE_COLORS = [
  "#6366F1", "#8B5CF6", "#EC4899", "#F59E0B", "#10B981", "#3B82F6"
];

function StatusDot({ status }) {
  if (status === "completed") return (
    <span className="status-dot status-dot--done">
      <svg width="9" height="9" viewBox="0 0 12 12" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
        <path d="M2 6l3 3 5-5" />
      </svg>
    </span>
  );
  if (status === "in_progress") return (
    <span className="status-dot status-dot--progress">
      <span style={{ width: 6, height: 6, borderRadius: "50%", background: "currentColor", display: "block" }} />
    </span>
  );
  return <span className="status-dot status-dot--empty" />;
}

function ModuleAccordion({ module, color, index, session }) {
  const [open, setOpen] = useState(index === 0);
  const [topics, setTopics] = useState([]);
  const [progress, setProgress] = useState({});
  const [loaded, setLoaded] = useState(false);

  const toggle = () => {
    if (!loaded) {
      api.get(`/api/modules/${module.id}/topics`).then((ts) => {
        setTopics(ts);
        setLoaded(true);
        if (session) {
          Promise.all(
            ts.map((t) =>
              api.get(`/api/topics/${t.slug}`).then((d) => ({ id: t.id, status: d.progress_status }))
            )
          ).then((results) => {
            const map = {};
            results.forEach(({ id, status }) => (map[id] = status));
            setProgress(map);
          });
        }
      });
    }
    setOpen((o) => !o);
  };

  useEffect(() => {
    // auto-load first module
    if (index === 0) toggle();
  }, []);

  const completedCount = Object.values(progress).filter((s) => s === "completed").length;
  const pct = topics.length > 0 ? Math.round((completedCount / topics.length) * 100) : 0;

  return (
    <div className={"curriculum-module" + (open ? " open" : "")}>
      <button className="curriculum-module-header" onClick={toggle} aria-expanded={open}>
        <div className="curriculum-module-thumb" style={{ background: color }}>
          <span style={{ fontSize: "0.7rem", fontWeight: 700, color: "rgba(255,255,255,.8)", letterSpacing: "0.05em" }}>
            M{module.number}
          </span>
        </div>
        <div className="curriculum-module-info">
          <div className="curriculum-module-title">{module.title}</div>
          {module.subtitle && <div className="curriculum-module-sub">{module.subtitle}</div>}
        </div>
        <div className="curriculum-module-meta">
          {session && topics.length > 0 && (
            <span className="curriculum-module-pct">{pct}%</span>
          )}
          <span className="curriculum-module-count">{topics.length || module.topic_count || "…"} topics</span>
          <svg
            className="curriculum-chevron"
            width="14" height="14" viewBox="0 0 20 20" fill="none"
            stroke="currentColor" strokeWidth="2.2" strokeLinecap="round"
          >
            <path d="M5 8l5 5 5-5" />
          </svg>
        </div>
      </button>

      {open && loaded && (
        <div className="curriculum-topics">
          {topics.map((t, idx) => {
            const status = progress[t.id];
            return (
              <Link
                key={t.id}
                to={`/topics/${t.slug}`}
                className={"curriculum-topic-row" + (status === "completed" ? " done" : "")}
              >
                <StatusDot status={status} />
                <span className="curriculum-topic-num">{String(t.number).padStart(2, "0")}</span>
                <span className="curriculum-topic-title">{t.title}</span>
                <div className="curriculum-topic-badges">
                  {t.video_url && <span className="badge badge-video">▶</span>}
                  {t.github_url && <span className="badge badge-repo">⌥</span>}
                </div>
                <svg width="12" height="12" viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" style={{ color: "var(--text-3)", flexShrink: 0 }}>
                  <path d="M5 10h10M12 6l4 4-4 4" />
                </svg>
              </Link>
            );
          })}

          {open && !loaded && (
            <div style={{ padding: "1rem 1.5rem", color: "var(--text-3)", fontSize: "0.875rem" }}>
              Loading topics…
            </div>
          )}
        </div>
      )}

      {open && !loaded && (
        <div style={{ padding: "1rem 1.5rem" }}>
          {[1,2,3].map(i => (
            <div key={i} style={{ height: 40, background: "var(--surface-2)", borderRadius: "var(--r-sm)", marginBottom: "0.5rem", animation: "pulse 1.4s infinite", animationDelay: `${i*0.1}s` }} />
          ))}
        </div>
      )}
    </div>
  );
}

export default function Home() {
  const { session } = useAuth();
  const [modules, setModules] = useState([]);
  const [firstIncomplete, setFirstIncomplete] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    api.get("/api/modules")
      .then(setModules)
      .catch((e) => setError(e.message));
  }, []);

  // Find the first incomplete topic to power "Continue learning"
  useEffect(() => {
    if (!session || modules.length === 0) return;
    (async () => {
      for (const m of modules) {
        const topics = await api.get(`/api/modules/${m.id}/topics`);
        for (const t of topics) {
          const d = await api.get(`/api/topics/${t.slug}`);
          if (d.progress_status !== "completed") {
            setFirstIncomplete({ slug: t.slug, title: t.title });
            return;
          }
        }
      }
    })();
  }, [session, modules]);

  return (
    <div>
      {/* ── Hero ────────────────────────────────────── */}
      <section className="hero">
        <div className="container hero-inner">
          <div className="hero-content">
            <div className="hero-eyebrow">
              <span>SAP BTP</span>
              <span className="hero-eyebrow-dot">·</span>
              <span>CAP</span>
              <span className="hero-eyebrow-dot">·</span>
              <span>SAPUI5</span>
            </div>
            <h1>
              From zero<br />
              <span>to deployed.</span>
            </h1>
            <p>
              17 hands-on apps across 6 modules — build your first UI5 screen,
              master CAP services, deploy to SAP BTP. Everything on one page.
            </p>
            <div className="hero-ctas">
              {session && firstIncomplete ? (
                <Link to={`/topics/${firstIncomplete.slug}`} className="btn btn-primary hero-cta-primary">
                  Continue: {firstIncomplete.title}
                  <svg width="14" height="14" viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
                    <path d="M4 10h12M10 4l6 6-6 6" />
                  </svg>
                </Link>
              ) : (
                <a href="#curriculum" className="btn btn-primary hero-cta-primary">
                  Browse the course
                  <svg width="14" height="14" viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
                    <path d="M10 4v12M4 10l6 6 6-6" />
                  </svg>
                </a>
              )}
              <Link to="/community" className="btn hero-cta-ghost">Community Q&amp;A</Link>
            </div>
          </div>
          <div className="hero-stats">
            <div className="hero-stat">
              <div className="hero-stat-num">6</div>
              <div className="hero-stat-label">Modules</div>
            </div>
            <div className="hero-stat-divider" />
            <div className="hero-stat">
              <div className="hero-stat-num">17</div>
              <div className="hero-stat-label">Hands-on apps</div>
            </div>
            <div className="hero-stat-divider" />
            <div className="hero-stat">
              <div className="hero-stat-num">1</div>
              <div className="hero-stat-label">BTP capstone</div>
            </div>
          </div>
        </div>
      </section>

      {/* ── Full curriculum ─────────────────────────── */}
      <section id="curriculum" className="curriculum-section">
        <div className="container">
          <div className="section-header">
            <div>
              <h2 className="section-title">Full curriculum</h2>
              <p className="section-sub">Click any module to expand its topics — click a topic to start reading.</p>
            </div>
            <span className="badge badge-outline">{modules.length} modules · 17 topics</span>
          </div>

          {error && (
            <div className="alert alert-danger" style={{ marginBottom: "1.5rem" }}>Failed to load: {error}</div>
          )}

          <div className="curriculum-list">
            {modules.length === 0 && !error ? (
              [1,2,3,4].map(i => (
                <div key={i} style={{ height: 68, background: "var(--surface)", border: "1px solid var(--border)", borderRadius: "var(--r-md)", marginBottom: "0.5rem", animation: "pulse 1.4s infinite", animationDelay: `${i*0.1}s` }} />
              ))
            ) : (
              modules.map((m, i) => (
                <ModuleAccordion
                  key={m.id}
                  module={m}
                  color={MODULE_COLORS[i % MODULE_COLORS.length]}
                  index={i}
                  session={session}
                />
              ))
            )}
          </div>
        </div>
      </section>

      {/* ── Bottom CTA ──────────────────────────────── */}
      <section style={{ paddingBottom: "4rem" }}>
        <div className="container">
          <div className="home-cta-card">
            <div>
              <h3>Have a question while learning?</h3>
              <p>Post it in the community — get answers from fellow learners and moderators.</p>
            </div>
            <Link to="/community" className="btn btn-primary">Go to Community →</Link>
          </div>
        </div>
      </section>
    </div>
  );
}
