import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "../lib/api";
import SEO from "../components/SEO";

const ORBITRON = `@import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@400;600;700;900&display=swap');`;

export default function ArenaQuests() {
  const navigate = useNavigate();
  const [quests, setQuests] = useState({ daily: [], weekly: [] });
  const [loading, setLoading] = useState(true);
  const [claiming, setClaiming] = useState(null);

  useEffect(() => {
    api.get("/api/arena/quests").then(d => { setQuests(d); setLoading(false); }).catch(() => setLoading(false));
  }, []);

  async function claim(id) {
    setClaiming(id);
    try {
      await api.post("/api/arena/quests/claim", { quest_id: id });
      const d = await api.get("/api/arena/quests");
      setQuests(d);
    } catch (e) {}
    setClaiming(null);
  }

  function QuestCard({ q }) {
    const pct = Math.min(100, Math.round((q.progress / q.target) * 100));
    const done = q.progress >= q.target;
    const claimed = !!q.claimed_at;
    const color = done && !claimed ? "#00E676" : "#00C8FF";
    const bd = done && !claimed ? "rgba(0,230,118,.35)" : "rgba(0,200,255,.18)";
    return (
            <SEO title="Daily Quests" description="Daily and weekly quests to earn bonus XP on CodeGoLive Arena." robots="noindex, nofollow" />
      <div style={{
        background: "#0C1220",
        border: `1px solid ${bd}`,
        borderLeft: `3px solid ${color}`,
        borderRadius: 6,
        padding: "1rem 1.25rem",
        opacity: claimed ? 0.5 : 1,
        transition: "opacity .2s",
      }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: ".6rem" }}>
          <div style={{ flex: 1, marginRight: ".75rem" }}>
            <div style={{ fontWeight: 600, color: "#E8EEFF", fontSize: ".9rem" }}>{q.title}</div>
            <div style={{ fontSize: ".74rem", color: "#7B8DB0", marginTop: 2, lineHeight: 1.4 }}>{q.description}</div>
          </div>
          <div style={{ textAlign: "right", flexShrink: 0 }}>
            <div style={{ fontFamily: "'Orbitron', monospace", fontSize: ".7rem", color: "#00C8FF", fontWeight: 700 }}>+{q.xp_reward} XP</div>
            <div style={{ fontFamily: "'Orbitron', monospace", fontSize: ".68rem", color: "#FFB300" }}>+{q.ap_reward} AP</div>
          </div>
        </div>
        <div style={{ height: 4, background: "#1E2B42", borderRadius: 2, overflow: "hidden", marginBottom: ".5rem" }}>
          <div style={{ height: "100%", width: `${pct}%`, background: done ? "#00E676" : "linear-gradient(90deg,#00C8FF,#006FFF)", borderRadius: 2, transition: "width .3s", boxShadow: done ? "0 0 6px rgba(0,230,118,.4)" : "none" }} />
        </div>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <span style={{ fontFamily: "'Orbitron', monospace", fontSize: ".65rem", color: "#7B8DB0" }}>{q.progress}/{q.target}</span>
          {done && !claimed && (
            <button onClick={() => claim(q.id)} disabled={claiming === q.id} style={{
              padding: ".3rem .85rem", background: "#00E676", color: "#070B16",
              border: "none", borderRadius: 4, fontFamily: "'Orbitron', sans-serif",
              fontWeight: 700, fontSize: ".6rem", letterSpacing: ".08em", cursor: "pointer",
              boxShadow: "0 0 10px rgba(0,230,118,.4)",
            }}>{claiming === q.id ? "…" : "CLAIM!"}</button>
          )}
          {claimed && <span style={{ fontFamily: "'Orbitron', sans-serif", fontSize: ".6rem", color: "#3A4A68", letterSpacing: ".08em" }}>✓ CLAIMED</span>}
        </div>
      </div>
    );
  }

  if (loading) return <div style={{ display: "flex", alignItems: "center", justifyContent: "center", minHeight: "60vh" }}><div style={{ fontFamily: "'Orbitron', sans-serif", color: "#00C8FF" }}>Loading quests…</div></div>;

  return (
    <div style={{ maxWidth: 1300, margin: "0 auto", padding: "1.75rem 2.5rem 3rem", width: "100%", boxSizing: "border-box" }}>
      <style>{ORBITRON}</style>
      <div style={{ display:"flex",alignItems:"center",marginBottom:"1rem" }}><button onClick={() => navigate("/arena")} style={{ display:"flex",alignItems:"center",gap:".4rem",background:"transparent",border:"1px solid rgba(0,200,255,.2)",borderRadius:4,padding:".35rem .85rem",color:"#7B8DB0",fontFamily:"'Orbitron', sans-serif",fontSize:".58rem",letterSpacing:".08em",cursor:"pointer" }}>← ARENA HUB</button></div>
      <div style={{ marginBottom: "1.5rem" }}>
        <div style={{ fontFamily: "'Orbitron', sans-serif", fontSize: ".6rem", letterSpacing: ".16em", color: "#00C8FF", marginBottom: 4 }}>ARENA</div>
        <h1 style={{ fontFamily: "'Orbitron', sans-serif", fontSize: "clamp(1.2rem,3vw,1.6rem)", fontWeight: 700, margin: 0, color: "#E8EEFF" }}>📋 Quests</h1>
        <p style={{ color: "#7B8DB0", margin: ".3rem 0 0", fontSize: ".82rem" }}>Complete missions to earn bonus XP and AP.</p>
      </div>

      <div style={{ fontFamily: "'Orbitron', sans-serif", fontSize: ".58rem", letterSpacing: ".14em", color: "#7B8DB0", marginBottom: ".6rem" }}>DAILY</div>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill,minmax(340px,1fr))", gap: ".65rem", marginBottom: "1.5rem" }}>
        {quests.daily.length === 0
          ? <p style={{ color: "#7B8DB0", background: "#0C1220", border: "1px solid rgba(0,200,255,.1)", borderRadius: 6, padding: "1.25rem", textAlign: "center", fontSize: ".82rem" }}>No daily quests available.</p>
          : quests.daily.map(q => <QuestCard key={q.id} q={q} />)}
      </div>

      <div style={{ fontFamily: "'Orbitron', sans-serif", fontSize: ".58rem", letterSpacing: ".14em", color: "#7B8DB0", marginBottom: ".6rem" }}>WEEKLY</div>
      <div style={{ display: "flex", flexDirection: "column", gap: ".65rem" }}>
        {quests.weekly.length === 0
          ? <p style={{ color: "#7B8DB0", background: "#0C1220", border: "1px solid rgba(0,200,255,.1)", borderRadius: 6, padding: "1.25rem", textAlign: "center", fontSize: ".82rem" }}>No weekly quests available.</p>
          : quests.weekly.map(q => <QuestCard key={q.id} q={q} />)}
      </div>
    </div>
  );
}
