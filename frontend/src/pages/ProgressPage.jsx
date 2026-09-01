import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { api } from "../lib/api";
import { useAuth } from "../lib/AuthContext";
import { COURSES } from "../lib/courses";
import QuoteCard from "../components/QuoteCard";
import { QUOTES } from "../constants/quotes";

/* ─── Ring SVG ─────────────────────────────────────────────── */
function Ring({ pct, size = 88, stroke = 8, color }) {
  const r = (size - stroke) / 2;
  const circ = 2 * Math.PI * r;
  const dash = (pct / 100) * circ;
  return (
    <svg width={size} height={size} style={{ transform: "rotate(-90deg)", flexShrink: 0 }}>
      <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="var(--border)" strokeWidth={stroke} />
      <circle
        cx={size / 2} cy={size / 2} r={r} fill="none"
        stroke={color || "var(--accent)"}
        strokeWidth={stroke}
        strokeLinecap="round"
        strokeDasharray={`${dash} ${circ}`}
        style={{ transition: "stroke-dasharray 0.6s ease" }}
      />
    </svg>
  );
}

/* ─── Mini module bar ──────────────────────────────────────── */
function ModuleBar({ mod, accentColor }) {
  const pct = mod.pct;
  const done = mod.completed === mod.total && mod.total > 0;
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "0.3rem" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <span style={{
          fontSize: "0.78rem",
          color: done ? "var(--text)" : "var(--text-2)",
          fontWeight: done ? 600 : 400,
          display: "flex", alignItems: "center", gap: "0.35rem",
        }}>
          {done && (
            <svg width="12" height="12" viewBox="0 0 12 12" fill="none" stroke={accentColor || "var(--accent)"} strokeWidth="2.5" strokeLinecap="round">
              <path d="M2 6l3 3 5-5" />
            </svg>
          )}
          {mod.title}
        </span>
        <span style={{ fontSize: "0.72rem", color: "var(--text-3)", whiteSpace: "nowrap" }}>
          {mod.completed}/{mod.total}
        </span>
      </div>
      <div style={{ height: 5, borderRadius: 99, background: "var(--border)", overflow: "hidden" }}>
        <div style={{
          height: "100%",
          width: `${pct}%`,
          borderRadius: 99,
          background: accentColor || "var(--accent)",
          transition: "width 0.6s ease",
        }} />
      </div>
    </div>
  );
}

/* ─── Course progress card ──────────────────────────────────── */
function CourseCard({ data }) {
  const staticCourse = COURSES.find((c) => c.id === data.course_id) || {};
  const accent = staticCourse.accentColor || "var(--accent)";
  const icon = staticCourse.icon || "📚";

  const allDone = data.completion_pct === 100 && data.total_topics > 0;
  const started = data.completed > 0 || data.in_progress > 0;

  return (
    <div style={{
      background: "var(--surface)",
      border: "1px solid var(--border)",
      borderRadius: 14,
      padding: "1.5rem",
      display: "flex",
      flexDirection: "column",
      gap: "1.25rem",
    }}>
      {/* Header row */}
      <div style={{ display: "flex", alignItems: "center", gap: "0.75rem" }}>
        <span style={{
          fontSize: "1.6rem",
          width: 44, height: 44, borderRadius: 10,
          background: "var(--surface-2)",
          display: "flex", alignItems: "center", justifyContent: "center",
          flexShrink: 0,
        }}>{icon}</span>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontWeight: 700, fontSize: "0.95rem", color: "var(--text)", lineHeight: 1.2 }}>{data.title}</div>
          {allDone && (
            <div style={{
              fontSize: "0.72rem", fontWeight: 700, color: accent,
              marginTop: "0.25rem", letterSpacing: "0.04em", textTransform: "uppercase",
            }}>✓ Completed</div>
          )}
          {!allDone && started && (
            <div style={{ fontSize: "0.72rem", color: "var(--text-3)", marginTop: "0.25rem" }}>
              {data.in_progress > 0 ? `${data.in_progress} in progress · ` : ""}{data.completed} of {data.total_topics} topics done
            </div>
          )}
          {!started && (
            <div style={{ fontSize: "0.72rem", color: "var(--text-3)", marginTop: "0.25rem" }}>Not started yet</div>
          )}
        </div>

        {/* Progress ring */}
        <div style={{ position: "relative", flexShrink: 0 }}>
          <Ring pct={data.completion_pct} color={accent} />
          <div style={{
            position: "absolute", inset: 0,
            display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
            fontSize: "0.9rem", fontWeight: 800, color: "var(--text)", lineHeight: 1,
          }}>
            {data.completion_pct}
            <span style={{ fontSize: "0.6rem", color: "var(--text-3)", fontWeight: 500 }}>%</span>
          </div>
        </div>
      </div>

      {/* Module breakdown */}
      {data.modules.length > 0 && (
        <div style={{ display: "flex", flexDirection: "column", gap: "0.6rem" }}>
          {data.modules.map((m) => (
            <ModuleBar key={m.module_id} mod={m} accentColor={accent} />
          ))}
        </div>
      )}

      {/* CTA */}
      <Link
        to={`/course/${data.course_id}`}
        style={{
          display: "inline-flex", alignItems: "center", gap: "0.4rem",
          fontSize: "0.82rem", fontWeight: 600,
          color: allDone ? "var(--text-2)" : accent,
          textDecoration: "none",
          marginTop: "auto",
          paddingTop: "0.25rem",
        }}
      >
        {allDone ? "Review Course" : started ? "Continue Learning" : "Start Course"}
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
          <path d="M5 12h14M12 5l7 7-7 7" />
        </svg>
      </Link>
    </div>
  );
}

