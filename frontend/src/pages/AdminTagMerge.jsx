import { useEffect, useState } from "react";
import AdminShell from "../components/AdminShell";
import { api } from "../lib/api";

export default function AdminTagMerge() {
  const [tags, setTags] = useState(null);
  const [error, setError] = useState(null);
  const [source, setSource] = useState("");
  const [target, setTarget] = useState("");
  const [merging, setMerging] = useState(false);
  const [success, setSuccess] = useState(null);

  const load = () => {
    setError(null);
    api.get("/api/admin/tags").then(setTags).catch((e) => setError(e.message));
  };

  useEffect(load, []);

  const handleMerge = async () => {
    if (!source || !target || source === target) return;
    setMerging(true); setError(null); setSuccess(null);
    try {
      await api.post(`/api/admin/tags/merge?source_tag_id=${source}&target_tag_id=${target}`);
      setSuccess("Tags merged successfully.");
      setSource(""); setTarget("");
      load();
    } catch (e) { setError(e.message); }
    finally { setMerging(false); }
  };

  const sourceTag = tags?.find((t) => t.id === source);
  const targetTag = tags?.find((t) => t.id === target);

  return (
    <AdminShell breadcrumbs={[{ label: "Admin", to: "/admin" }, { label: "Tags" }]}>
      <div className="admin-page">
        <div className="admin-page-header">
          <div>
            <h1 className="admin-page-title">Tags</h1>
            <p className="admin-page-desc">{tags ? `${tags.length} tags` : "Loading…"}</p>
          </div>
        </div>

        {error && <div className="admin-alert admin-alert--error">{error}</div>}
        {success && <div className="admin-alert admin-alert--success">{success}</div>}

        {/* Merge tool */}
        <div className="admin-section">
          <h2 className="admin-section-title">Merge Tags</h2>
          <p className="admin-section-desc">Move all questions from one tag to another, then delete the source tag.</p>
          <div className="admin-form-grid" style={{ maxWidth: "560px" }}>
            <div className="admin-field">
              <label className="admin-label">Source (to delete)</label>
              <select className="admin-select" value={source} onChange={(e) => setSource(e.target.value)}>
                <option value="">Select tag…</option>
                {(tags || []).filter((t) => t.id !== target).map((t) => (
                  <option key={t.id} value={t.id}>{t.name} ({t.usage_count ?? 0})</option>
                ))}
              </select>
            </div>
            <div className="admin-field">
              <label className="admin-label">Target (to keep)</label>
              <select className="admin-select" value={target} onChange={(e) => setTarget(e.target.value)}>
                <option value="">Select tag…</option>
                {(tags || []).filter((t) => t.id !== source).map((t) => (
                  <option key={t.id} value={t.id}>{t.name} ({t.usage_count ?? 0})</option>
                ))}
              </select>
            </div>
          </div>
          {source && target && source !== target && (
            <div className="admin-merge-preview">
              Merge <strong>"{sourceTag?.name}"</strong> → <strong>"{targetTag?.name}"</strong>. Source will be deleted.
            </div>
          )}
          <div style={{ marginTop: "12px" }}>
            <button
              className="admin-btn admin-btn--primary"
              disabled={!source || !target || source === target || merging}
              onClick={handleMerge}
            >
              {merging ? "Merging…" : "Merge Tags"}
            </button>
          </div>
        </div>

        {/* Tag list */}
        <div className="admin-section">
          <h2 className="admin-section-title">All Tags</h2>
          {!tags && <div className="admin-skeleton" style={{ height: "200px" }} />}
          {tags && (
            <div className="admin-table-wrap">
              <table className="admin-table">
                <thead><tr><th>Tag</th><th>Usage</th></tr></thead>
                <tbody>
                  {tags.map((t) => (
                    <tr key={t.id}>
                      <td className="admin-table-primary">{t.name}</td>
                      <td className="admin-table-num">{t.usage_count ?? 0}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </AdminShell>
  );
}
