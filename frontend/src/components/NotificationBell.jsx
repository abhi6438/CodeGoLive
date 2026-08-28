import { useEffect, useState, useRef } from "react";
import { api } from "../lib/api";
import { useAuth } from "../lib/AuthContext";

export default function NotificationBell() {
  const { session } = useAuth();
  const [notifications, setNotifications] = useState([]);
  const [open, setOpen] = useState(false);
  const ref = useRef(null);

  const unread = notifications.filter((n) => !n.read).length;

  const load = () => {
    if (!session) return;
    api.get("/api/notifications").then(setNotifications).catch(() => {});
  };

  useEffect(() => { load(); }, [session]);

  // Close dropdown when clicking outside
  useEffect(() => {
    const handler = (e) => { if (ref.current && !ref.current.contains(e.target)) setOpen(false); };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  const markRead = async (id) => {
    await api.post(`/api/notifications/${id}/read`, {});
    setNotifications((prev) => prev.map((n) => n.id === id ? { ...n, read: true } : n));
  };

  const markAllRead = async () => {
    await Promise.all(notifications.filter((n) => !n.read).map((n) => api.post(`/api/notifications/${n.id}/read`, {})));
    setNotifications((prev) => prev.map((n) => ({ ...n, read: true })));
  };

  const typeLabel = (type) => {
    if (type === "answered") return "answered your question";
    if (type === "mentioned") return "mentioned you";
    if (type === "accepted") return "accepted your answer";
    return type;
  };

  if (!session) return (
    <button
      disabled
      className="topbar-icon-btn"
      title="Sign in to see notifications"
      aria-label="Notifications"
      style={{ opacity: 0.4, cursor: "default" }}
    >
      🔔
    </button>
  );

  return (
    <div ref={ref} style={{ position: "relative", display: "inline-block" }}>
      <button
        onClick={() => { setOpen((o) => !o); if (!open) load(); }}
className="topbar-icon-btn"
        style={{ fontSize: "1rem", position: "relative" }}
        title="Notifications"
        aria-label="Notifications"
      >
        🔔
        {unread > 0 && (
          <span style={{
            position: "absolute", top: "-4px", right: "-6px",
            background: "var(--amber)", color: "var(--navy)",
            borderRadius: "999px", fontSize: "0.65rem", fontWeight: 700,
            padding: "0 4px", minWidth: "16px", textAlign: "center", lineHeight: "16px",
          }}>
            {unread > 9 ? "9+" : unread}
          </span>
        )}
      </button>

      {open && (
        <div style={{
          position: "absolute", right: 0, top: "calc(100% + 0.5rem)",
          background: "var(--white)", border: "1px solid var(--border)",
          borderRadius: "10px", boxShadow: "0 4px 20px rgba(0,0,0,0.12)",
          width: "320px", zIndex: 1000, overflow: "hidden",
        }}>
          <div style={{
            display: "flex", alignItems: "center", justifyContent: "space-between",
            padding: "0.75rem 1rem", borderBottom: "1px solid var(--border)",
            background: "var(--navy)", color: "var(--white)",
          }}>
            <strong>Notifications</strong>
            {unread > 0 && (
              <button onClick={markAllRead} style={{
                background: "none", border: "none", color: "var(--ice)",
                cursor: "pointer", fontSize: "0.78rem",
              }}>
                Mark all read
              </button>
            )}
          </div>

          <div style={{ maxHeight: "360px", overflowY: "auto" }}>
            {notifications.length === 0 ? (
              <div style={{ padding: "1.5rem", textAlign: "center", color: "var(--muted)", fontSize: "0.9rem" }}>
                No notifications yet
              </div>
            ) : (
              notifications.map((n) => (
                <div
                  key={n.id}
                  onClick={() => !n.read && markRead(n.id)}
                  style={{
                    padding: "0.75rem 1rem",
                    borderBottom: "1px solid var(--border)",
                    background: n.read ? "var(--white)" : "#eff6ff",
                    cursor: n.read ? "default" : "pointer",
                    fontSize: "0.88rem",
                  }}
                >
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
                    <span>
                      {!n.read && <span style={{ color: "var(--navy-light)", fontWeight: 700, marginRight: "0.3rem" }}>●</span>}
                      Someone {typeLabel(n.type)}
                    </span>
                  </div>
                  <div style={{ color: "var(--muted)", fontSize: "0.78rem", marginTop: "0.2rem" }}>
                    {new Date(n.created_at).toLocaleDateString("en-IN", { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" })}
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  );
}
