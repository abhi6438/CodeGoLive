import { useEffect, useState, useCallback } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { useAuth } from "../lib/AuthContext";
import { api } from "../lib/api";
import SEO from "../components/SEO";

/* ─── helpers ─── */
function timeAgo(iso) {
  const d = new Date(iso);
  const s = Math.floor((Date.now() - d) / 1000);
  if (s < 60) return "just now";
  if (s < 3600) return `${Math.floor(s / 60)}m ago`;
  if (s < 86400) return `${Math.floor(s / 3600)}h ago`;
  if (s < 604800) return `${Math.floor(s / 86400)}d ago`;
  return d.toLocaleDateString("en-US", { month: "short", day: "numeric" });
}

function Skel({ h = 16, w = "100%", r = 6, mb = 0 }) {
  return <div className="cp-skel" style={{ height: h, width: w, borderRadius: r, marginBottom: mb }} />;
}

/* ─── QuestionCard ─── */
function QuestionCard({ q, expanded, onExpand, onRefresh, session }) {
  const [detail, setDetail] = useState(null);
  const [loadingDetail, setLoadingDetail] = useState(false);
  const [answerBody, setAnswerBody] = useState("");
  const [posting, setPosting] = useState(false);
  const [feedback, setFeedback] = useState(null);
  const [deleting, setDeleting] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);

  useEffect(() => {
    if (!expanded) return;
    if (detail) return;
    setLoadingDetail(true);
    api.get(`/api/questions/${q.id}`)
      .then(setDetail)
      .catch(() => setDetail(null))
      .finally(() => setLoadingDetail(false));
  }, [expanded, q.id]);

  const answerCount = q.answers ? q.answers.length : 0;
  const tags = q.question_tags?.map((t) => t.tags?.name).filter(Boolean) || [];
  const author = q.profiles?.display_name || "Anonymous";

  const postAnswer = async () => {
    if (!answerBody.trim()) return;
    setPosting(true);
    setFeedback(null);
    try {
      await api.post(`/api/questions/${q.id}/answers`, { body: answerBody });
      setAnswerBody("");
      const fresh = await api.get(`/api/questions/${q.id}`);
      setDetail(fresh);
      onRefresh?.();
      setFeedback({ type: "success", text: "Answer posted!" });
    } catch (err) {
      const raw = err?.detail || err?.message || "";
      const msg = raw && raw.length < 120 && !raw.startsWith("{") ? raw : "Could not post answer. Try again.";
      setFeedback({ type: "error", text: msg });
    } finally {
      setPosting(false);
    }
  };

  const deleteQuestion = async (e) => {
    e.stopPropagation();
    if (!confirmDelete) { setConfirmDelete(true); return; }
    setDeleting(true);
    try {
      await api.del(`/api/questions/${q.id}`);
      onRefresh?.();
    } catch {
      setFeedback({ type: "error", text: "Could not delete. Try again." });
      setConfirmDelete(false);
    } finally {
      setDeleting(false);
    }
  };

  return (
    <div className={`cp-qcard${expanded ? " cp-qcard--open" : ""}`}>
      <div className="cp-qcard-top" onClick={() => onExpand(expanded ? null : q.id)}>
        <div className="cp-qcard-meta-row">
          <div className="cp-qcard-avatar">{author.charAt(0).toUpperCase()}</div>
          <span className="cp-qcard-author">{author}</span>
          <span className="cp-qcard-dot">·</span>
          <span className="cp-qcard-time">{timeAgo(q.created_at)}</span>
          {answerCount === 0 && <span className="cp-badge cp-badge--unanswered">Unanswered</span>}
          {answerCount > 0 && <span className="cp-badge cp-badge--answered">{answerCount} answer{answerCount !== 1 ? "s" : ""}</span>}
        </div>
        <h3 className="cp-qcard-title">{q.title}</h3>
        {tags.length > 0 && (
          <div className="cp-tag-row">
            {tags.map((t) => <span key={t} className="cp-tag">{t}</span>)}
          </div>
        )}
        <div className="cp-qcard-chevron">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            {expanded ? <polyline points="18 15 12 9 6 15" /> : <polyline points="6 9 12 15 18 9" />}
          </svg>
        </div>
        {session?.user?.id === q.user_id && (
          <button
            className={`cp-delete-btn${confirmDelete ? " cp-delete-btn--confirm" : ""}`}
            onClick={deleteQuestion}
            disabled={deleting}
            title={confirmDelete ? "Click again to confirm" : "Delete question"}
          >
            {deleting ? "…" : confirmDelete ? "Confirm?" : (
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
                <polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6m4-6v6"/><path d="M9 6V4h6v2"/>
              </svg>
            )}
          </button>
        )}
      </div>

      {expanded && (
        <div className="cp-qcard-body">
          {loadingDetail ? (
            <div className="cp-detail-skel">
              <Skel h={14} w="90%" mb={8} />
              <Skel h={14} w="75%" mb={8} />
              <Skel h={14} w="60%" />
            </div>
          ) : detail ? (
            <>
              <p className="cp-qbody">{detail.body}</p>
              {detail.answers && detail.answers.length > 0 && (
                <div className="cp-answers">
                  <div className="cp-answers-hd">{detail.answers.length} Answer{detail.answers.length !== 1 ? "s" : ""}</div>
                  {detail.answers.map((a) => (
                    <div key={a.id} className="cp-answer">
                      <div className="cp-answer-meta">
                        <div className="cp-qcard-avatar cp-qcard-avatar--sm">{(a.profiles?.display_name || "A").charAt(0).toUpperCase()}</div>
                        <span className="cp-answer-author">{a.profiles?.display_name || "Anonymous"}</span>
                        <span className="cp-qcard-dot">·</span>
                        <span className="cp-qcard-time">{timeAgo(a.created_at)}</span>
                        {a.is_accepted && <span className="cp-badge cp-badge--accepted">✓ Accepted</span>}
                      </div>
                      <p className="cp-answer-body">{a.body}</p>
                    </div>
                  ))}
                </div>
              )}
              {session ? (
                <div className="cp-answer-form">
                  <div className="cp-answers-hd">Your Answer</div>
                  {feedback && (
                    <div className={`cp-inline-feedback cp-inline-feedback--${feedback.type}`}>{feedback.text}</div>
                  )}
                  <textarea
                    className="cp-field cp-field--area"
                    rows={3}
                    placeholder="Write your answer…"
                    value={answerBody}
                    onChange={(e) => setAnswerBody(e.target.value)}
                  />
                  <button className="btn btn-primary cp-post-ans-btn" onClick={postAnswer} disabled={posting}>
                    {posting ? "Posting…" : "Post Answer"}
                  </button>
                </div>
              ) : (
                <div className="cp-signin-nudge">
                  <Link to="/login">Sign in</Link> to post an answer.
                </div>
              )}
            </>
          ) : (
            <p className="cp-error-inline">Could not load details. Try again.</p>
          )}
        </div>
      )}
    </div>
  );
}

