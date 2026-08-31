import { useEffect, useState, useCallback, useRef } from "react";
import { useParams, useNavigate, Link } from "react-router-dom";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { Prism as SyntaxHighlighter } from "react-syntax-highlighter";
import { vscDarkPlus } from "react-syntax-highlighter/dist/esm/styles/prism";
import { api } from "../lib/api";
import { useAuth } from "../lib/AuthContext";
import { getCourse } from "../lib/courses";
import QAThread from "../components/QAThread";
import { useMobileBar } from "../lib/MobileBarContext";

/* ─── helpers ─────────────────────────────────────────────── */
function youtubeEmbedUrl(url) {
  if (!url) return null;
  const match = url.match(/(?:youtu\.be\/|v=)([\w-]+)/);
  return match ? `https://www.youtube.com/embed/${match[1]}` : url;
}

function CodeBlock({ language, children }) {
  const [copied, setCopied] = useState(false);
  const code = String(children).replace(/\n$/, "");
  const handleCopy = () => {
    navigator.clipboard.writeText(code).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  };
  return (
    <div className="code-block-wrapper">
      <div className="code-block-header">
        <span className="code-lang-badge">{language || "code"}</span>
        <button className={`code-copy-btn${copied ? " copied" : ""}`} onClick={handleCopy}>
          {copied ? "✓ Copied!" : "Copy"}
        </button>
      </div>
      <SyntaxHighlighter
        language={language || "text"}
        PreTag="pre"
        style={vscDarkPlus}
        customStyle={{ margin: 0, borderRadius: "0 0 8px 8px", fontSize: "0.84rem", lineHeight: 1.65 }}
      >
        {code}
      </SyntaxHighlighter>
    </div>
  );
}

const mdComponents = {
  code({ inline, className, children, ...props }) {
    const match = /language-(\w+)/.exec(className || "");
    const language = match ? match[1] : "";
    if (!inline) {
      return <CodeBlock language={language}>{children}</CodeBlock>;
    }
    return <code className="inline-code" {...props}>{children}</code>;
  },
};

/* ─── status dot ───────────────────────────────────────────── */
function StatusDot({ status }) {
  if (status === "completed")
    return (
      <span className="status-dot status-dot--done">
        <svg width="9" height="9" viewBox="0 0 12 12" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
          <path d="M2 6l3 3 5-5" />
        </svg>
      </span>
    );
  if (status === "in_progress")
    return (
      <span className="status-dot status-dot--progress">
        <span style={{ width: 6, height: 6, borderRadius: "50%", background: "currentColor", display: "block" }} />
      </span>
    );
  return <span className="status-dot status-dot--empty" />;
}

