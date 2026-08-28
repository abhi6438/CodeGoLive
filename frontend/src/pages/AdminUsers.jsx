import { useEffect, useState } from "react";
import AdminShell from "../components/AdminShell";
import { api } from "../lib/api";
import { useAuth } from "../lib/AuthContext";

const ROLE_LABELS = {
  admin: { label: "Admin", cls: "badge-red" },
  moderator: { label: "Moderator", cls: "badge-blue" },
  learner: { label: "Learner", cls: "badge-gray" },
};

function RoleBadge({ role }) {
  const r = ROLE_LABELS[role] || { label: role, cls: "badge-gray" };
  return <span className={`admin-badge ${r.cls}`}>{r.label}</span>;
}

export default function AdminUsers() {
  const { profile: me } = useAuth();
  const [users, setUsers] = useState(null);
  const [error, setError] = useState(null);
  const [search, setSearch] = useState("");
  const [filterRole, setFilterRole] = useState("");
  const [updating, setUpdating] = useState(null);

  const load = () => {
    setError(null);
    api.get("/api/admin/users").then(setUsers).catch((e) => setError(e.message));
  };

  useEffect(load, []);

  const setRole = async (userId, role) => {
    setUpdating(userId);
    try {
      await api.patch(`/api/admin/users/${userId}/role`, { role });
      load();
    } catch (e) { setError(e.message); }
    finally { setUpdating(null); }
  };

  const filtered = (users || []).filter((u) => {
    if (filterRole && u.role !== filterRole) return false;
    if (search) {
      const q = search.toLowerCase();
      return (u.display_name || "").toLowerCase().includes(q) || u.id.toLowerCase().includes(q);
    }
    return true;
  });

  return (
    <AdminShell breadcrumbs={[{ label: "Admin", to: "/admin" }, { label: "Users" }]}>
      <div className="admin-page">
        <div className="admin-page-header">
          <div>
            <h1 className="admin-page-title">Users</h1>
            <p className="admin-page-desc">{users ? `${filtered.length} of ${users.length} users` : "Loading…"}</p>
          </div>
        </div>

        {error && <div className="admin-alert admin-alert--error">{error}</div>}

        <div className="admin-filters">
          <input
            className="admin-input admin-input--search"
            placeholder="Search by name or ID…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
          <select className="admin-select admin-select--sm" value={filterRole} onChange={(e) => setFilterRole(e.target.value)}>
            <option value="">All roles</option>
            <option value="admin">Admin</option>
            <option value="moderator">Moderator</option>
            <option value="learner">Learner</option>
          </select>
        </div>

        {!users && !error && (
          <div className="admin-table-wrap">
            <table className="admin-table"><tbody>
              {[0,1,2,3].map((i) => (
                <tr key={i}><td colSpan={4}><div className="admin-skeleton" style={{ height: "32px", margin: "4px 0" }} /></td></tr>
              ))}
            </tbody></table>
          </div>
        )}

        {users && filtered.length === 0 && (
          <div className="admin-empty">No users match your filters.</div>
        )}

        {users && filtered.length > 0 && (
          <div className="admin-table-wrap">
            <table className="admin-table">
              <thead>
                <tr>
                  <th>User</th>
                  <th>Role</th>
                  <th>Joined</th>
                  <th>Change role</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((u) => (
                  <tr key={u.id} className={updating === u.id ? "admin-row--updating" : ""}>
                    <td>
                      <div className="admin-table-primary">{u.display_name || "—"}</div>
                      <div className="admin-table-meta">{u.id}</div>
                    </td>
                    <td><RoleBadge role={u.role} /></td>
                    <td className="admin-table-meta">
                      {u.created_at ? new Date(u.created_at).toLocaleDateString("en-GB", { day: "2-digit", month: "short", year: "numeric" }) : "—"}
                    </td>
                    <td>
                      {u.id !== me?.id ? (
                        <div className="admin-role-actions">
                          {u.role !== "learner" && (
                            <button className="admin-btn admin-btn--xs admin-btn--ghost" disabled={updating === u.id} onClick={() => setRole(u.id, "learner")}>Learner</button>
                          )}
                          {u.role !== "moderator" && (
                            <button className="admin-btn admin-btn--xs admin-btn--ghost" disabled={updating === u.id} onClick={() => setRole(u.id, "moderator")}>Moderator</button>
                          )}
                          {u.role !== "admin" && (
                            <button className="admin-btn admin-btn--xs admin-btn--primary" disabled={updating === u.id} onClick={() => setRole(u.id, "admin")}>Admin</button>
                          )}
                        </div>
                      ) : (
                        <span className="admin-table-meta">You</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </AdminShell>
  );
}