/* ─── AskForm ─── */
function AskForm({ onPosted, onCancel }) {
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [tags, setTags] = useState("");
  const [asking, setAsking] = useState(false);
  const [err, setErr] = useState(null);

  const submit = async () => {
    if (!title.trim() || !body.trim()) { setErr("Title and details are required."); return; }
    setAsking(true); setErr(null);
    try {
      const result = await api.post("/api/questions", {
        title, body, topic_id: null,
        tags: tags.split(",").map((t) => t.trim()).filter(Boolean),
      });
      onPosted?.(result?.status);
    } catch (e) {
      const raw = e?.detail || e?.message || "";
      setErr(raw && raw.length < 120 && !raw.startsWith("{") ? raw : "Could not post question. Please try again.");
    } finally {
      setAsking(false);
    }
  };

  return (
    <div className="cp-ask-card">
      <div className="cp-ask-card-hd">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
        </svg>
        <span>Ask the Community</span>
        <button className="cp-ask-close" onClick={onCancel}>×</button>
      </div>
      {err && <div className="cp-inline-feedback cp-inline-feedback--error">{err}</div>}
      <div className="cp-ask-fields">
        <input className="cp-field" placeholder="What's your question? Be specific." value={title} onChange={(e) => setTitle(e.target.value)} />
        <textarea className="cp-field cp-field--area" rows={3} placeholder="Add details, context, or what you've already tried…" value={body} onChange={(e) => setBody(e.target.value)} />
        <div className="cp-ask-row">
          <input className="cp-field cp-field--tags" placeholder="Tags: cap, odata, ui5…" value={tags} onChange={(e) => setTags(e.target.value)} />
          <button className="btn btn-primary" onClick={submit} disabled={asking}>{asking ? "Posting…" : "Post Question"}</button>
        </div>
      </div>
    </div>
  );
}

