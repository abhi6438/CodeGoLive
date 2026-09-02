import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import AdminShell from "../components/AdminShell";
import { api } from "../lib/api";
import SEO from "../components/SEO";

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
      <SEO title="Admin — Courses" robots="noindex, nofollow" />
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
    status: "coming_soon", icon: "", order_index: 0, access_type: "public",
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
        <div className="admin-field">
          <label className="admin-label">Access Type</label>
          <select className="admin-select" value={form.access_type || "public"} onChange={(e) => set("access_type", e.target.value)}>
            <option value="public">Public — open to all learners</option>
            <option value="restricted">Restricted — invite only</option>
          </select>
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


function AccessPanel({ courseId }) {
  const [users, setUsers] = useState([]);
  const [email, setEmail] = useState("");
  const [granting, setGranting] = useState(false);
  const [error, setError] = useState(null);

  const reload = () => {
    api.get(`/api/admin/course-access/${courseId}`).then(setUsers).catch(() => {});
  };

  useEffect(() => { reload(); }, [courseId]); // eslint-disable-line

  const handleGrant = async () => {
    if (!email.trim()) return;
    setGranting(true); setError(null);
    try {
      await api.post(`/api/admin/course-access/${courseId}`, { user_email: email.trim() });
      setEmail("");
      reload();
    } catch (e) { setError(e.message || "Failed to grant access"); }
    finally { setGranting(false); }
  };

  const handleRevoke = async (userId) => {
    try {
      await api.del(`/api/admin/course-access/${courseId}/${userId}`);
      reload();
    } catch (e) { setError(e.message || "Failed to revoke access"); }
  };

  return (
    <div className="admin-form-panel" style={{ marginTop: "1.5rem", borderTop: "2px solid var(--accent)", paddingTop: "1.25rem" }}>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "0.5rem" }}>
        <h3 className="admin-form-title" style={{ margin: 0 }}>Manage Access</h3>
      </div>
      <p style={{ fontSize: "0.82rem", color: "var(--text-2)", marginBottom: "1rem" }}>
        This course is <strong>restricted</strong>. Only users listed below can see and enter it.
        Grant or revoke access instantly — no need to click Save.
      </p>
      {error && <div className="admin-alert admin-alert--error" style={{ marginBottom: "0.75rem" }}>{error}</div>}
      <div style={{ display: "flex", gap: "0.5rem", marginBottom: "1.25rem" }}>
        <input
          className="admin-input"
          style={{ flex: 1 }}
          placeholder="Enter learner email e.g. user@example.com"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && handleGrant()}
        />
        <button className="admin-btn admin-btn--primary" disabled={granting || !email.trim()} onClick={handleGrant}>
          {granting ? "Granting…" : "Grant Access"}
        </button>
      </div>
      {users.length === 0 ? (
        <p style={{ fontSize: "0.82rem", color: "var(--text-3)" }}>No users have access yet.</p>
      ) : (
        <div className="admin-table-wrap">
          <table className="admin-table">
            <thead>
              <tr>
                <th>User</th>
                <th>Granted</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {users.map((u) => (
                <tr key={u.user_id}>
                  <td>
                    <div className="admin-table-primary">{u.profiles?.email || u.user_id}</div>
                    {u.profiles?.display_name && (
                      <div className="admin-table-meta">{u.profiles.display_name}</div>
                    )}
                  </td>
                  <td style={{ fontSize: "0.78rem", color: "var(--text-3)" }}>
                    {u.granted_at ? new Date(u.granted_at).toLocaleDateString() : "—"}
                  </td>
                  <td>
                    <button className="admin-btn admin-btn--danger" style={{fontSize:"0.75rem",padding:"0.3rem 0.7rem"}} onClick={() => { if(window.confirm(`Revoke access for ${u.profiles?.email || u.user_id}?`)) handleRevoke(u.user_id); }} title="Revoke access">Revoke</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
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
  const [assessmentSettings, setAssessmentSettings] = useState([]);
  const [togglingId, setTogglingId] = useState(null);
  const [accessPanel, setAccessPanel] = useState(null); // course object whose access panel is open

  const loadAssessmentSettings = () => {
    api.get("/api/admin/assessment-settings")
      .then(setAssessmentSettings)
      .catch(() => {});
  };

  const load = () => {
    setError(null);
    api.get("/api/admin/courses")
      .then(setCourses)
      .catch((e) => setError(e.message));
  };

  useEffect(() => { load(); loadAssessmentSettings(); }, []);

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

  const handleAssessmentToggle = async (courseId, currentEnabled) => {
    setTogglingId(courseId);
    try {
      await api.patch(`/api/admin/assessment-settings/${courseId}`, { enabled: !currentEnabled });
      loadAssessmentSettings();
    } catch (e) { /* ignore */ }
    finally { setTogglingId(null); }
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


        {/* Standalone Access Control Panel */}
        {accessPanel && (
          <div className="admin-form-panel" style={{ marginTop: "1rem", borderTop: "2px solid var(--accent)", paddingTop: "1.25rem" }}>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "0.75rem" }}>
              <h3 className="admin-form-title" style={{ margin: 0 }}>🔐 Access Control — {accessPanel.title}</h3>
              <button className="admin-btn" onClick={() => setAccessPanel(null)}>✕ Close</button>
            </div>
            <AccessPanel courseId={accessPanel.id} key={accessPanel.id} />
          </div>
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
                  <th>Access</th>
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
                    <td>
                      {c.access_type === "restricted"
                        ? <span style={{fontSize:"0.72rem",padding:"0.18rem 0.5rem",borderRadius:"4px",background:"rgba(139,92,246,0.18)",color:"var(--accent)",fontWeight:600}}>🔐 Restricted</span>
                        : <span style={{fontSize:"0.72rem",padding:"0.18rem 0.5rem",borderRadius:"4px",background:"rgba(34,197,94,0.12)",color:"#4ade80"}}>Public</span>
                      }
                    </td>
                    <td className="admin-table-num">{c.module_count ?? 0}</td>
                    <td className="admin-table-num">{c.order_index}</td>
                    <td>
                      <div className="admin-row-actions">
                        <button className="admin-btn-icon" onClick={() => { setEditing(c); setShowForm(false); setSaveError(null); setAccessPanel(null); }} title="Edit">✏️</button>
                        {c.access_type === "restricted" && (
                          <button className="admin-btn-icon" style={accessPanel?.id === c.id ? { background: "var(--accent)", color: "#fff", borderRadius: "4px" } : {}} onClick={() => { setAccessPanel(accessPanel?.id === c.id ? null : c); setEditing(null); setShowForm(false); }} title="Manage Access">🔐</button>
                        )}
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

        {/* Assessment Settings */}
        <div className="admin-section" style={{ marginTop: "2.5rem" }}>
          <div className="admin-section-header">
            <h2 className="admin-section-title">Assessment Availability</h2>
            <p className="admin-section-desc">Enable or disable the final assessment for each course. Only enabled courses appear on the Assessment page.</p>
          </div>
          {assessmentSettings.length === 0 && (
            <p className="admin-empty" style={{ marginTop: "1rem" }}>No courses found or settings unavailable.</p>
          )}
          {assessmentSettings.length > 0 && (
            <div className="admin-table-wrap" style={{ marginTop: "1rem" }}>
              <table className="admin-table">
                <thead>
                  <tr>
                    <th>Course</th>
                    <th>Status</th>
                    <th style={{ width: 120 }}>Assessment</th>
                  </tr>
                </thead>
                <tbody>
                  {assessmentSettings.map((s) => (
                    <tr key={s.course_id}>
                      <td>
                        <div className="admin-table-primary">{s.title}</div>
                        <div className="admin-table-meta">{s.course_id}</div>
                      </td>
                      <td><StatusBadge status={s.status} /></td>
                      <td>
                        <button
                          className={`asmt-toggle${s.assessment_enabled ? " asmt-toggle--on" : ""}`}
                          disabled={togglingId === s.course_id}
                          onClick={() => handleAssessmentToggle(s.course_id, s.assessment_enabled)}
                          title={s.assessment_enabled ? "Disable assessment" : "Enable assessment"}
                        >
                          <span className="asmt-toggle-track">
                            <span className="asmt-toggle-knob" />
                          </span>
                          <span className="asmt-toggle-label">{s.assessment_enabled ? "On" : "Off"}</span>
                        </button>
                      </td>
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
