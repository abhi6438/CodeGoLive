import { useEffect, useState, useCallback } from "react";
import { useParams, Link } from "react-router-dom";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { Prism as SyntaxHighlighter } from "react-syntax-highlighter";
import { vscDarkPlus } from "react-syntax-highlighter/dist/esm/styles/prism";
import { api } from "../lib/api";
import { useAuth } from "../lib/AuthContext";
import QAThread from "../components/QAThread";

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

export default function TopicPage() {
  const { slug } = useParams();
  const { session } = useAuth();
  const [topic, setTopic] = useState(null);
  const [siblingTopics, setSiblingTopics] = useState([]);
  const [siblingProgress, setSiblingProgress] = useState({});
  const [questions, setQuestions] = useState([]);
  const [askTitle, setAskTitle] = useState("");
  const [askBody, setAskBody] = useState("");
  const [askTags, setAskTags] = useState("");

  const loadTopic = useCallback(() => {
    api.get(`/api/topics/${slug}`).then(setTopic);
  }, [slug]);

  const loadQuestions = useCallback(async () => {
    if (!topic) return;
    const qs = await api.get(`/api/questions?topic_id=${topic.id}`);
    const full = await Promise.all(qs.map((q) => api.get(`/api/questions/${q.id}`)));
    setQuestions(full);
  }, [topic]);

  useEffect(() => { loadTopic(); }, [loadTopic]);
  useEffect(() => { loadQuestions(); }, [loadQuestions]);

  // Load module siblings for sidebar
  useEffect(() => {
    if (!topic?.module_id) return;
    api.get(`/api/modules/${topic.module_id}/topics`).then((topics) => {
      setSiblingTopics(topics);
      if (session) {
        Promise.all(
          topics.map((t) =>
            api.get(`/api/topics/${t.slug}`).then((d) => ({ id: t.id, status: d.progress_status }))
          )
        ).then((results) => {
          const map = {};
          results.forEach(({ id, status }) => (map[id] = status));
          setSiblingProgress(map);
        });
      }
    });
  }, [topic?.module_id, session]);

  const markComplete = async () => {
    await api.post(`/api/topics/${slug}/progress`, { status: "completed" });
    loadTopic();
  };

  const askQuestion = async () => {
    if (!askTitle.trim() || !askBody.trim()) return;
    await api.post("/api/questions", {
      title: askTitle,
      body: askBody,
      topic_id: topic.id,
      tags: askTags.split(",").map((t) => t.trim()).filter(Boolean),
    });
    setAskTitle(""); setAskBody(""); setAskTags("");
    loadQuestions();
  };

  if (!topic) return (
    <div style={{ display: "flex", alignItems: "center", justifyContent: "center", height: "50vh", color: "var(--text-3)" }}>
      <div style={{ textAlign: "center" }}>
        <div style={{ fontSize: "2.5rem", marginBottom: "0.75rem", opacity: 0.25 }}>◌</div>
        Loading topic…
      </div>
    </div>
  );

  const isCompleted = topic.progress_status === "completed";
  const topicIdx = siblingTopics.findIndex((t) => t.id === topic.id);
  const prevTopic = topicIdx > 0 ? siblingTopics[topicIdx - 1] : null;
  const nextTopic = topicIdx < siblingTopics.length - 1 ? siblingTopics[topicIdx + 1] : null;

  return (
    <div style={{ minHeight: "calc(100vh - 64px)", paddingBottom: "5rem" }}>
      {/* ── Topic header banner ─────────────────────── */}
      <div className="topic-header-banner">
        <div className="container">
          <div className="topic-header-breadcrumb">
            <Link to="/course/sap-btp">Course</Link>
            <span className="breadcrumb-sep">/</span>
            {topic.module_id && (
              <>
                <Link to={`/modules/${topic.module_id}`}>Module {topic.module_number || ""}</Link>
                <span className="breadcrumb-sep">/</span>
              </>
            )}
            <span className="breadcrumb-current">{topic.title}</span>
          </div>

          <div className="topic-header-body">
            <div>
              <div className="topic-header-meta">
                <span className="badge badge-outline">Topic {topic.number}</span>
                {isCompleted && (
                  <span className="badge" style={{ background: "var(--success-light)", color: "var(--success)" }}>
                    ✓ Completed
                  </span>
                )}
              </div>
              <h1 className="topic-header-title">{topic.title}</h1>
              {topic.description && (
                <p className="topic-header-desc">{topic.description}</p>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* ── 2-column lesson layout ──────────────────── */}
      <div className="container">
        <div className="lesson-layout">
          {/* ── Main content ─────────── */}
          <main className="lesson-main">
            {/* Video */}
            {topic.video_url && (
              <div className="video-embed">
                <iframe
                  src={youtubeEmbedUrl(topic.video_url)}
                  title="Topic video"
                  allowFullScreen
                />
              </div>
            )}

            {/* Action buttons */}
            <div className="topic-actions">
              {topic.github_url && (
                <a className="btn btn-outline" href={topic.github_url} target="_blank" rel="noreferrer">
                  <svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M12 2C6.477 2 2 6.477 2 12c0 4.42 2.865 8.17 6.839 9.49.5.092.682-.217.682-.482 0-.237-.008-.866-.013-1.7-2.782.603-3.369-1.34-3.369-1.34-.454-1.156-1.11-1.462-1.11-1.462-.908-.62.069-.608.069-.608 1.003.07 1.531 1.03 1.531 1.03.892 1.529 2.341 1.087 2.91.831.092-.646.35-1.086.636-1.336-2.22-.253-4.555-1.11-4.555-4.943 0-1.091.39-1.984 1.029-2.683-.103-.253-.446-1.27.098-2.647 0 0 .84-.269 2.75 1.025A9.578 9.578 0 0 1 12 6.836c.85.004 1.705.115 2.504.337 1.909-1.294 2.747-1.025 2.747-1.025.546 1.377.202 2.394.1 2.647.64.699 1.028 1.592 1.028 2.683 0 3.842-2.339 4.687-4.566 4.935.359.309.678.919.678 1.852 0 1.336-.012 2.415-.012 2.743 0 .267.18.578.688.48C19.138 20.167 22 16.418 22 12c0-5.523-4.477-10-10-10z"/>
                  </svg>
                  View Code on GitHub
                </a>
              )}
              {session && (
                <button
                  className={"btn" + (isCompleted ? " btn-outline" : " btn-primary")}
                  onClick={markComplete}
                  disabled={isCompleted}
                  style={isCompleted ? { color: "var(--success)", borderColor: "var(--success)" } : {}}
                >
                  {isCompleted ? (
                    <>
                      <svg width="14" height="14" viewBox="0 0 12 12" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
                        <path d="M2 6l3 3 5-5" />
                      </svg>
                      Completed
                    </>
                  ) : "Mark Complete"}
                </button>
              )}
            </div>

            {/* Written content */}
            {topic.content_md && (
              <div className="markdown-body">
                <ReactMarkdown
                  remarkPlugins={[remarkGfm]}
                  components={{
                    code({ inline, className, children, ...props }) {
                      const lang = /language-(\w+)/.exec(className || "");
                      if (!inline) {
                        return <CodeBlock language={lang ? lang[1] : "text"}>{children}</CodeBlock>;
                      }
                      return (
                        <code style={{ background: "var(--card-bg)", border: "1px solid var(--border)", padding: "1px 6px", borderRadius: 4, fontFamily: "var(--mono)", fontSize: "0.85em" }} {...props}>
                          {children}
                        </code>
                      );
                    },
                    blockquote({ children }) {
                      return <div className="md-tip-box">{children}</div>;
                    },
                    h2({ children }) {
                      return <h2 className="md-section-heading">{children}</h2>;
                    },
                    table({ children }) {
                      return (
                        <div style={{ overflowX: "auto", marginBottom: "1.5rem" }}>
                          <table className="md-table">{children}</table>
                        </div>
                      );
                    },
                  }}
                >
                  {topic.content_md}
                </ReactMarkdown>
              </div>
            )}

            {topic.deliverable_note && (
              <div className="deliverable-card">
                <div className="deliverable-card-label">Deliverable</div>
                <p>{topic.deliverable_note}</p>
              </div>
            )}

            {/* Prev / Next navigation */}
            <div className="lesson-nav">
              {prevTopic ? (
                <Link to={`/course/sap-btp/${prevTopic.slug}`} className="lesson-nav-btn lesson-nav-btn--prev">
                  <span className="lesson-nav-dir">
                    <svg width="14" height="14" viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round">
                      <path d="M13 4l-6 6 6 6" />
                    </svg>
                    Previous
                  </span>
                  <span className="lesson-nav-title">{prevTopic.title}</span>
                </Link>
              ) : <div />}
              {nextTopic ? (
                <Link to={`/course/sap-btp/${nextTopic.slug}`} className="lesson-nav-btn lesson-nav-btn--next">
                  <span className="lesson-nav-dir">
                    Next
                    <svg width="14" height="14" viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round">
                      <path d="M5 10h10M12 6l4 4-4 4" />
                    </svg>
                  </span>
                  <span className="lesson-nav-title">{nextTopic.title}</span>
                </Link>
              ) : <div />}
            </div>

            {/* Q&A section */}
            <div className="qa-section-header">
              <h2 className="qa-section-title">
                Questions about this topic
                {questions.length > 0 && (
                  <span className="badge" style={{ marginLeft: "0.5rem", fontSize: "0.75rem" }}>{questions.length}</span>
                )}
              </h2>
              <p className="qa-section-sub">Ask anything related to this lesson — the community has your back.</p>
            </div>

            {session ? (
              <div className="card qa-ask-card">
                <input
                  type="text"
                  placeholder="Question title — be specific"
                  value={askTitle}
                  onChange={(e) => setAskTitle(e.target.value)}
                  style={{ marginBottom: "0.5rem" }}
                />
                <textarea
                  rows={3}
                  placeholder="Describe your question with context…"
                  value={askBody}
                  onChange={(e) => setAskBody(e.target.value)}
                  style={{ marginBottom: "0.5rem" }}
                />
                <input
                  type="text"
                  placeholder="Tags, comma separated (e.g. routing, crud)"
                  value={askTags}
                  onChange={(e) => setAskTags(e.target.value)}
                  style={{ marginBottom: "0.75rem" }}
                />
                <button className="btn btn-primary" onClick={askQuestion}>
                  Ask Question
                </button>
              </div>
            ) : (
              <div className="card" style={{ textAlign: "center", padding: "2rem" }}>
                <p style={{ color: "var(--text-2)", marginBottom: "1rem" }}>Sign in to ask a question about this topic.</p>
                <Link to="/login" className="btn btn-primary">Sign in</Link>
              </div>
            )}

            {questions.map((q) => (
              <QAThread key={q.id} question={q} onRefresh={loadQuestions} />
            ))}
          </main>
        </div>
      </div>
    </div>
  );
}