/* ─── Sidebar cards ─── */
function PopularTagsCard({ tags, loading }) {
  return (
    <div className="cp-sidebar-card">
      <div className="cp-sidebar-card-hd">Popular Tags</div>
      {loading ? (
        <div className="cp-sidebar-skel">
          {[80, 60, 90, 55, 70].map((w, i) => <Skel key={i} h={24} w={`${w}%`} r={12} mb={6} />)}
        </div>
      ) : tags.length === 0 ? (
        <p className="cp-sidebar-empty">No tags yet.</p>
      ) : (
        <div className="cp-tag-cloud">
          {tags.map((t) => (
            <span key={t.id || t.name} className="cp-tag cp-tag--lg">
              {t.name}
              {t.usage_count > 0 && <span className="cp-tag-count">{t.usage_count}</span>}
            </span>
          ))}
        </div>
      )}
    </div>
  );
}

function CommStatsCard({ stats, loading }) {
  return (
    <div className="cp-sidebar-card">
      <div className="cp-sidebar-card-hd">Community Stats</div>
      {loading ? (
        <div className="cp-sidebar-skel">
          {[1, 2, 3].map((i) => <Skel key={i} h={40} w="100%" r={6} mb={8} />)}
        </div>
      ) : (
        <div className="cp-stats-grid">
          <div className="cp-stat-item">
            <span className="cp-stat-num">{stats.question_count ?? "—"}</span>
            <span className="cp-stat-lbl">Questions</span>
          </div>
          <div className="cp-stat-item">
            <span className="cp-stat-num">{stats.answer_count ?? "—"}</span>
            <span className="cp-stat-lbl">Answers</span>
          </div>
          <div className="cp-stat-item">
            <span className="cp-stat-num">{stats.member_count ?? "—"}</span>
            <span className="cp-stat-lbl">Members</span>
          </div>
        </div>
      )}
    </div>
  );
}

function NeedHelpCard({ questions }) {
  const unanswered = questions.filter((q) => (q.answers ? q.answers.length : 0) === 0).slice(0, 5);
  if (unanswered.length === 0) return null;
  return (
    <div className="cp-sidebar-card cp-sidebar-card--warn">
      <div className="cp-sidebar-card-hd">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round"><circle cx="12" cy="12" r="10"/><path d="M12 8v4m0 4h.01"/></svg>
        Need Help ({unanswered.length})
      </div>
      <ul className="cp-need-help-list">
        {unanswered.map((q) => <li key={q.id} className="cp-need-help-item">{q.title}</li>)}
      </ul>
    </div>
  );
}

