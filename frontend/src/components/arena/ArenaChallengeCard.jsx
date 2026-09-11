export default function ArenaChallengeCard({ match, onJoin }) {
  const topicLabels = { "sap-btp": "SAP BTP", "sap-ai": "SAP AI Core", "dev-quickstart": "Dev Quickstart" };
  const ago = (iso) => {
    const diff = (Date.now() - new Date(iso)) / 1000;
    if (diff < 60) return "just now";
    if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
    return `${Math.floor(diff / 3600)}h ago`;
  };
  return (
    <div style={{
      background: "#0C1220",
      border: "1px solid rgba(0,200,255,.18)",
      borderLeft: "3px solid #00C8FF",
      borderRadius: 6,
      padding: "1rem 1.25rem",
      display: "flex", alignItems: "center", justifyContent: "space-between", gap: "1rem",
    }}>
      <div>
        <div style={{ fontFamily: "'Orbitron', sans-serif", fontWeight: 700, fontSize: ".82rem", color: "#E8EEFF", letterSpacing: ".04em" }}>
          {topicLabels[match.topic_id] || match.topic_id}
        </div>
        <div style={{ fontSize: ".72rem", color: "#7B8DB0", marginTop: 3 }}>
          {match.max_questions} questions · {ago(match.created_at)}
        </div>
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: ".75rem" }}>
        <code style={{
          background: "#141D2E", border: "1px solid rgba(0,200,255,.2)",
          padding: ".2rem .6rem", borderRadius: 4,
          fontFamily: "'Orbitron', monospace", fontSize: ".8rem",
          letterSpacing: ".12em", color: "#00C8FF",
        }}>{match.room_code}</code>
        <button onClick={onJoin} style={{
          padding: ".4rem 1rem", background: "#00C8FF", color: "#070B16",
          border: "none", borderRadius: 4,
          fontFamily: "'Orbitron', sans-serif", fontWeight: 700,
          fontSize: ".62rem", letterSpacing: ".08em", cursor: "pointer",
        }}>JOIN →</button>
      </div>
    </div>
  );
}
