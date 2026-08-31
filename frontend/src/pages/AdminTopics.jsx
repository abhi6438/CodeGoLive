import { useEffect, useState, useCallback } from "react";
import AdminShell from "../components/AdminShell";
import { api } from "../lib/api";
import SEO from "../components/SEO";

const STATUS_LABELS = {
  published: { label: "Published", cls: "badge-green" },
  draft: { label: "Draft", cls: "badge-yellow" },
};

function StatusBadge({ status }) {
  const s = STATUS_LABELS[status] || { label: status ?? "draft", cls: "badge-yellow" };
  return <span className={`admin-badge ${s.cls}`}>{s.label}</span>;
}

function ConfirmDialog({ message, onConfirm, onCancel }) {
  return (
    <div className="admin-dialog-overlay">
      <SEO title="Admin — Topics" robots="noindex, nofollow" />
      <div className="admin-dialog">
        <p className="admin-dialog-msg">{message}</p>
        <div className="admin-dialog-actions">
          <button className="admin-btn admin-btn--ghost" onClick={onCancel}>Cancel</button>
          <button className="admin-btn admin-btn--danger" onClick={onConfirm}>Delete</button>
        </div>
      </div>
    </div>
  );
}

function TopicForm({ modules, initial, onSave, onCancel, saving, error }) {
  const [form, setForm] = useState(initial || {
    module_id: modules?.[0]?.id || "",
    number: "", slug: "", title: "", focus: "",
    description: "", video_url: "", github_url: "",
    deliverable_note: "", order_index: 0, status: "draft",
  });
  const set = (k, v) => setForm((f) => ({ ...f, [k]: v }));

  return (
    <div className="admin-form-panel">
      <h3 className="admin-form-title">{initial ? "Edit Topic" : "New Topic"}</h3>
      {error && <div className="admin-alert admin-alert--error">{error}</div>}
      <div className="admin-form-grid">
        <div className="admin-field">
          <label className="admin-label">Module *</label>
          <select className="admin-select" value={form.module_id} onChange={(e) => set("module_id", e.target.value)}>
            {modules?.map((m) => <option key={m.id} value={m.id}>{m.title}</option>)}
          </select>
        </div>
        <div className="admin-field">
          <label className="admin-label">Number</label>
          <input className="admin-input" value={form.number} onChange={(e) => set("number", e.target.value)} placeholder="1.1" />
        </div>
        <div className="admin-field">
          <label className="admin-label">Slug *</label>
          <input className="admin-input" value={form.slug} onChange={(e) => set("slug", e.target.value)} placeholder="my-topic-slug" />
        </div>
        <div className="admin-field">
          <label className="admin-label">Title *</label>
          <input className="admin-input" value={form.title} onChange={(e) => set("title", e.target.value)} />
        </div>
        <div className="admin-field">
          <label className="admin-label">Focus</label>
          <input className="admin-input" value={form.focus || ""} onChange={(e) => set("focus", e.target.value)} placeholder="Short focus line" />
        </div>
        <div className="admin-field">
          <label className="admin-label">Video URL</label>
          <input className="admin-input" value={form.video_url || ""} onChange={(e) => set("video_url", e.target.value)} placeholder="https://youtube.com/..." />
        </div>
        <div className="admin-field">
          <label className="admin-label">GitHub URL</label>
          <input className="admin-input" value={form.github_url || ""} onChange={(e) => set("github_url", e.target.value)} />
        </div>
        <div className="admin-field">
          <label className="admin-label">Order</label>
          <input className="admin-input" type="number" value={form.order_index} onChange={(e) => set("order_index", +e.target.value)} />
        </div>
        <div className="admin-field">
          <label className="admin-label">Status</label>
          <select className="admin-select" value={form.status || "draft"} onChange={(e) => set("status", e.target.value)}>
            <option value="draft">Draft</option>
            <option value="published">Published</option>
          </select>
        </div>
        <div className="admin-field admin-field--full">
          <label className="admin-label">Description</label>
          <textarea className="admin-textarea" rows={2} value={form.description || ""} onChange={(e) => set("description", e.target.value)} />
        </div>
        <div className="admin-field admin-field--full">
          <label className="admin-label">Deliverable Note</label>
          <textarea className="admin-textarea" rows={2} value={form.deliverable_note || ""} onChange={(e) => set("deliverable_note", e.target.value)} />
        </div>
        <div className="admin-field admin-field--full">
          <label className="admin-label">Content (Markdown)</label>
          <textarea className="admin-textarea admin-textarea--code" rows={10} value={form.content_md || ""} onChange={(e) => set("content_md", e.target.value)} placeholder="## Introduction&#10;..." />
        </div>
      </div>
      <div className="admin-form-actions">
        <button className="admin-btn admin-btn--ghost" onClick={onCancel}>Cancel</button>
        <button className="admin-btn admin-btn--primary" disabled={saving} onClick={() => onSave(form)}>
          {saving ? "Saving…" : "Save"}
        </button>
      </div>
    </div>
  );
}

