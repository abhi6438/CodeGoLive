import { useEffect, useState, useCallback } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { useAuth } from "../lib/AuthContext";
import { api } from "../lib/api";
import QAThread from "../components/QAThread";
import SEO from "../components/SEO";

export default function Community() {
  const { session } = useAuth();
  const [searchParams] = useSearchParams();
  useEffect(() => { if (searchParams.get("ask") === "1") setShowForm(true); }, []);
  const [questions, setQuestions] = useState([]);
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [tags, setTags] = useState("");
  const [loading, setLoading] = useState(true);
  const [asking, setAsking] = useState(false);
  const [showForm, setShowForm] = useState(false);
  const [postFeedback, setPostFeedback] = useState(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const qs = await api.get("/api/questions?general_only=true");
      const full = await Promise.all(qs.map((q) => api.get(`/api/questions/${q.id}`)));
      setQuestions(full);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  const ask = async () => {
    if (!title.trim() || !body.trim()) return;
    setAsking(true);
    setPostFeedback(null);
    try {
      const result = await api.post("/api/questions", {
        title, body, topic_id: null,
        tags: tags.split(",").map((t) => t.trim()).filter(Boolean),
      });
      setTitle(""); setBody(""); setTags("");
      setShowForm(false);
      load();
      if (result?.status === "approved") {
        setPostFeedback({ type: "success", message: "✓ Question posted — visible to the community now." });
      } else {
        setPostFeedback({ type: "pending", message: "✓ Question sent for review — a moderator will approve it shortly." });
      }
    } catch (err) {
      const raw = err?.detail || err?.message || "";
      const msg = raw && raw.length < 120 && !raw.startsWith("{") && !raw.startsWith("'") ? raw : "Could not post your question. Please try again.";
      setPostFeedback({ type: "error", message: msg });
    } finally {
      setAsking(false);
    }
  };

  const answeredCount = questions.filter((q) => (q.answers || []).length > 0).length;
  const unanswered = questions.filter((q) => (q.answers || []).length === 0);

  return (
    <div className="comm-page">
      <SEO title="Community" description="Ask questions, share solutions, and learn with the CodeGoLive developer community." />
      {/* ── Hero ───────────────────────────────────────── */}
      <div className="comm-hero">
        <div className="comm-hero-inner container">
          <div className="comm-hero-text">
            <span className="comm-eyebrow">Community</span>
            <h1 className="comm-title">Ask Anything</h1>
            <p className="comm-subtitle">
              Got a doubt not tied to one specific topic? Ask here — the whole community can help.
            </p>
          </div>
          {session && (
            <button
              className={`comm-ask-btn${showForm ? " comm-ask-btn--cancel" : ""}`}
              onClick={() => { setShowForm((f) => !f); setPostFeedback(null); }}
            >
              {showForm ? (
                <>
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                  Cancel
                </>
              ) : (
                <>
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                  Ask a Question
                </>
              )}
            </button>
          )}
        </div>

        {/* Stats row */}
        <div className="comm-stats container">
          <div className="comm-stat">
            <span className="comm-stat-num">{questions.length}</span>
            <span className="comm-stat-label">Questions asked</span>
          </div>
          <div className="comm-stat-divider" />
          <div className="comm-stat">
            <span className="comm-stat-num">{answeredCount}</span>
            <span className="comm-stat-label">Answered</span>
          </div>
          <div className="comm-stat-divider" />
          <div className="comm-stat">
            <span className="comm-stat-num comm-stat-num--warn">{unanswered.length}</span>
            <span className="comm-stat-label">Need help</span>
          </div>
        </div>
      </div>

      {/* ── Body ───────────────────────────────────────── */}
      <div className="container comm-body">

        {/* Post feedback banner */}
        {postFeedback && (
          <div className={`comm-feedback comm-feedback--${postFeedback.type}`}>
            <span>{postFeedback.message}</span>
            <button onClick={() => setPostFeedback(null)}>×</button>
          </div>
        )}

        {/* Ask form */}
        {session && showForm && (
          <div className="comm-ask-card">
            <div className="comm-ask-card-header">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
              </svg>
              <h3>Ask the Community</h3>
            </div>
            <div className="comm-ask-fields">
              <input
                className="comm-field"
                type="text"
                placeholder="What's your question? Be specific."
                value={title}
                onChange={(e) => setTitle(e.target.value)}
              />
              <textarea
                className="comm-field comm-field--area"
                rows={4}
                placeholder="Add details, context, or what you've already tried…"
                value={body}
                onChange={(e) => setBody(e.target.value)}
              />
              <div className="comm-ask-row">
                <input
                  className="comm-field comm-field--tags"
                  type="text"
                  placeholder="Tags: cap, odata, ui5…"
                  value={tags}
                  onChange={(e) => setTags(e.target.value)}
                />
                <button className="btn btn-primary comm-post-btn" onClick={ask} disabled={asking}>
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                    <line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/>
                  </svg>
                  {asking ? "Posting…" : "Post Question"}
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Not signed in */}
        {!session && (
          <div className="comm-signin-prompt">
            <div className="comm-signin-icon">
              <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
              </svg>
            </div>
            <p>Sign in to ask questions and join the conversation.</p>
            <Link to="/login" className="btn btn-primary">Sign in to ask</Link>
          </div>
        )}

        {/* Unanswered nudge */}
        {unanswered.length > 0 && (
          <div className="comm-unanswered">
            <div className="comm-unanswered-hd">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round">
                <circle cx="12" cy="12" r="10"/><path d="M12 8v4m0 4h.01"/>
              </svg>
              {unanswered.length} unanswered question{unanswered.length > 1 ? "s" : ""} — can you help?
            </div>
            <ul className="comm-unanswered-list">
              {unanswered.slice(0, 3).map((q) => (
                <li key={q.id}>{q.title}</li>
              ))}
            </ul>
          </div>
        )}

        {/* Question list */}
        {loading ? (
          <div className="comm-skeleton-list">
            {[1, 2, 3].map((i) => (
              <div key={i} className="comm-skeleton" style={{ animationDelay: `${i * 0.12}s` }} />
            ))}
          </div>
        ) : questions.length === 0 ? (
          <div className="comm-empty">
            <div className="comm-empty-icon">
              <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
              </svg>
            </div>
            <p className="comm-empty-title">No questions yet</p>
            <p className="comm-empty-sub">Be the first to ask — your question might help others too.</p>
            {session && (
              <button className="btn btn-primary" style={{ marginTop: "1.25rem" }} onClick={() => setShowForm(true)}>
                Ask the first question
              </button>
            )}
          </div>
        ) : (
          <div className="comm-qa-list">
            {questions.map((q) => <QAThread key={q.id} question={q} onRefresh={load} />)}
          </div>
        )}
      </div>
    </div>
  );
}