/* ─── Main Component ─── */
export default function Community() {
  const { session } = useAuth();
  const [searchParams] = useSearchParams();
  const [questions, setQuestions] = useState([]);
  const [communityStats, setCommunityStats] = useState({ question_count: 0, answer_count: 0, member_count: 0, top_tags: [] });
  const [loading, setLoading] = useState(true);
  const [statsLoading, setStatsLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [postFeedback, setPostFeedback] = useState(null);
  const [activeTab, setActiveTab] = useState("latest");
  const [expandedId, setExpandedId] = useState(null);

  useEffect(() => { if (searchParams.get("ask") === "1") setShowForm(true); }, []);

  const loadQuestions = useCallback(async () => {
    setLoading(true);
    try {
      const qs = await api.get("/api/questions?general_only=true");
      setQuestions(qs || []);
    } catch {
      setQuestions([]);
    } finally {
      setLoading(false);
    }
  }, []);

  const loadStats = useCallback(async () => {
    setStatsLoading(true);
    try {
      const s = await api.get("/api/questions/community-stats");
      setCommunityStats(s);
    } catch {
      // non-critical
    } finally {
      setStatsLoading(false);
    }
  }, []);

  useEffect(() => { loadQuestions(); loadStats(); }, [loadQuestions, loadStats]);

  const answeredCount = questions.filter((q) => (q.answers ? q.answers.length : 0) > 0).length;
  const unansweredCount = questions.length - answeredCount;

  const filteredQuestions = (() => {
    let qs = [...questions];
    if (activeTab === "unanswered") return qs.filter((q) => (q.answers ? q.answers.length : 0) === 0);
    if (activeTab === "popular") return qs.sort((a, b) => (b.answers?.length || 0) - (a.answers?.length || 0));
    if (activeTab === "mine") return qs.filter((q) => q.user_id === session?.user?.id);
    return qs.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
  })();

  const handlePosted = (status) => {
    setShowForm(false);
    loadQuestions();
    loadStats();
    setPostFeedback({
      type: status === "approved" ? "success" : "pending",
      text: status === "approved"
        ? "✓ Question posted — visible to the community now."
        : "✓ Question sent for review — a moderator will approve it shortly.",
    });
    setTimeout(() => setPostFeedback(null), 6000);
  };

  const TABS = [
    { id: "latest", label: "Latest" },
    { id: "unanswered", label: `Unanswered${unansweredCount > 0 ? ` (${unansweredCount})` : ""}` },
    { id: "popular", label: "Popular" },
    ...(session ? [{ id: "mine", label: "Mine" }] : []),
  ];

  return (
    <div className="cp-page">
      <SEO title="Community" description="Ask questions, share solutions, and learn with the CodeGoLive developer community." />

      {/* Compact Hero */}
      <div className="cp-hero">
        <div className="cp-hero-inner">
          <div className="cp-hero-left">
            <h1 className="cp-hero-title">Community Q&amp;A</h1>
            <p className="cp-hero-sub">Ask questions, share solutions, learn together.</p>

          </div>
          {session && (
            <button className="btn cp-ask-toggle" onClick={() => { setShowForm((f) => !f); setPostFeedback(null); }}>
              {showForm ? "Cancel" : "+ Ask a Question"}
            </button>
          )}
        </div>
        <div className="cp-hero-stats">
          <div className="cp-hero-stat"><span className="cp-hero-stat-n">{questions.length}</span><span className="cp-hero-stat-l">Questions</span></div>
          <div className="cp-hero-stat-div" />
          <div className="cp-hero-stat"><span className="cp-hero-stat-n">{answeredCount}</span><span className="cp-hero-stat-l">Answered</span></div>
          <div className="cp-hero-stat-div" />
          <div className="cp-hero-stat"><span className="cp-hero-stat-n cp-hero-stat-n--warn">{unansweredCount}</span><span className="cp-hero-stat-l">Need Help</span></div>
          <div className="cp-hero-stat-div" />
          <div className="cp-hero-stat"><span className="cp-hero-stat-n">{communityStats.member_count || "—"}</span><span className="cp-hero-stat-l">Members</span></div>
        </div>
      </div>

      {/* Body */}
      <div className="cp-body">
        {/* Main column */}
        <div className="cp-main">
          {postFeedback && (
            <div className={`cp-feedback cp-feedback--${postFeedback.type}`}>
              <span>{postFeedback.text}</span>
              <button onClick={() => setPostFeedback(null)}>×</button>
            </div>
          )}
          {showForm && session && <AskForm onPosted={handlePosted} onCancel={() => setShowForm(false)} />}
          {!session && (
            <div className="cp-signin-card">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
              </svg>
              <p><Link to="/login">Sign in</Link> to ask questions and join the conversation.</p>
            </div>
          )}
          <div className="cp-tabs">
            {TABS.map((t) => (
              <button key={t.id} className={`cp-tab${activeTab === t.id ? " cp-tab--active" : ""}`} onClick={() => setActiveTab(t.id)}>
                {t.label}
              </button>
            ))}
          </div>
          {loading ? (
            <div className="cp-skel-list">
              {[1, 2, 3, 4].map((i) => (
                <div key={i} className="cp-qcard cp-qcard--skel">
                  <Skel h={12} w="20%" mb={10} />
                  <Skel h={18} w="85%" mb={8} />
                  <Skel h={12} w="40%" />
                </div>
              ))}
            </div>
          ) : filteredQuestions.length === 0 ? (
            <div className="cp-empty">
              <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
              </svg>
              <p className="cp-empty-title">
                {activeTab === "mine" ? "You haven't asked anything yet." : activeTab === "unanswered" ? "All caught up — no unanswered questions." : "No questions yet. Be the first!"}
              </p>
              {session && activeTab !== "mine" && (
                <button className="btn btn-primary" style={{ marginTop: "1rem" }} onClick={() => setShowForm(true)}>Ask the first question</button>
              )}
            </div>
          ) : (
            <div className="cp-qlist">
              {filteredQuestions.map((q) => (
                <QuestionCard key={q.id} q={q} expanded={expandedId === q.id} onExpand={setExpandedId} onRefresh={() => { loadQuestions(); loadStats(); }} session={session} />
              ))}
            </div>
          )}
        </div>

        {/* Sidebar */}
        <aside className="cp-sidebar">
          <PopularTagsCard tags={communityStats.top_tags || []} loading={statsLoading} />
          <CommStatsCard stats={communityStats} loading={statsLoading} />
          <NeedHelpCard questions={questions} />
        </aside>
      </div>
    </div>
  );
}