/* ─── WorkspaceSidebar ─────────────────────────────────────── */
function WorkspaceSidebar({ courseId, modules, topicsMap, progress, activeSlug, onTopicClick, onClose }) {
  const [expanded, setExpanded] = useState(() => {
    // auto-open the module containing the active topic
    const activeModule = modules.find((m) =>
      (topicsMap[m.id] || []).some((t) => t.slug === activeSlug)
    );
    return activeModule ? { [activeModule.id]: true } : { [modules[0]?.id]: true };
  });

  // when active topic changes, ensure its module is open
  useEffect(() => {
    const mod = modules.find((m) =>
      (topicsMap[m.id] || []).some((t) => t.slug === activeSlug)
    );
    if (mod) setExpanded((prev) => ({ ...prev, [mod.id]: true }));
  }, [activeSlug, modules, topicsMap]);

  const toggle = (id) =>
    setExpanded((prev) => ({ ...prev, [id]: !prev[id] }));

  // progress per module
  const moduleProgress = (moduleId) => {
    const topics = topicsMap[moduleId] || [];
    if (!topics.length) return { done: 0, total: 0, pct: 0 };
    const done = topics.filter((t) => progress[t.id] === "completed").length;
    return { done, total: topics.length, pct: Math.round((done / topics.length) * 100) };
  };

  return (
    <aside className="ws-sidebar">
      <div className="ws-sidebar-header">
        <Link to="/dashboard" className="ws-back-link">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <polyline points="15 18 9 12 15 6" />
          </svg>
          All Courses
        </Link>
        {onClose && (
          <button className="ws-sidebar-close" onClick={onClose} aria-label="Close sidebar">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
              <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </button>
        )}
      </div>

      <nav className="ws-sidebar-nav">
        {modules.map((mod, idx) => {
          const topics = topicsMap[mod.id] || [];
          const isOpen = !!expanded[mod.id];
          const { done, total, pct } = moduleProgress(mod.id);
          const COLORS = ["#6366F1","#8B5CF6","#EC4899","#F59E0B","#10B981","#3B82F6"];
          const color = COLORS[idx % COLORS.length];

          return (
            <div key={mod.id} className={`ws-module${isOpen ? " open" : ""}`}>
              <button className="ws-module-header" onClick={() => toggle(mod.id)}>
                <span className="ws-module-thumb" style={{ background: color }}>
                  {idx + 1}
                </span>
                <span className="ws-module-info">
                  <span className="ws-module-title">{mod.title}</span>
                  <span className="ws-module-sub">{done}/{total} topics</span>
                </span>
                <span className="ws-module-chevron">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                    <polyline points="6 9 12 15 18 9" />
                  </svg>
                </span>
              </button>

              {pct > 0 && (
                <div className="ws-module-progress-bar">
                  <div className="ws-module-progress-fill" style={{ width: `${pct}%`, background: color }} />
                </div>
              )}

              {isOpen && topics.length > 0 && (
                <ul className="ws-topic-list">
                  {topics.map((t, ti) => {
                    const isActive = t.slug === activeSlug;
                    const st = progress[t.id] || "not_started";
                    return (
                      <li key={t.id}>
                        <button
                          className={`ws-topic-btn${isActive ? " active" : ""}${st === "completed" ? " done" : ""}`}
                          onClick={() => {
                            onTopicClick(t.slug);
                            if (onClose) onClose(); // close drawer on mobile
                          }}
                        >
                          <span className="ws-topic-num">{ti + 1}</span>
                          <span className="ws-topic-title">{t.title}</span>
                          <StatusDot status={st} />
                        </button>
                      </li>
                    );
                  })}
                </ul>
              )}
            </div>
          );
        })}
      </nav>
    </aside>
  );
}

