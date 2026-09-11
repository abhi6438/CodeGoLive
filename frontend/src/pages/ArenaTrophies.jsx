import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "../lib/api";

const ORBITRON = `@import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@400;600;700;900&display=swap');`;

const RARITY = {
  common:    { color: "#A0B8D0", glow: "rgba(160,184,208,.25)" },
  rare:      { color: "#00C8FF", glow: "rgba(0,200,255,.3)"   },
  epic:      { color: "#A855F7", glow: "rgba(168,85,247,.3)"  },
  legendary: { color: "#FFB300", glow: "rgba(255,179,0,.35)"  },
};

export default function ArenaTrophies() {
  const navigate = useNavigate();
  const [badges, setBadges] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get("/api/arena/trophies").then(d => { setBadges(d); setLoading(false); }).catch(() => setLoading(false));
  }, []);

  const unlocked = badges.filter(b => b.unlocked).length;

  if (loading) return <div style={{ display: "flex", alignItems: "center", justifyContent: "center", minHeight: "60vh" }}><div style={{ fontFamily: "'Orbitron', sans-serif", color: "#00C8FF" }}>Loading trophies…</div></div>;

  return (
    <div style={{ maxWidth: 1300, margin: "0 auto", padding: "1.75rem 2.5rem 3rem", width: "100%", boxSizing: "border-box" }}>
      <style>{ORBITRON}</style>
      <div style={{ display:"flex",alignItems:"center",marginBottom:"1.25rem" }}><button onClick={() => navigate("/arena")} style={{ display:"flex",alignItems:"center",gap:".4rem",background:"transparent",border:"1px solid rgba(0,200,255,.2)",borderRadius:4,padding:".35rem .85rem",color:"#7B8DB0",fontFamily:"'Orbitron', sans-serif",fontSize:".58rem",letterSpacing:".08em",cursor:"pointer" }}>← ARENA HUB</button></div>
      <div style={{ marginBottom: "1.25rem" }}>
        <div style={{ fontFamily: "'Orbitron', sans-serif", fontSize: ".6rem", letterSpacing: ".16em", color: "#00C8FF", marginBottom: 4 }}>ARENA</div>
        <h1 style={{ fontFamily: "'Orbitron', sans-serif", fontSize: "clamp(1.2rem,3vw,1.6rem)", fontWeight: 700, margin: 0, color: "#E8EEFF" }}>🏆 Trophy Cabinet</h1>
        <p style={{ color: "#7B8DB0", margin: ".3rem 0 0", fontSize: ".82rem" }}>{unlocked} / {badges.length} badges unlocked</p>
      </div>

      {/* Progress bar */}
      <div style={{ marginBottom: "1.5rem" }}>
        <div style={{ height: 6, background: "#1E2B42", borderRadius: 3, overflow: "hidden" }}>
          <div style={{ height: "100%", width: `${badges.length ? (unlocked / badges.length) * 100 : 0}%`, background: "linear-gradient(90deg,#00C8FF,#006FFF)", borderRadius: 3, boxShadow: "0 0 8px rgba(0,200,255,.4)", transition: "width .5s" }} />
        </div>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(155px, 1fr))", gap: ".75rem" }}>
        {badges.map(b => {
          const r = RARITY[b.rarity] || RARITY.common;
          return (
            <div key={b.badge_key} style={{
              background: "#0C1220",
              border: b.unlocked ? `1px solid ${r.color}55` : "1px solid rgba(0,200,255,.08)",
              borderTop: b.unlocked ? `3px solid ${r.color}` : "3px solid #1E2B42",
              borderRadius: 6,
              padding: "1rem .9rem",
              textAlign: "center",
              opacity: b.unlocked ? 1 : 0.4,
              transition: "opacity .2s, box-shadow .2s",
              boxShadow: b.unlocked ? `0 0 18px ${r.glow}` : "none",
            }}>
              <div style={{ fontSize: "2rem", marginBottom: ".5rem", filter: b.unlocked ? "none" : "grayscale(1)" }}>{b.emoji}</div>
              <div style={{ fontWeight: 600, fontSize: ".82rem", color: "#E8EEFF", marginBottom: ".25rem" }}>{b.title}</div>
              <div style={{ fontSize: ".68rem", color: "#7B8DB0", marginBottom: ".4rem", lineHeight: 1.35 }}>{b.description}</div>
              <div style={{ fontFamily: "'Orbitron', sans-serif", fontSize: ".55rem", fontWeight: 700, letterSpacing: ".1em", color: r.color }}>{b.rarity.toUpperCase()}</div>
              {b.unlocked && b.unlocked_at && (
                <div style={{ fontSize: ".6rem", color: "#3A4A68", marginTop: ".25rem" }}>{new Date(b.unlocked_at).toLocaleDateString()}</div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