/* ─── Stat chip ─────────────────────────────────────────────── */
function Stat({ value, label, icon }) {
  return (
    <div style={{
      background: "var(--surface)",
      border: "1px solid var(--border)",
      borderRadius: 12,
      padding: "1rem 1.25rem",
      display: "flex", alignItems: "center", gap: "0.75rem",
    }}>
      <span style={{ fontSize: "1.4rem", lineHeight: 1 }}>{icon}</span>
      <div>
        <div style={{ fontSize: "1.35rem", fontWeight: 800, color: "var(--text)", lineHeight: 1 }}>{value}</div>
        <div style={{ fontSize: "0.72rem", color: "var(--text-3)", marginTop: "0.2rem", textTransform: "uppercase", letterSpacing: "0.06em" }}>{label}</div>
      </div>
    </div>
  );
}

/* ─── Main page ─────────────────────────────────────────────── */
export default function ProgressPage() {
  const { session, loading } = useAuth();
  const navigate = useNavigate();
  const [data, setData] = useState(null);
  const [fetching, setFetching] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (loading) return;
    if (!session) { navigate("/login"); return; }
    setFetching(true);
    api.get("/api/progress/summary")
      .then(setData)
      .catch((e) => setError(e.message))
      .finally(() => setFetching(false));
  }, [session, loading]); // eslint-disable-line

  if (loading || fetching) {
    return (
      <div style={{ display: "flex", justifyContent: "center", alignItems: "center", minHeight: "50vh" }}>
        <div className="ws-content-spinner" />
      </div>
    );
  }

  if (error) {
    return (
      <div style={{ textAlign: "center", padding: "4rem 1rem" }}>
        <p style={{ color: "var(--text-2)", marginBottom: "1rem" }}>Could not load progress data.</p>
        <button className="btn btn-primary" onClick={() => window.location.reload()}>Retry</button>
      </div>
    );
  }

  if (!data) return null;

  const activeCourses = data.courses.filter((c) => c.completed > 0 || c.in_progress > 0).length;
  const totalTopics = data.courses.reduce((s, c) => s + c.total_topics, 0);

  return (
    <div style={{ maxWidth: 860, margin: "0 auto", padding: "2rem 1.25rem 4rem" }}>

      {/* Page header */}
      <div style={{ marginBottom: "2rem" }}>
        <h1 style={{ margin: 0, fontSize: "1.6rem", fontWeight: 800, color: "var(--text)" }}>My Progress</h1>
        <QuoteCard quote={QUOTES.PROGRESS} emoji="📊" variant="default" style={{marginTop:"0.75rem"}} />
        <p style={{ margin: "0.4rem 0 0", color: "var(--text-2)", fontSize: "0.9rem" }}>
          Track your learning journey across all courses.
        </p>
        <QuoteCard quote={QUOTES.PROGRESS} emoji="📊" variant="default" style={{marginTop:"1rem"}} />
      </div>

      {/* Top stats */}
      <div style={{
        display: "grid",
        gridTemplateColumns: "repeat(auto-fit, minmax(160px, 1fr))",
        gap: "0.75rem",
        marginBottom: "2rem",
      }}>
        <Stat value={data.total_completed} label="Topics Completed" icon="✅" />
        <Stat value={`${data.streak} day${data.streak !== 1 ? "s" : ""}`} label="Current Streak" icon="🔥" />
        <Stat value={activeCourses} label="Courses Started" icon="📚" />
        <Stat value={totalTopics} label="Total Topics" icon="📖" />
      </div>

      {/* Course cards */}
      {data.courses.length === 0 ? (
        <div style={{ textAlign: "center", padding: "3rem", color: "var(--text-2)" }}>
          <div style={{ fontSize: "2.5rem", marginBottom: "1rem" }}>🚀</div>
          <p style={{ fontWeight: 600, color: "var(--text)" }}>No courses yet</p>
          <p style={{ fontSize: "0.9rem", marginBottom: "1.5rem" }}>Start a course to track your progress here.</p>
          <Link to="/" className="btn btn-primary">Browse Courses</Link>
        </div>
      ) : (
        <>
          {data.total_completed === 0 && (
            <div style={{
              background: "var(--surface-2)",
              border: "1px solid var(--border)",
              borderRadius: 10,
              padding: "1rem 1.25rem",
              marginBottom: "1.5rem",
              display: "flex", alignItems: "center", gap: "0.75rem",
              fontSize: "0.88rem", color: "var(--text-2)",
            }}>
              <span style={{ fontSize: "1.2rem" }}>💡</span>
              Open a topic and click <strong style={{ color: "var(--text)" }}>Mark as complete</strong> to start tracking your progress.
            </div>
          )}

          <div style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(340px, 1fr))",
            gap: "1rem",
          }}>
            {data.courses.map((c) => (
              <CourseCard key={c.course_id} data={c} />
            ))}
          </div>
        </>
      )}

      {/* Last activity */}
      {data.last_completed_at && (
        <p style={{ textAlign: "center", marginTop: "2.5rem", fontSize: "0.78rem", color: "var(--text-3)" }}>
          Last activity: {new Date(data.last_completed_at).toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })}
        </p>
      )}
    </div>
  );
}
