import { useState } from "react";

export default function ArenaChatPanel({ matchId, events, onSend, onTaunt }) {
  const [msg, setMsg] = useState("");
  const [showTaunts, setShowTaunts] = useState(false);

  const TAUNTS = [
    { key: "too_slow",  label: "🐢 Too slow!" },
    { key: "nice_try",  label: "😅 Nice try!" },
    { key: "on_fire",   label: "🔥 I'm on fire!" },
    { key: "scared",    label: "😱 Are you scared?" },
    { key: "easy",      label: "😎 Too easy." },
    { key: "gg",        label: "🤝 GG!" },
  ];

  const chatEvents = events.filter(e => e.event_type === "chat" || e.event_type === "taunt");

  function send() {
    if (!msg.trim()) return;
    onSend(msg.trim());
    setMsg("");
  }

  return (
    <div style={{
      display: "flex", flexDirection: "column", height: "100%",
      background: "#0C1220", border: "1px solid rgba(0,200,255,.15)", borderRadius: 8,
      overflow: "hidden",
    }}>
      <div style={{ padding: "0.6rem 0.75rem", borderBottom: "1px solid rgba(0,200,255,.1)", fontWeight: 700, fontSize: "0.75rem", fontFamily: "'Orbitron', sans-serif", letterSpacing: ".06em", color: "#E8EEFF" }}>
        💬 Chat
      </div>

      {/* Messages */}
      <div style={{ flex: 1, overflowY: "auto", padding: "0.75rem", display: "flex", flexDirection: "column", gap: "0.4rem" }}>
        {chatEvents.length === 0 && (
          <div style={{ color: "#7B8DB0", fontSize: "0.78rem", textAlign: "center", marginTop: "1rem" }}>No messages yet</div>
        )}
        {chatEvents.map((e, i) => (
          <div key={i} style={{ fontSize: "0.82rem" }}>
            {e.event_type === "taunt" ? (
              <span style={{ background: "#141D2E", borderRadius: 6, padding: "0.15rem 0.4rem", fontWeight: 600 }}>
                {e.payload?.emoji} {e.payload?.text}
              </span>
            ) : (
              <span style={{ color: "#7B8DB0" }}>{e.payload?.message}</span>
            )}
          </div>
        ))}
      </div>

      {/* Taunt buttons */}
      {showTaunts && (
        <div style={{ padding: "0.5rem", borderTop: "1px solid rgba(0,200,255,.12)", display: "flex", flexWrap: "wrap", gap: "0.35rem" }}>
          {TAUNTS.map(t => (
            <button key={t.key} onClick={() => { onTaunt(t.key); setShowTaunts(false); }} style={{
              padding: "0.25rem 0.6rem", fontSize: "0.75rem", border: "1px solid rgba(0,200,255,.12)",
              borderRadius: 6, background: "#141D2E", cursor: "pointer", color: "#E8EEFF",
            }}>{t.label}</button>
          ))}
        </div>
      )}

      {/* Input */}
      <div style={{ display: "flex", gap: "0.4rem", padding: "0.5rem", borderTop: "1px solid rgba(0,200,255,.12)" }}>
        <button onClick={() => setShowTaunts(s => !s)} title="Taunts" style={{
          padding: "0.3rem 0.5rem", border: "1px solid rgba(0,200,255,.12)", borderRadius: 6,
          background: showTaunts ? "#00C8FF" : "#141D2E", cursor: "pointer", fontSize: "0.85rem",
          color: showTaunts ? "#fff" : "#E8EEFF",
        }}>⚡</button>
        <input
          value={msg} onChange={e => setMsg(e.target.value)}
          onKeyDown={e => e.key === "Enter" && send()}
          placeholder="Type…" style={{
            flex: 1, padding: "0.3rem 0.5rem", border: "1px solid rgba(0,200,255,.12)",
            borderRadius: 6, background: "#141D2E", color: "#E8EEFF", fontSize: "0.82rem",
          }}
        />
        <button onClick={send} disabled={!msg.trim()} style={{
          padding: "0.3rem 0.6rem", background: "#00C8FF", color: "#fff",
          border: "none", borderRadius: 6, cursor: "pointer", fontWeight: 600, fontSize: "0.82rem",
        }}>Send</button>
      </div>
    </div>
  );
}
