const EXPIRY_HOURS = 2; // must match backend MATCH_EXPIRY_HOURS

const topicLabels = {
  "sap-btp": "SAP BTP",
  "sap-ai": "SAP AI Core",
  "dev-quickstart": "Dev Quickstart",
};

function getAgeInfo(iso) {
  const diffSec = (Date.now() - new Date(iso)) / 1000;
  const diffMin = diffSec / 60;
  const diffHrs = diffMin / 60;

  const expiresInSec = EXPIRY_HOURS * 3600 - diffSec;
  const expiresInMin = Math.max(0, Math.floor(expiresInSec / 60));

  let ageLabel;
  if (diffMin < 1)       ageLabel = "just now";
  else if (diffMin < 60) ageLabel = `${Math.floor(diffMin)}m ago`;
  else                   ageLabel = `${Math.floor(diffHrs)}h ago`;

  // freshness tier
  let tier;
  if (diffMin < 15)        tier = "fresh";   // < 15 min — green
  else if (diffMin < 60)   tier = "recent";  // < 1h   — teal
  else if (diffHrs < 1.5)  tier = "aging";   // < 1.5h — yellow
  else                     tier = "expiring"; // < 2h  — orange

  return { ageLabel, tier, expiresInMin, diffHrs };
}

const TIER_STYLES = {
  fresh:    { border: "#22C55E", glow: "rgba(34,197,94,0.25)",  badge: "🟢 FRESH",    badgeBg: "rgba(34,197,94,0.12)",   badgeColor: "#22C55E" },
  recent:   { border: "#00C8FF", glow: "rgba(0,200,255,0.18)",  badge: null,           badgeBg: null,                     badgeColor: "#00C8FF" },
  aging:    { border: "#FACC15", glow: "rgba(250,204,21,0.18)", badge: "⏳ AGING",     badgeBg: "rgba(250,204,21,0.1)",   badgeColor: "#FACC15" },
  expiring: { border: "#F97316", glow: "rgba(249,115,22,0.22)", badge: "🔥 EXPIRING",  badgeBg: "rgba(249,115,22,0.12)",  badgeColor: "#F97316" },
};

export default function ArenaChallengeCard({ match, onJoin }) {
  const { ageLabel, tier, expiresInMin } = getAgeInfo(match.created_at);
  const ts = TIER_STYLES[tier];

  return (
    <div style={{
      background: "#0C1220",
      border: `1px solid rgba(0,200,255,.14)`,
      borderLeft: `3px solid ${ts.border}`,
      borderRadius: 6,
      padding: "1rem 1.25rem",
      display: "flex",
      alignItems: "center",
      justifyContent: "space-between",
      gap: "1rem",
      boxShadow: `0 0 16px ${ts.glow}`,
      transition: "box-shadow .2s",
      position: "relative",
      overflow: "hidden",
    }}>
      {/* Subtle tier glow strip */}
      <div style={{
        position: "absolute", left: 0, top: 0, bottom: 0, width: 3,
        background: ts.border,
        boxShadow: `0 0 10px ${ts.border}`,
      }} />

      {/* Left: info */}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: "flex", alignItems: "center", gap: ".5rem", flexWrap: "wrap", marginBottom: 4 }}>
          <span style={{
            fontFamily: "'Orbitron', sans-serif", fontWeight: 700,
            fontSize: ".82rem", color: "#E8EEFF", letterSpacing: ".04em",
          }}>
            {topicLabels[match.topic_id] || match.topic_id}
          </span>
          {ts.badge && (
            <span style={{
              fontSize: ".58rem", fontFamily: "'Orbitron', sans-serif",
              fontWeight: 700, letterSpacing: ".1em",
              padding: ".15rem .45rem", borderRadius: 3,
              background: ts.badgeBg, color: ts.badgeColor,
              border: `1px solid ${ts.badgeColor}40`,
            }}>
              {ts.badge}
            </span>
          )}
        </div>

        <div style={{ fontSize: ".72rem", color: "#7B8DB0", display: "flex", gap: ".75rem", flexWrap: "wrap" }}>
          <span>{match.max_questions} questions</span>
          <span style={{ color: ts.badgeColor || "#7B8DB0" }}>⏱ {ageLabel}</span>
          {tier === "expiring" && (
            <span style={{ color: "#F97316" }}>
              · expires in ~{expiresInMin}m
            </span>
          )}
        </div>
      </div>

      {/* Right: code + join */}
      <div style={{ display: "flex", alignItems: "center", gap: ".75rem", flexShrink: 0 }}>
        <code style={{
          background: "#141D2E", border: `1px solid ${ts.border}40`,
          padding: ".2rem .6rem", borderRadius: 4,
          fontFamily: "'Orbitron', monospace", fontSize: ".8rem",
          letterSpacing: ".12em", color: ts.badgeColor || "#00C8FF",
        }}>
          {match.room_code}
        </code>
        <button
          onClick={onJoin}
          style={{
            padding: ".4rem 1rem",
            background: tier === "expiring" ? "#F97316" : "#00C8FF",
            color: "#070B16",
            border: "none", borderRadius: 4,
            fontFamily: "'Orbitron', sans-serif", fontWeight: 700,
            fontSize: ".62rem", letterSpacing: ".08em", cursor: "pointer",
            boxShadow: tier === "expiring"
              ? "0 0 12px rgba(249,115,22,0.4)"
              : "0 0 12px rgba(0,200,255,0.3)",
            transition: "all .2s",
          }}
        >
          JOIN →
        </button>
      </div>
    </div>
  );
}
