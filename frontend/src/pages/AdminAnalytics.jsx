import { useEffect, useState, useCallback } from "react";
import AdminShell from "../components/AdminShell";
import { api } from "../lib/api";
import SEO from "../components/SEO";

const CRUMB = [{ label: "Analytics" }];

function fmtDuration(secs) {
  if (!secs) return "—";
  if (secs < 60) return `${secs}s`;
  const m = Math.floor(secs / 60), s = secs % 60;
  if (m < 60) return `${m}m ${s}s`;
  return `${Math.floor(m / 60)}h ${m % 60}m`;
}

function fmtTime(iso) {
  if (!iso) return "—";
  const d = new Date(iso);
  return d.toLocaleString(undefined, { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" });
}

function StatCard({ label, value, sub, color }) {
  return (
    <div className="an-stat-card">
      <div className="an-stat-val" style={color ? { color } : {}}>{value ?? "—"}</div>
      <div className="an-stat-label">{label}</div>
      {sub && <div className="an-stat-sub">{sub}</div>}
    </div>
  );
}

export default function AdminAnalytics() {
  const [data, setData]     = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError]   = useState(null);

  const load = useCallback(async () => {
    setLoading(true); setError(null);
    try {
      const res = await api.get("/api/admin/analytics");
      setData(res);
    } catch (e) {
      setError(e?.detail || e?.message || "Failed to load analytics.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  const totalLoggedIn   = data?.logged_in_count  ?? 0;
  const totalAnonymous  = data?.anonymous_count   ?? 0;
  const totalUsers      = totalLoggedIn + totalAnonymous;
  const loggedPct       = totalUsers > 0 ? Math.round((totalLoggedIn / totalUsers) * 100) : 0;

  return (
    <AdminShell breadcrumbs={CRUMB}>
      <SEO robots="noindex, nofollow" />
      <div className="an-page">
        <div className="an-header">
          <h2 className="an-title">Site Analytics</h2>
          <div className="an-header-actions">
            <a
              href="https://analytics.google.com"
              target="_blank"
              rel="noreferrer"
              className="admin-btn admin-btn--ghost"
            >
              Open Google Analytics ↗
            </a>
            <button className="admin-btn" onClick={load} disabled={loading}>
              {loading ? "Loading…" : "↺ Refresh"}
            </button>
          </div>
        </div>

        {error && (
          <div className="admin-error-banner">{error}</div>
        )}

        {loading && !data ? (
          <div className="an-skeleton-grid">
            {[1,2,3,4].map(i => <div key={i} className="an-skeleton" />)}
          </div>
        ) : data ? (
          <>
            {/* ── Stat cards ── */}
            <div className="an-stats-row">
              <StatCard label="Page views today"     value={data.views_today} />
              <StatCard label="Page views (7 days)"  value={data.views_7d} />
              <StatCard label="Page views (30 days)" value={data.views_30d} />
              <StatCard
                label="Avg time on site"
                value={fmtDuration(data.avg_duration_seconds)}
                sub="last 30 days"
                color="var(--primary)"
              />
            </div>

            {/* ── Tables row ── */}
            <div className="an-tables-row">
              {/* Top Pages */}
              <div className="an-card">
                <div className="an-card-title">Top Pages <span className="an-badge">30d</span></div>
                <table className="an-table">
                  <thead><tr><th>Page</th><th>Views</th></tr></thead>
                  <tbody>
                    {(data.top_pages || []).map((p, i) => (
                      <tr key={i}>
                        <td className="an-path">{p.path}</td>
                        <td className="an-count">{p.count}</td>
                      </tr>
                    ))}
                    {(!data.top_pages?.length) && (
                      <tr><td colSpan={2} className="an-empty">No data yet</td></tr>
                    )}
                  </tbody>
                </table>
              </div>

              {/* Top Countries */}
              <div className="an-card">
                <div className="an-card-title">Top Countries <span className="an-badge">30d</span></div>
                <table className="an-table">
                  <thead><tr><th>Country</th><th>Views</th></tr></thead>
                  <tbody>
                    {(data.top_countries || []).map((c, i) => (
                      <tr key={i}>
                        <td>{c.country}</td>
                        <td className="an-count">{c.count}</td>
                      </tr>
                    ))}
                    {(!data.top_countries?.length) && (
                      <tr><td colSpan={2} className="an-empty">No data yet</td></tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>

            {/* ── Logged-in ratio ── */}
            <div className="an-card an-card--full">
              <div className="an-card-title">
                Visitor type <span className="an-badge">30d</span>
              </div>
              <div className="an-ratio-row">
                <span className="an-ratio-label">Logged in ({totalLoggedIn})</span>
                <div className="an-ratio-bar">
                  <div className="an-ratio-fill" style={{ width: `${loggedPct}%` }} />
                </div>
                <span className="an-ratio-label">Anonymous ({totalAnonymous})</span>
              </div>
              <div className="an-ratio-pct">{loggedPct}% of visits are from signed-in users</div>
            </div>

            {/* ── Recent visits ── */}
            <div className="an-card an-card--full">
              <div className="an-card-title">Recent Visits <span className="an-badge">last 50</span></div>
              <div className="an-scroll-table">
                <table className="an-table">
                  <thead>
                    <tr>
                      <th>Time</th>
                      <th>Page</th>
                      <th>Country</th>
                      <th>City</th>
                      <th>Time spent</th>
                      <th>User</th>
                    </tr>
                  </thead>
                  <tbody>
                    {(data.recent || []).map((r) => (
                      <tr key={r.id}>
                        <td className="an-meta">{fmtTime(r.created_at)}</td>
                        <td className="an-path">{r.path}</td>
                        <td>{r.country || "—"}</td>
                        <td className="an-meta">{r.city || "—"}</td>
                        <td className="an-count">{fmtDuration(r.duration_seconds)}</td>
                        <td className="an-meta">{r.user_id ? "👤" : "—"}</td>
                      </tr>
                    ))}
                    {(!data.recent?.length) && (
                      <tr><td colSpan={6} className="an-empty">No visits recorded yet</td></tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </>
        ) : null}
      </div>
    </AdminShell>
  );
}
