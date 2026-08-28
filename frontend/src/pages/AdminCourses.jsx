import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import AdminShell from "../components/AdminShell";
import { api } from "../lib/api";

const STATUS_LABELS = {
  available: { label: "Available", cls: "badge-green" },
  coming_soon: { label: "Coming Soon", cls: "badge-yellow" },
  archived: { label: "Archived", cls: "badge-gray" },
};

function StatusBadge({ status }) {
  const s = STATUS_LABELS[status] || { label: status, cls: "badge-gray" };
  return <span className={`admin-badge ${s.cls}`}>{s.label}</span>;
}

function ConfirmDialog({ message, onConfirm, onCancel }) {
  return (
    <div className="admin-dialog-overlay">
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

function CourseForm({ initial, onSave, onCancel, saving }) {
  const [form, setForm] = useState(initial || {
    id: "", title: "", subtitle: "", description: "",
    status: "coming_soon", icon: "", order_index: 0,
  });
  const set = (k, v) => setForm((f) => ({ ...f, [k]: v }));

  return (
    <div className="admin-form-panel">
      <h3 className="admin-form-title">{initial ? "Edit Course" : "New Course"}</h3>
      <div className="admin-form-grid">
        {!initial && (
          <div className="admin-field">
            <label className="admin-label">ID (slug) *</label>
            <input className="admin-input" value={form.id} onChange={(e) => set("id", e.target.value)} placeholder="e.g. sap-btp" />
          </div>
        )}
        <div className="admin-field">
          <label className="admin-label">Title *</label>
          <input className="admin-input" value={form.title} onChange={(e) => set("title", e.target.value)} />
        </div>
        <div className="admin-field">
          <label className="admin-label">Subtitle</label>
          <input className="admin-input" value={form.subtitle || ""} onChange={(e) => set("subtitle", e.target.value)} />
        </div>
        <div className="admin-field admin-field--full">
          <label className="admin-label">Description</label>
          <textarea className="admin-textarea" rows={3} value={form.description || ""} onChange={(e) => set("description", e.target.value)} />
        </div>
        <div className="admin-field">
          <label className="admin-label">Status</label>
          <select className="admin-select" value={form.status} onChange={(e) => set("status", e.target.value)}>
            <option value="available">Available</option>
            <option value="coming_soon">Coming Soon</option>
            <option value="archived">Archived</option>
          </select>
        </div>
        <div className="admin-field">
          <label className="admin-label">Icon (emoji)</label>
          <input className="admin-input" value={form.icon || ""} onChange={(e) => set("icon", e.target.value)} placeholder="🛠️" />
        </div>
        <div className="admin-field">
          <label className="admin-label">Order</label>
          <input className="admin-input" type="number" value={form.order_index} onChange={(e) => set("order_index", +e.target.value)} />
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

export default function AdminCourses() {
  const [courses, setCourses] = useState(null);
  const [error, setError] = useState(null);
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState(null);
  const [saving, setSaving] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(null);
  const [saveError, setSaveError] = useState(null);

  const load = () => {
    setError(null);
    api.get("/api/admin/courses")
      .then(setCourses)
      .catch((e) => setError(e.message));
  };

  useEffect(load, []);

  const handleCreate = async (form) => {
    if (!form.id || !form.title) return setSaveError("ID and Title are required");
    setSaving(true); setSaveError(null);
    try {
      await api.post("/api/admin/courses", form);
      setShowForm(false);
      load();
    } catch (e) { setSaveError(e.message); }
    finally { setSaving(false); }
  };

  const handleUpdate = async (form) => {
    if (!form.title) return setSaveError("Title is required");
    setSaving(true); setSaveError(null);
    try {
      await api.patch(`/api/admin/courses/${editing.id}`, form);
      setEditing(null);
      load();
    } catch (e) { setSaveError(e.message); }
    finally { setSaving(false); }
  };

  const handleDelete = async (id) => {
    try {
      await api.del(`/api/admin/courses/${id}`);
      setConfirmDelete(null);
      load();
    } catch (e) { setError(e.message); setConfirmDelete(null); }
  };

  return (
    <AdminShell breadcrumbs={[{ label: "Admin", to: "/admin" }, { label: "Courses" }]}>
      <div className="admin-page">
        <div className="admin-page-header">
          <div>
            <h1 className="admin-page-title">Courses</h1>
            <p className="admin-page-desc">{courses ? `${courses.length} course${courses.length !== 1 ? "s" : ""}` : "Loading…"}</p>
          </div>
          <button className="admin-btn admin-btn--primary" onClick={() => { setShowForm(true); setEditing(null); setSaveError(null); }}>
            + New Course
          </button>
        </div>

        {error && <div className="admin-alert admin-alert--error">{error}</div>}
        {saveError && <div className="admin-alert admin-alert--error">{saveError}</div>}

        {(showForm && !editing) && (
          <CourseForm onSave={handleCreate} onCancel={() => setShowForm(false)} saving={saving} />
        )}

        {editing && (
          <CourseForm initial={editing} onSave={handleUpdate} onCancel={() => setEditing(null)} saving={saving} />
        )}

        {/* Table */}
        {!courses && !error && (
          <div className="admin-table-wrap">
            <table className="admin-table"><tbody>
              {[0,1,2].map((i) => (
                <tr key={i}><td colSpan={5}><div className="admin-skeleton" style={{ height: "32px", margin: "4px 0" }} /></td></tr>
              ))}
            </tbody></table>
          </div>
        )}

        {courses && courses.length === 0 && (
          <div className="admin-empty">No courses yet. <button className="admin-link-btn" onClick={() => setShowForm(true)}>Create one.</button></div>
        )}

        {courses && courses.length > 0 && (
          <div className="admin-table-wrap">
            <table className="admin-table">
              <thead>
                <tr>
                  <th>Course</th>
                  <th>Status</th>
                  <th>Modules</th>
                  <th>Order</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {courses.map((c) => (
                  <tr key={c.id}>
                    <td>
                      <div className="admin-table-primary">
                        <span style={{ marginRight: "6px" }}>{c.icon}</span>
                        {c.title}
                      </div>
                      <div className="admin-table-meta">{c.id}</div>
                    </td>
                    <td><StatusBadge status={c.status} /></td>
                    <td className="admin-table-num">{c.module_count ?? 0}</td>
                    <td className="admin-table-num">{c.order_index}</td>
                    <td>
                      <div className="admin-row-actions">
                        <button className="admin-btn-icon" onClick={() => { setEditing(c); setShowForm(false); setSaveError(null); }} title="Edit">✏️</button>
                        <button className="admin-btn-icon admin-btn-icon--danger" onClick={() => setConfirmDelete(c)} title="Delete">🗑</button>
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
            message={`Delete course "${confirmDelete.title}"? This cannot be undone.`}
            onConfirm={() => handleDelete(confirmDelete.id)}
            onCancel={() => setConfirmDelete(null)}
          />
        )}
      </div>
    </AdminShell>
  );
}