/* ─── TopicContent ─────────────────────────────────────────── */
function TopicContent({ topic, onComplete, onPrev, onNext, prevTopic, nextTopic, session }) {
  const [questions, setQuestions] = useState([]);
  const [askTitle, setAskTitle] = useState("");
  const [askBody, setAskBody] = useState("");
  const [askTags, setAskTags] = useState("");
  const [completing, setCompleting] = useState(false);

  const loadQuestions = useCallback(async () => {
    if (!topic) return;
    const qs = await api.get(`/api/questions?topic_id=${topic.id}`);
    const full = await Promise.all(qs.map((q) => api.get(`/api/questions/${q.id}`)));
    setQuestions(full);
  }, [topic]);

  useEffect(() => {
    setQuestions([]);
    loadQuestions();
  }, [loadQuestions]);

  const handleComplete = async () => {
    setCompleting(true);
    try {
      const result = await api.post(`/api/topics/${topic.slug}/complete`, {});
      onComplete && onComplete(topic.id, result?.course_completed, result?.course_id);
    } catch (e) {
      console.error(e);
    } finally {
      setCompleting(false);
    }
  };

  const handleAsk = async (e) => {
    e.preventDefault();
    if (!askTitle.trim()) return;
    await api.post("/api/questions", {
      title: askTitle,
      body: askBody,
      topic_id: topic.id,
      tags: askTags.split(",").map((s) => s.trim()).filter(Boolean),
    });
    setAskTitle(""); setAskBody(""); setAskTags("");
    loadQuestions();
  };

  if (!topic) return (
    <div className="ws-content-loading">
      <div className="ws-content-spinner" />
      <p>Loading topic…</p>
    </div>
  );

  const embedUrl = youtubeEmbedUrl(topic.video_url);
  const isDone = topic.progress_status === "completed";

  return (
    <article className="ws-content">
      {/* Topic header */}
      <header className="ws-topic-header">
        <h1 className="ws-content-title">{topic.title}</h1>
        <div className="ws-topic-meta-row">
          {topic.estimated_minutes && (
            <span className="ws-topic-meta-item">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>
              </svg>
              {topic.estimated_minutes} min
            </span>
          )}
          {isDone && (
            <span className="ws-topic-done-badge">
              <svg width="11" height="11" viewBox="0 0 12 12" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
                <path d="M2 6l3 3 5-5" />
              </svg>
              Completed
            </span>
          )}
        </div>
      </header>

      {/* Video */}
      {embedUrl && (
        <div className="ws-video-wrap">
          <iframe
            src={embedUrl}
            title={topic.title}
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            allowFullScreen
          />
        </div>
      )}

      {/* Markdown content */}
      {topic.content_md && (
        <div className="prose ws-prose">
          <ReactMarkdown remarkPlugins={[remarkGfm]} components={mdComponents}>
            {topic.content_md}
          </ReactMarkdown>
        </div>
      )}

      {/* Deliverable */}
      {topic.deliverable && (
        <div className="ws-deliverable">
          <div className="ws-deliverable-label">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
              <polyline points="16 16 12 12 8 16"/><line x1="12" y1="12" x2="12" y2="21"/>
              <path d="M20.39 18.39A5 5 0 0 0 18 9h-1.26A8 8 0 1 0 3 16.3"/>
            </svg>
            Deliverable
          </div>
          <p className="ws-deliverable-text">{topic.deliverable}</p>
        </div>
      )}

      {/* Mark complete + nav */}
      <div className="ws-lesson-nav">
        <div className="ws-lesson-nav-side">
          {prevTopic ? (
            <button className="btn ws-nav-btn" onClick={() => onPrev(prevTopic.slug)}>
              ← {prevTopic.title}
            </button>
          ) : <span />}
        </div>
        <div className="ws-lesson-nav-center">
          {session && !isDone && (
            <button className="btn btn-primary ws-complete-btn" onClick={handleComplete} disabled={completing}>
              {completing ? "Saving…" : "Mark as complete ✓"}
            </button>
          )}
        </div>
        <div className="ws-lesson-nav-side ws-lesson-nav-right">
          {nextTopic ? (
            <button className="btn ws-nav-btn" onClick={() => onNext(nextTopic.slug)}>
              {nextTopic.title} →
            </button>
          ) : <span />}
        </div>
      </div>

      {/* Q&A — visible to all; ask form requires login */}
      <section className="ws-qa-section">
        <div className="ws-qa-header">
          <div className="ws-qa-header-left">
            <svg className="ws-qa-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
            </svg>
            <h2 className="ws-qa-title">Discussion</h2>
            {questions.length > 0 && (
              <span className="ws-qa-count">{questions.length}</span>
            )}
          </div>
        </div>

        {session ? (
          <form className="ws-ask-form" onSubmit={handleAsk}>
            <div className="ws-ask-trigger">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="ws-ask-trigger-icon">
                <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="16"/><line x1="8" y1="12" x2="16" y2="12"/>
              </svg>
              <input
                className="ws-ask-input"
                placeholder="Ask a question about this topic…"
                value={askTitle}
                onChange={(e) => setAskTitle(e.target.value)}
              />
            </div>
            {askTitle && (
              <div className="ws-ask-expanded">
                <textarea
                  className="ws-ask-body"
                  rows={3}
                  placeholder="Add more context (optional)"
                  value={askBody}
                  onChange={(e) => setAskBody(e.target.value)}
                />
                <div className="ws-ask-footer">
                  <input
                    className="ws-ask-tags-input"
                    placeholder="Tags: cap, fiori, btp…"
                    value={askTags}
                    onChange={(e) => setAskTags(e.target.value)}
                  />
                  <button type="submit" className="btn btn-primary ws-ask-submit">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                      <line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/>
                    </svg>
                    Post Question
                  </button>
                </div>
              </div>
            )}
          </form>
        ) : (
          <div className="ws-qa-login-prompt">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
            </svg>
            <span>
              <a href="/login" className="ws-qa-login-link">Sign in</a> to ask a question or join the discussion.
            </span>
          </div>
        )}

        <div className="ws-qa-list">
          {questions.length === 0 ? (
            <div className="ws-qa-empty">
              <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
              </svg>
              <p className="ws-qa-empty-title">No questions yet</p>
              <p className="ws-qa-empty-sub">Be the first to ask — your question might help others too.</p>
            </div>
          ) : (
            questions.map((q) => (
              <QAThread
                key={q.id}
                question={q}
                session={session}
                onUpdate={loadQuestions}
              />
            ))
          )}
        </div>
      </section>
    </article>
  );
}

