export default function ArenaProvokeModal({ onSelect, onClose }) {
  const TAUNTS = [
    { key: "too_slow",  emoji: "🐢", text: "Too slow!" },
    { key: "nice_try",  emoji: "😅", text: "Nice try!" },
    { key: "on_fire",   emoji: "🔥", text: "I'm on fire!" },
    { key: "scared",    emoji: "😱", text: "Are you scared?" },
    { key: "easy",      emoji: "😎", text: "Too easy." },
    { key: "not_bad",   emoji: "👏", text: "Not bad…" },
    { key: "gg",        emoji: "🤝", text: "GG!" },
  ];

  return (
    <div style={{
      position: "fixed", inset: 0, background: "rgba(0,0,0,0.72)",
      display: "flex", alignItems: "center", justifyContent: "center", zIndex: 1000,
    }} onClick={onClose}>
      <div style={{
        background: "#0C1220", border: "1px solid rgba(255,87,34,.35)",
        borderTop: "3px solid #FF5722",
        borderRadius: 8, padding: "1.5rem", minWidth: 280, maxWidth: 360,
        boxShadow: "0 0 40px rgba(255,87,34,.18)",
      }} onClick={e => e.stopPropagation()}>
        <div style={{ fontFamily: "'Orbitron', sans-serif", fontSize: ".75rem", fontWeight: 700, color: "#FF5722", letterSpacing: ".1em", marginBottom: "1.1rem" }}>⚡ PROVOKE YOUR RIVAL</div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: ".5rem" }}>
          {TAUNTS.map(t => (
            <button key={t.key} onClick={() => { onSelect(t.key); onClose(); }} style={{
              padding: ".6rem .75rem", border: "1px solid rgba(255,87,34,.2)",
              borderRadius: 6, background: "rgba(255,87,34,.06)",
              cursor: "pointer", fontWeight: 600, fontSize: ".82rem",
              color: "#E8EEFF", textAlign: "left",
              transition: "border-color .15s, background .15s",
            }}
            onMouseOver={e => { e.currentTarget.style.borderColor = "rgba(255,87,34,.5)"; e.currentTarget.style.background = "rgba(255,87,34,.12)"; }}
            onMouseOut={e => { e.currentTarget.style.borderColor = "rgba(255,87,34,.2)"; e.currentTarget.style.background = "rgba(255,87,34,.06)"; }}>
              {t.emoji} {t.text}
            </button>
          ))}
        </div>
        <button onClick={onClose} style={{
          marginTop: "1rem", width: "100%", padding: ".5rem",
          border: "1px solid rgba(0,200,255,.2)", borderRadius: 6,
          background: "transparent", cursor: "pointer",
          color: "#7B8DB0", fontFamily: "'Orbitron', sans-serif",
          fontSize: ".58rem", letterSpacing: ".08em",
        }}>CANCEL</button>
      </div>
    </div>
  );
}
