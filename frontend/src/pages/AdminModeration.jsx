import { useEffect, useState, useCallback } from "react";
import AdminShell from "../components/AdminShell";
import { api } from "../lib/api";

function ModerationCard({ item, type, onDecide }) {
  const [rejecting, setRejecting] = useState(false);
  const [reason, setReason] = useState("");

  return (
    <div className="admin-mod-card">
      <div className="admin-mod-meta">
        <span className="admin-table-primary">{item.profiles?.display_name || "Unknown"}</span>
        {type === "answers" && item.questions?.title && (
          <span className="admin-table-meta"> on "{item.questions.title}"</span>
        )}
        <span className="admin-table-meta"> · {new Date(item.created_at).toLocaleString("en-GB", { day: "2-digit", month: "short", hour: "2-digit", minute: "2-digit" })}</span>
        {item.auto_flagged && <span className="admin-badge badge-red" style={{ marginLeft: "8px" }}>Auto-flagged</span>}
      </div>
      <p className="admin-mod-body">{item.body}</p>
      {rejecting ? (
        <div className="admin-mod-reject-form">
          <input
            className="admin-input"
            placeholder="Reason for rejection (optional)"
            value={reason}
            onChange={(e) => setReason(e.target.value)}
          />
          <div style={{ display: "flex", gap: "8px", marginTop: "8px" }}>
            <button className="admin-btn admin-btn--ghost admin-btn--sm" onClick={() => setRejecting(false)}>Cancel</button>
            <button className="admin-btn admin-btn--danger admin-btn--sm" onClick={() => onDecide(type, item.id, false, reason || null)}>Confirm Reject</button>
          </div>
        </div>
      ) : (
        <div className="admin-mod-actions">
          <button className="admin-btn admin-btn--primary admin-btn--sm" onClick={() => onDecide(type, item.id, true, null)}>Approve</button>
          <button className="admin-btn admin-btn--ghost admin-btn--sm" onClick={() => setRejecting(true)}>Reject</button>
        </div>
      )}
    </div>
  );
}

export default function AdminModeration() {
  const [queue, setQueue] = useState(null);
  const [error, setError] = useState(null);

  const load = useCallback(() => {
    setError(null);
    api.get("/api/moderation/queue")
      .then(setQueue)
      .catch((e) => setError(e.message));
  }, []);

  useEffect(() => { load(); }, [load]);

  const decide = async (type, id, approve, note) => {
    try {
      await api.post(`/api/moderation/${type}/${id}`, { approve, note });
      load();
    } catch (e) { setError(e.message); }
  };

  const totalPending = queue ? queue.answers.length + queue.replies.length : 0;

  return (
    <AdminShell breadcrumbs={[{ label: "Admin", to: "/admin" }, { label: "Moderation" }]}>
      <div className="admin-page">
        <div className="admin-page-header">
          <div>
            <h1 className="admin-page-title">Moderation Queue</h1>
            <p className="admin-page-desc">
              {queue ? (totalPending === 0 ? "All clear" : `${totalPending} item${totalPending !== 1 ? "s" : ""} pending review`) : "Loading…"}
            </p>
          </div>
          {queue && totalPending > 0 && (
            <span className="admin-badge badge-red" style={{ fontSize: "13px", padding: "4px 10px" }}>{totalPending} pending</span>
          )}
        </div>

        {error && <div className="admin-alert admin-alert--error">{error}</div>}

        {queue && totalPending === 0 && (
          <div className="admin-empty admin-empty--success">
            ✓ No items pending moderation
          </div>
        )}

        {!queue && !error && (
          <div className="admin-table-wrap">
            {[0,1].map((i) => <div key={i} className="admin-mod-card"><div className="admin-skeleton" style={{ height: "80px" }} /></div>)}
          </div>
        )}

        {queue && queue.answers.length > 0 && (
          <div className="admin-section">
            <h2 className="admin-section-title">Answers <span className="admin-section-count">{queue.answers.length}</span></h2>
            {queue.answers.map((a) => (
              <ModerationCard key={a.id} item={a} type="answers" onDecide={decide} />
            ))}
          </div>
        )}

        {queue && queue.replies.length > 0 && (
          <div className="admin-section">
            <h2 className="admin-section-title">Replies <span className="admin-section-count">{queue.replies.length}</span></h2>
            {queue.replies.map((r) => (
              <ModerationCard key={r.id} item={r} type="replies" onDecide={decide} />
            ))}
          </div>
        )}
      </div>
    </AdminShell>
  );
}