/* ─── CourseWorkspace (main) ───────────────────────────────── */
export default function CourseWorkspace() {
  const { courseId, topicSlug } = useParams();
  const navigate = useNavigate();
  const { session } = useAuth();
  const course = getCourse(courseId);

  const [modules, setModules] = useState([]);
  const [topicsMap, setTopicsMap] = useState({}); // moduleId → topics[]
  const [progress, setProgress] = useState({});   // topicId → status
  const [completedCourse, setCompletedCourse] = useState(null); // {courseId} when course just finished
  const [topic, setTopic] = useState(null);
  const [loadingModules, setLoadingModules] = useState(true);
  const [loadingTopic, setLoadingTopic] = useState(false);
  const [sidebarOpen, setSidebarOpen] = useState(false); // mobile drawer
  const { setBar } = useMobileBar() || {};

  // Register course mobile bar in topbar
  useEffect(() => {
    if (!setBar) return;
    setBar({ title: course?.title || "Course", backTo: "/", onToggle: () => setSidebarOpen(true) });
    return () => setBar(null);
  }, [course?.title, setBar]);

  // ── load modules + topics once ──────────────────────────────
  useEffect(() => {
    if (!course) return;
    setLoadingModules(true);
    api.get(`/api/modules?course_id=${courseId}`).then(async (mods) => {
      setModules(mods);
      const map = {};
      await Promise.all(
        mods.map((m) =>
          api.get(`/api/modules/${m.id}/topics`).then((ts) => {
            map[m.id] = ts;
          })
        )
      );
      setTopicsMap(map);

      // If no slug in URL, navigate to first topic
      if (!topicSlug && mods.length > 0) {
        const firstTopics = map[mods[0].id] || [];
        if (firstTopics.length > 0) {
          navigate(`/course/${courseId}/${firstTopics[0].slug}`, { replace: true });
        }
      }
    }).finally(() => setLoadingModules(false));
  }, [courseId]); // eslint-disable-line

  // ── load progress when logged in ───────────────────────────
  useEffect(() => {
    if (!session || Object.keys(topicsMap).length === 0) return;
    const allTopics = Object.values(topicsMap).flat();
    Promise.all(
      allTopics.map((t) =>
        api.get(`/api/topics/${t.slug}`)
          .then((d) => ({ id: t.id, status: d.progress_status }))
          .catch(() => ({ id: t.id, status: "not_started" }))
      )
    ).then((results) => {
      const p = {};
      results.forEach(({ id, status }) => { p[id] = status; });
      setProgress(p);
    });
  }, [session, topicsMap]);

  // ── load topic content when slug changes ────────────────────
  useEffect(() => {
    if (!topicSlug) return;
    setLoadingTopic(true);
    setTopic(null);
    api.get(`/api/topics/${topicSlug}`)
      .then((t) => {
        setTopic(t);
        // sync progress for this topic
        if (t.progress_status) {
          setProgress((prev) => ({ ...prev, [t.id]: t.progress_status }));
        }
      })
      .finally(() => setLoadingTopic(false));
  }, [topicSlug]);

  // ── helpers: prev/next topic across all modules ─────────────
  const allTopics = modules.flatMap((m) => topicsMap[m.id] || []);
  const currentIdx = allTopics.findIndex((t) => t.slug === topicSlug);
  const prevTopic = currentIdx > 0 ? allTopics[currentIdx - 1] : null;
  const nextTopic = currentIdx < allTopics.length - 1 ? allTopics[currentIdx + 1] : null;

  const navigateToTopic = (slug) => {
    navigate(`/course/${courseId}/${slug}`);
  };

  const handleComplete = (topicId, courseCompleted, courseId) => {
    setProgress((prev) => ({ ...prev, [topicId]: "completed" }));
    setTopic((prev) => prev ? { ...prev, progress_status: "completed" } : prev);
    if (courseCompleted && courseId) setCompletedCourse(courseId);
  };

  if (!course) {
    return (
      <div style={{ textAlign: "center", padding: "4rem 1rem" }}>
        <h2>Course not found</h2>
        <Link to="/dashboard" className="btn btn-primary" style={{ marginTop: "1rem" }}>
          Back to Dashboard
        </Link>
      </div>
    );
  }

  return (
    <div className="workspace">
      {/* Mobile header bar */}
      <div className="ws-mobile-bar">
        <button className="ws-hamburger" onClick={() => setSidebarOpen(true)} aria-label="Open sidebar">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
            <line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/>
          </svg>
        </button>
        <span className="ws-mobile-title">{topic?.title || course.title}</span>
      </div>

      {/* Overlay for mobile drawer */}
      {sidebarOpen && (
        <div className="ws-overlay" onClick={() => setSidebarOpen(false)} />
      )}


      {/* Course completion banner */}
      {completedCourse && (
        <div style={{
          position: "fixed", inset: 0, zIndex: 9999,
          background: "rgba(0,0,0,0.55)", display: "flex", alignItems: "center", justifyContent: "center",
          padding: "1rem",
        }} onClick={() => setCompletedCourse(null)}>
          <div style={{
            background: "var(--surface)", border: "1px solid var(--border)", borderRadius: 18,
            padding: "2.5rem 2rem", maxWidth: 420, width: "100%", textAlign: "center",
            boxShadow: "0 24px 80px rgba(0,0,0,0.3)",
          }} onClick={(e) => e.stopPropagation()}>
            <div style={{ fontSize: "3.5rem", marginBottom: "0.75rem" }}>🎓</div>
            <h2 style={{ margin: "0 0 0.5rem", fontSize: "1.4rem", fontWeight: 800, color: "var(--text)" }}>
              Course Complete!
            </h2>
            <p style={{ color: "var(--text-2)", marginBottom: "1.5rem", fontSize: "0.9rem" }}>
              You've completed all topics in this course. Your certificate has been issued!
            </p>
            <div style={{ display: "flex", gap: "0.75rem", justifyContent: "center", flexWrap: "wrap" }}>
              <Link to="/certificate" className="btn btn-primary" onClick={() => setCompletedCourse(null)}>
                View Certificate →
              </Link>
              <button className="btn btn-outline" onClick={() => setCompletedCourse(null)}>
                Keep Learning
              </button>
            </div>
          </div>
        </div>
      )}

      <div className="workspace-inner">
        {/* Left sidebar */}
        <div className={`ws-sidebar-wrap${sidebarOpen ? " open" : ""}`}>
          {loadingModules ? (
            <aside className="ws-sidebar ws-sidebar--loading">
              <div className="ws-content-spinner" />
            </aside>
          ) : (
            <WorkspaceSidebar
              courseId={courseId}
              modules={modules}
              topicsMap={topicsMap}
              progress={progress}
              activeSlug={topicSlug}
              onTopicClick={navigateToTopic}
              onClose={() => setSidebarOpen(false)}
            />
          )}
        </div>

        {/* Right content panel */}
        <main className="ws-main">
          {loadingTopic ? (
            <div className="ws-content-loading">
              <div className="ws-content-spinner" />
              <p>Loading…</p>
            </div>
          ) : (
            <TopicContent
              topic={topic}
              session={session}
              onComplete={handleComplete}
              onPrev={navigateToTopic}
              onNext={navigateToTopic}
              prevTopic={prevTopic}
              nextTopic={nextTopic}
            />
          )}
        </main>
      </div>
    </div>
  );
}
