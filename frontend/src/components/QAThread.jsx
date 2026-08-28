import { useState } from "react";
import { useAuth } from "../lib/AuthContext";
import { api } from "../lib/api";

/* ── inline feedback banner ─────────────────────────────────────── */
function Banner({ type, message, onDismiss }) {
  if (!message) return null;
  const colors = {
    success: { bg: "var(--success, #22c55e)", text: "#fff" },
    pending: { bg: "var(--amber, #f59e0b)", text: "#fff" },
    error:   { bg: "var(--danger, #ef4444)",  text: "#fff" },
  };
  const { bg, text } = colors[type] || colors.error;
  return (
    <div style={{
      display: "flex", alignItems: "center", justifyContent: "space-between",
      padding: "0.5rem 0.75rem", borderRadius: "6px", marginTop: "0.5rem",
      background: bg, color: text, fontSize: "0.875rem",
    }}>
      <span>{message}</span>
      <button onClick={onDismiss} style={{
        background: "none", border: "none", color: text,
        cursor: "pointer", marginLeft: "0.75rem", fontSize: "1rem", lineHeight: 1,
      }}>×</button>
    </div>
  );
}

/* ── reply form (with inline rejection handling) ─────────────────── */
function ReplyForm({ answerId, parentReplyId, onPosted }) {
  const [body, setBody] = useState("");
  const [feedback, setFeedback] = useState(null); // { type, message }
  const { session } = useAuth();
  if (!session) return null;

  const submit = async () => {
    if (!body.trim()) return;
    setFeedback(null);
    try {
      const result = await api.post("/api/replies", {
        answer_id: answerId,
        parent_reply_id: parentReplyId,
        body,
      });
      setBody("");
      if (result?.status === "approved") {
        onPosted();
      } else {
        setFeedback({ type: "pending", message: "Reply sent for review — a moderator will approve it shortly." });
        onPosted();
      }
    } catch (err) {
      const msg = err?.detail || err?.message || "Could not post reply.";
      setFeedback({ type: "error", message: msg });
    }
  };

  return (
    <div style={{ marginTop: "0.5rem" }}>
      <textarea
        rows={2}
        placeholder="Write a reply... use @name to mention someone"
        value={body}
        onChange={(e) => setBody(e.target.value)}
      />
      <Banner {...(feedback || {})} onDismiss={() => setFeedback(null)} />
      <button className="btn btn-outline" style={{ marginTop: "0.4rem" }} onClick={submit}>
        Reply
      </button>
    </div>
  );
}

/* ── single reply ────────────────────────────────────────────────── */
function Reply({ reply, answerId, onPosted, depth = 0 }) {
  const [replying, setReplying] = useState(false);
  return (
    <div className="qa-reply">
      <div className="qa-meta">{reply.profiles?.display_name} &middot; {new Date(reply.created_at).toLocaleDateString()}</div>
      <div>{reply.body}</div>
      {depth < 3 && (
        <button className="btn btn-outline" style={{ marginTop: "0.3rem", fontSize: "0.78rem" }} onClick={() => setReplying(!replying)}>
          Reply
        </button>
      )}
      {replying && (
        <ReplyForm
          answerId={answerId}
          parentReplyId={reply.id}
          onPosted={() => { setReplying(false); onPosted(); }}
        />
      )}
    </div>
  );
}

/* ── single answer ───────────────────────────────────────────────── */
function Answer({ answer, questionOwnerId, onRefresh }) {
  const { session, profile } = useAuth();
  const [replying, setReplying] = useState(false);
  const canAccept = session && profile?.id === questionOwnerId && !answer.accepted;

  const vote = async (value) => {
    await api.post(`/api/answers/${answer.id}/vote?value=${value}`);
    onRefresh();
  };

  const accept = async () => {
    await api.post(`/api/answers/${answer.id}/accept`);
    onRefresh();
  };

  return (
    <div className={`qa-answer ${answer.accepted ? "accepted" : ""}`}>
      {answer.accepted && <strong style={{ color: "var(--success)" }}>&#10003; Accepted answer</strong>}
      <div className="qa-meta">{answer.profiles?.display_name} &middot; {new Date(answer.created_at).toLocaleDateString()}</div>
      <div>{answer.body}</div>
      <div style={{ marginTop: "0.4rem", display: "flex", gap: "0.5rem", alignItems: "center" }}>
        <button className="vote-btn" onClick={() => vote(1)}>&#9650;</button>
        <button className="vote-btn" onClick={() => vote(-1)}>&#9660;</button>
        <button className="btn btn-outline" style={{ fontSize: "0.78rem" }} onClick={() => setReplying(!replying)}>Reply</button>
        {canAccept && <button className="btn btn-amber" style={{ fontSize: "0.78rem" }} onClick={accept}>Mark as accepted</button>}
      </div>
      {replying && <ReplyForm answerId={answer.id} onPosted={() => { setReplying(false); onRefresh(); }} />}
      {(answer.replies || []).map((r) => (
        <Reply key={r.id} reply={r} answerId={answer.id} onPosted={onRefresh} />
      ))}
    </div>
  );
}

/* ── main thread component ───────────────────────────────────────── */
export default function QAThread({ question, onRefresh }) {
  const { session } = useAuth();
  const [answerBody, setAnswerBody] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [feedback, setFeedback] = useState(null); // { type, message }

  const submitAnswer = async () => {
    if (!answerBody.trim() || submitting) return;
    setSubmitting(true);
    setFeedback(null);
    try {
      const result = await api.post("/api/answers", {
        question_id: question.id,
        body: answerBody,
      });
      setAnswerBody("");
      onRefresh();
      if (result?.status === "approved") {
        setFeedback({ type: "success", message: "✓ Answer posted — visible to everyone now." });
      } else {
        setFeedback({ type: "pending", message: "✓ Sent for review — a moderator will approve it shortly." });
      }
    } catch (err) {
      const msg = err?.detail || err?.message || "Could not post answer.";
      setFeedback({ type: "error", message: msg });
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="qa-question">
      <h3>{question.title}</h3>
      <div className="qa-meta">
        {question.profiles?.display_name} &middot; {new Date(question.created_at).toLocaleDateString()}
      </div>
      <p>{question.body}</p>
      {(question.question_tags || []).map((qt) => (
        <span key={qt.tags.name} className="tag-chip">#{qt.tags.name}</span>
      ))}

      <div style={{ marginTop: "1rem" }}>
        {(question.answers || []).map((a) => (
          <Answer key={a.id} answer={a} questionOwnerId={question.user_id} onRefresh={onRefresh} />
        ))}
        {(question.answers || []).length === 0 && (
          <p style={{ color: "var(--muted)" }}>No approved answers yet — be the first to help.</p>
        )}
      </div>

      {session ? (
        <div style={{ marginTop: "1rem" }}>
          <textarea
            rows={3}
            placeholder="Write an answer..."
            value={answerBody}
            onChange={(e) => { setAnswerBody(e.target.value); setFeedback(null); }}
          />
          <Banner {...(feedback || {})} onDismiss={() => setFeedback(null)} />
          <button
            className="btn btn-primary"
            style={{ marginTop: "0.5rem" }}
            onClick={submitAnswer}
            disabled={submitting}
          >
            {submitting ? "Posting…" : "Post answer"}
          </button>
        </div>
      ) : (
        <p style={{ color: "var(--muted)" }}>Sign in to answer this question.</p>
      )}
    </div>
  );
}
