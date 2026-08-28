import { useEffect, useState } from "react";
import { useParams, Link } from "react-router-dom";
import { api } from "../lib/api";
import { useAuth } from "../lib/AuthContext";

function StatusDot({ status }) {
  if (status === "completed") return (
    <span className="status-dot status-dot--done" title="Completed">
      <svg width="10" height="10" viewBox="0 0 12 12" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
        <path d="M2 6l3 3 5-5" />
      </svg>
    </span>
  );
  if (status === "in_progress") return (
    <span className="status-dot status-dot--progress" title="In progress">
      <svg width="8" height="8" viewBox="0 0 12 12" fill="currentColor">
        <path d="M6 0a6 6 0 0 1 0 12V9a3 3 0 0 0 0-6V0z" opacity=".4"/>
        <path d="M6 0a6 6 0 0 1 6 6H9a3 3 0 0 0-3-3V0z"/>
      </svg>
    </span>
  );
  return <span className="status-dot status-dot--empty" title="Not started" />;
}

function ProgressBar({ done, total }) {
  const pct = total > 0 ? Math.round((done / total) * 100) : 0;
  return (
    <div style={{ display: "flex", alignItems: "center", gap: "0.75rem", marginTop: "1rem" }}>
      <div className="progress-bar-track" style={{ flex: 1 }}>
        <div className="progress-bar-fill" style={{ width: `${pct}%` }} />
      </div>
      <span style={{ fontSize: "0.78rem", color: "var(--text-3)", whiteSpace: "nowrap", fontVariantNumeric: "tabular-nums" }}>
        {done}/{total}
      </span>
    </div>
  );
}

export default function ModulePage() {
  const { moduleId } = useParams();
  const { session } = useAuth();
  const [module, setModule] = useState(null);
  const [topics, setTopics] = useState([]);
  const [progress, setProgress] = useState({});

  useEffect(() => {
    api.get(`/api/modules/${moduleId}/topics`).then(setTopics);
    api.get(`/api/modules`).then((mods) => {
      const m = mods.find((m) => m.id === moduleId);
      if (m) setModule(m);
    });
  }, [moduleId]);

  useEffect(() => {
    if (!session || topics.length === 0) return;
    Promise.all(
      topics.map((t) =>
        api.get(`/api/topics/${t.slug}`).then((d) => ({ id: t.id, status: d.progress_status }))
      )
    ).then((results) => {
      const map = {};
      results.forEach(({ id, status }) => (map[id] = status));
      setProgress(map);
    });
  }, [session, topics]);

  const completedCount = Object.values(progress).filter((s) => s === "completed").length;
  const firstIncomplete = topics.find((t) => progress[t.id] !== "completed");

  return (
    <div style={{ minHeight: "calc(100vh - 64px)", paddingBottom: "4rem" }}>
      {/* ── Module header ──────────────────────────── */}
      <div className="page-header">
        <div className="container">
          <Link to="/" className="breadcrumb-back">
            <svg width="14" height="14" viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round">
              <path d="M13 4l-6 6 6 6" />
            </svg>
            All modules
          </Link>
          {module ? (
            <div className="module-header-content">
              <div className="module-header-meta">
                <span className="badge badge-outline">Module {module.number}</span>
                {session && topics.length > 0 && (
                  <span className="badge" style={{ background: "var(--success-light)", color: "var(--success)" }}>
                    {completedCount}/{topics.length} completed
                  </span>
                )}
              </div>
              <h1 className="page-title">{module.title}</h1>
              {module.subtitle && <p className="page-sub">{module.subtitle}</p>}
              {session && topics.length > 0 && (
                <ProgressBar done={completedCount} total={topics.length} />
              )}
              {session && firstIncomplete && (
                <Link to={`/topics/${firstIncomplete.slug}`} className="btn btn-primary" style={{ marginTop: "1.25rem" }}>
                  {completedCount === 0 ? "Start module" : "Continue"} →
                </Link>
              )}
            </div>
          ) : (
            <div style={{ height: 80, background: "var(--surface-2)", borderRadius: "var(--r-sm)", animation: "pulse 1.4s infinite" }} />
          )}
        </div>
      </div>

      {/* ── Topic list ─────────────────────────────── */}
      <div className="container" style={{ paddingTop: "2rem" }}>
        <div className="topic-list-header">
          <span className="section-eyebrow">{topics.length} {topics.length === 1 ? "topic" : "topics"} in this module</span>
        </div>

        <div className="topic-list">
          {topics.map((t, idx) => {
            const status = progress[t.id];
            const locked = session && idx > 0 && progress[topics[idx - 1]?.id] !== "completed" && status !== "completed" && status !== "in_progress";
            return (
              <Link
                key={t.id}
                to={locked ? "#" : `/topics/${t.slug}`}
                className={"topic-row" + (locked ? " topic-row--locked" : "") + (status === "completed" ? " topic-row--done" : "")}
                onClick={locked ? (e) => e.preventDefault() : undefined}
                style={{ textDecoration: "none", color: "inherit" }}
              >
                <div className="topic-row-left">
                  <StatusDot status={locked ? "locked" : status} />
                  <div className="topic-row-num">{String(t.number).padStart(2, "0")}</div>
                  <div className="topic-row-info">
                    <div className="topic-row-title">{t.title}</div>
                    {t.focus && <div className="topic-row-focus">{t.focus}</div>}
                  </div>
                </div>
                <div className="topic-row-right">
                  {t.video_url && (
                    <span className="badge badge-video">▶ Video</span>
                  )}
                  {t.github_url && (
                    <span className="badge badge-repo">⌥ Repo</span>
                  )}
                  {locked ? (
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" style={{ color: "var(--text-3)" }}>
                      <rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>
                    </svg>
                  ) : (
                    <svg width="14" height="14" viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" style={{ color: "var(--text-3)" }}>
                      <path d="M5 10h10M12 6l4 4-4 4"/>
                    </svg>
                  )}
                </div>
              </Link>
            );
          })}
        </div>
      </div>
    </div>
  );
}