export default function AdminTopics() {
  const [topics, setTopics] = useState(null);
  const [modules, setModules] = useState([]);
  const [error, setError] = useState(null);
  const [search, setSearch] = useState("");
  const [filterModule, setFilterModule] = useState("");
  const [filterStatus, setFilterStatus] = useState("");
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState(null);
  const [saving, setSaving] = useState(false);
  const [saveError, setSaveError] = useState(null);
  const [confirmDelete, setConfirmDelete] = useState(null);

  const load = useCallback(() => {
    setError(null);
    Promise.all([
      api.get("/api/admin/topics"),
      api.get("/api/admin/modules"),
    ]).then(([t, m]) => { setTopics(t); setModules(m); })
      .catch((e) => setError(e.message));
  }, []);

  useEffect(load, [load]);

  const filtered = (topics || [])
    .filter((t) => {
      if (search && !t.title.toLowerCase().includes(search.toLowerCase())) return false;
      if (filterModule && t.module_id !== filterModule) return false;
      if (filterStatus && (t.status || "draft") !== filterStatus) return false;
      return true;
    })
    .sort((a, b) => {
      // Global sort by number (numeric), fallback to order_index, then title
      const na = parseFloat(a.number);
      const nb = parseFloat(b.number);
      const validA = !isNaN(na);
      const validB = !isNaN(nb);
      if (validA && validB) return na - nb;
      if (validA) return -1;
      if (validB) return 1;
      return (a.order_index ?? 0) - (b.order_index ?? 0);
    });

  const handleCreate = async (form) => {
    if (!form.module_id || !form.title || !form.slug) return setSaveError("Module, title, and slug are required");
    setSaving(true); setSaveError(null);
    try {
      await api.post("/api/admin/topics", form);
      setShowForm(false);
      load();
    } catch (e) { setSaveError(e.message); }
    finally { setSaving(false); }
  };

  const handleUpdate = async (form) => {
    if (!form.title) return setSaveError("Title is required");
    setSaving(true); setSaveError(null);
    try {
      await api.patch(`/api/admin/topics/${editing.id}`, form);
      setEditing(null);
      load();
    } catch (e) { setSaveError(e.message); }
    finally { setSaving(false); }
  };

  const handleDelete = async (id) => {
    try {
      await api.del(`/api/admin/topics/${id}`);
      setConfirmDelete(null);
      load();
    } catch (e) { setError(e.message); setConfirmDelete(null); }
  };

  const handlePublishToggle = async (t) => {
    const newStatus = (t.status || "draft") === "published" ? "draft" : "published";
    try {
      await api.patch(`/api/admin/topics/${t.id}`, { status: newStatus });
      load();
    } catch (e) { setError(e.message); }
  };

  return (
    <AdminShell breadcrumbs={[{ label: "Admin", to: "/admin" }, { label: "Topics" }]}>
      <div className="admin-page">
        <div className="admin-page-header">
          <div>
            <h1 className="admin-page-title">Topics</h1>
            <p className="admin-page-desc">
              {topics ? `${filtered.length} of ${topics.length} topics` : "Loading…"}
            </p>
          </div>
          <button className="admin-btn admin-btn--primary" onClick={() => { setShowForm(true); setEditing(null); setSaveError(null); }}>
            + New Topic
          </button>
        </div>

        {error && <div className="admin-alert admin-alert--error">{error}</div>}

        {/* Filters */}
        <div className="admin-filters">
          <input
            className="admin-input admin-input--search"
            placeholder="Search topics…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
          <select className="admin-select admin-select--sm" value={filterModule} onChange={(e) => setFilterModule(e.target.value)}>
            <option value="">All modules</option>
            {modules.map((m) => <option key={m.id} value={m.id}>{m.title}</option>)}
          </select>
          <select className="admin-select admin-select--sm" value={filterStatus} onChange={(e) => setFilterStatus(e.target.value)}>
            <option value="">All statuses</option>
            <option value="published">Published</option>
            <option value="draft">Draft</option>
          </select>
        </div>

        {/* Form */}
        {showForm && !editing && (
          <TopicForm modules={modules} onSave={handleCreate} onCancel={() => setShowForm(false)} saving={saving} error={saveError} />
        )}
        {editing && (
          <TopicForm modules={modules} initial={editing} onSave={handleUpdate} onCancel={() => setEditing(null)} saving={saving} error={saveError} />
        )}

        {/* Table */}
        {!topics && !error && (
          <div className="admin-table-wrap">
            <table className="admin-table"><tbody>
              {[0,1,2,3].map((i) => (
                <tr key={i}><td colSpan={5}><div className="admin-skeleton" style={{ height: "32px", margin: "4px 0" }} /></td></tr>
              ))}
            </tbody></table>
          </div>
        )}

        {topics && filtered.length === 0 && (
          <div className="admin-empty">
            {search || filterModule || filterStatus ? "No topics match your filters." : "No topics yet."}
          </div>
        )}

        {topics && filtered.length > 0 && (
          <div className="admin-table-wrap">
            <table className="admin-table">
              <thead>
                <tr>
                  <th>#</th>
                  <th>Title</th>
                  <th>Module</th>
                  <th>Status</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((t) => (
                  <tr key={t.id}>
                    <td className="admin-table-num">{t.number || "—"}</td>
                    <td>
                      <div className="admin-table-primary">{t.title}</div>
                      <div className="admin-table-meta">{t.slug}</div>
                    </td>
                    <td>
                      <div className="admin-table-meta">{t.module_title || t.module_id}</div>
                    </td>
                    <td>
                      <button
                        className={`admin-badge admin-badge--btn ${(t.status || "draft") === "published" ? "badge-green" : "badge-yellow"}`}
                        onClick={() => handlePublishToggle(t)}
                        title="Click to toggle"
                      >
                        {(t.status || "draft") === "published" ? "Published" : "Draft"}
                      </button>
                    </td>
                    <td>
                      <div className="admin-row-actions">
                        <button className="admin-btn-icon" onClick={() => { setEditing(t); setShowForm(false); setSaveError(null); }} title="Edit">✏️</button>
                        <button className="admin-btn-icon admin-btn-icon--danger" onClick={() => setConfirmDelete(t)} title="Delete">🗑</button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {confirmDelete && (
          <ConfirmDialog
            message={`Delete topic "${confirmDelete.title}"? This cannot be undone.`}
            onConfirm={() => handleDelete(confirmDelete.id)}
            onCancel={() => setConfirmDelete(null)}
          />
        )}
      </div>
    </AdminShell>
  );
}
