import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { api } from '../lib/api';
import SEO from "../components/SEO";

const ORBITRON = `@import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@400;600;700;900&display=swap');`;
const BG    = "#070B16";
const CARD  = "#0C1220";
const CARD2 = "#141D2E";
const CYAN  = "#00C8FF";
const GOLD  = "#FFB300";
const TEXT  = "#E8EEFF";
const MUTED = "#7B8DB0";
const BORDER = "rgba(0,200,255,.14)";

const TOPICS = [
  { id: "sap-btp",  label: "SAP BTP" },
  { id: "sap-ai",   label: "SAP AI" },
];

const SIZES = [
  { players: 4, label: "4 Players", rounds: "2 rounds", icon: "⚔️" },
  { players: 8, label: "8 Players", rounds: "3 rounds", icon: "🏟️" },
];

const DIFFICULTY = [
  { questions: 5,  label: "Easy",   time: "30s/Q" },
  { questions: 10, label: "Normal", time: "30s/Q" },
  { questions: 15, label: "Hard",   time: "20s/Q" },
];

export default function ArenaTournamentLobby() {
  const navigate = useNavigate();
  const [tab, setTab]       = useState("create");  // create | join
  const [topic, setTopic]   = useState("sap-btp");
  const [size, setSize]     = useState(4);
  const [diff, setDiff]     = useState(1);          // index into DIFFICULTY
  const [code, setCode]     = useState("");
  const [busy, setBusy]     = useState(false);
  const [err, setErr]       = useState(null);

  async function handleCreate() {
    setBusy(true); setErr(null);
    try {
      const d = await api.post('/api/arena/tournament/create', {
        topic_id: topic,
        max_questions: DIFFICULTY[diff].questions,
        max_players: size,
      });
      navigate(`/arena/tournament/${d.tournament_id}`);
    } catch (e) { setErr(e.message); setBusy(false); }
  }

  async function handleJoin() {
    if (!code.trim()) return;
    setBusy(true); setErr(null);
    try {
      const d = await api.post('/api/arena/tournament/join', { room_code: code.trim().toUpperCase() });
      navigate(`/arena/tournament/${d.tournament_id}`);
    } catch (e) { setErr(e.message); setBusy(false); }
  }

  const btnBase = {
    fontFamily: "'Orbitron',sans-serif", fontSize: ".62rem", fontWeight: 700,
    letterSpacing: ".1em", border: "none", borderRadius: 4, cursor: "pointer",
    padding: ".55rem 1.2rem", transition: "opacity .15s",
  };

  return (
          <>
            <SEO title="Tournament Lobby" description="Create or join an Arena tournament on CodeGoLive." robots="noindex, nofollow" />
      <div style={{ maxWidth: 640, margin: "0 auto", padding: "2rem 1.5rem 4rem", background: BG, minHeight: "100vh" }}>
      <style>{ORBITRON}</style>

      <div style={{ marginBottom: "1.75rem" }}>
        <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".58rem",letterSpacing:".2em",color:CYAN,marginBottom:4 }}>ARENA · COMPETE</div>
        <h1 style={{ fontFamily:"'Orbitron',sans-serif",fontSize:"clamp(1.3rem,4vw,2rem)",fontWeight:900,margin:0,color:TEXT }}>
          🏟️ TOURNAMENT
        </h1>
        <p style={{ color:MUTED,margin:".4rem 0 0",fontSize:".82rem" }}>Single-elimination bracket. Last player standing wins.</p>
      </div>

      {/* Tabs */}
      <div style={{ display:"flex",gap:".5rem",marginBottom:"1.5rem",background:CARD2,padding:4,borderRadius:6,border:`1px solid ${BORDER}` }}>
        {["create","join"].map(t => (
          <button key={t} onClick={() => { setTab(t); setErr(null); }}
            style={{ ...btnBase, flex:1, background: tab===t ? CYAN : "transparent", color: tab===t ? "#070B16" : MUTED, padding:".5rem" }}>
            {t === "create" ? "🛠 CREATE" : "🔗 JOIN"}
          </button>
        ))}
      </div>

      {tab === "create" ? (
        <div style={{ display:"flex",flexDirection:"column",gap:"1.25rem" }}>
          {/* Topic */}
          <div style={{ background:CARD,border:`1px solid ${BORDER}`,borderRadius:8,padding:"1.1rem" }}>
            <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".58rem",letterSpacing:".14em",color:MUTED,marginBottom:".75rem" }}>TOPIC</div>
            <div style={{ display:"flex",gap:".5rem",flexWrap:"wrap" }}>
              {TOPICS.map(t => (
                <button key={t.id} onClick={() => setTopic(t.id)}
                  style={{ ...btnBase, background: topic===t.id ? "rgba(0,200,255,.15)" : CARD2, color: topic===t.id ? CYAN : MUTED, border: `1px solid ${topic===t.id ? CYAN : "rgba(255,255,255,.08)"}` }}>
                  {t.label}
                </button>
              ))}
            </div>
          </div>

          {/* Size */}
          <div style={{ background:CARD,border:`1px solid ${BORDER}`,borderRadius:8,padding:"1.1rem" }}>
            <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".58rem",letterSpacing:".14em",color:MUTED,marginBottom:".75rem" }}>BRACKET SIZE</div>
            <div style={{ display:"flex",gap:".75rem" }}>
              {SIZES.map(s => (
                <button key={s.players} onClick={() => setSize(s.players)}
                  style={{ ...btnBase, flex:1, display:"flex",flexDirection:"column",alignItems:"center",gap:4,padding:".75rem",
                    background: size===s.players ? "rgba(255,179,0,.12)" : CARD2,
                    color: size===s.players ? GOLD : MUTED,
                    border: `1px solid ${size===s.players ? GOLD+"66" : "rgba(255,255,255,.08)"}`,
                  }}>
                  <span style={{ fontSize:"1.4rem" }}>{s.icon}</span>
                  <span>{s.label}</span>
                  <span style={{ fontSize:".55rem",color:MUTED,fontWeight:400 }}>{s.rounds}</span>
                </button>
              ))}
            </div>
          </div>

          {/* Difficulty */}
          <div style={{ background:CARD,border:`1px solid ${BORDER}`,borderRadius:8,padding:"1.1rem" }}>
            <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".58rem",letterSpacing:".14em",color:MUTED,marginBottom:".75rem" }}>DIFFICULTY</div>
            <div style={{ display:"flex",gap:".5rem" }}>
              {DIFFICULTY.map((d, i) => (
                <button key={i} onClick={() => setDiff(i)}
                  style={{ ...btnBase, flex:1, display:"flex",flexDirection:"column",alignItems:"center",gap:3,padding:".6rem",
                    background: diff===i ? "rgba(0,230,118,.1)" : CARD2,
                    color: diff===i ? "#00E676" : MUTED,
                    border: `1px solid ${diff===i ? "#00E67666" : "rgba(255,255,255,.08)"}`,
                  }}>
                  <span>{d.label}</span>
                  <span style={{ fontSize:".55rem",fontWeight:400,color:MUTED }}>{d.questions}Q · {d.time}</span>
                </button>
              ))}
            </div>
          </div>

          {err && <div style={{ color:"#FF5722",fontSize:".78rem",padding:".5rem",background:"rgba(255,87,34,.08)",borderRadius:4 }}>{err}</div>}

          <button onClick={handleCreate} disabled={busy}
            style={{ ...btnBase, background: GOLD, color:"#070B16", padding:".8rem 1.5rem", fontSize:".72rem", opacity: busy?0.6:1, width:"100%" }}>
            {busy ? "CREATING…" : "🏆 CREATE TOURNAMENT"}
          </button>
        </div>
      ) : (
        <div style={{ display:"flex",flexDirection:"column",gap:"1rem" }}>
          <div style={{ background:CARD,border:`1px solid ${BORDER}`,borderRadius:8,padding:"1.25rem" }}>
            <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".58rem",letterSpacing:".14em",color:MUTED,marginBottom:".75rem" }}>TOURNAMENT CODE</div>
            <input
              value={code}
              onChange={e => setCode(e.target.value.toUpperCase())}
              onKeyDown={e => e.key === "Enter" && handleJoin()}
              placeholder="ENTER CODE"
              maxLength={8}
              style={{ width:"100%",boxSizing:"border-box",background:CARD2,border:`1px solid ${BORDER}`,borderRadius:4,padding:".75rem 1rem",color:TEXT,fontFamily:"'Orbitron',monospace",fontSize:"1.2rem",letterSpacing:".2em",textAlign:"center",outline:"none" }}
            />
          </div>

          {err && <div style={{ color:"#FF5722",fontSize:".78rem",padding:".5rem",background:"rgba(255,87,34,.08)",borderRadius:4 }}>{err}</div>}

          <button onClick={handleJoin} disabled={busy || !code.trim()}
            style={{ ...btnBase, background: CYAN, color:"#070B16", padding:".8rem", fontSize:".72rem", opacity: (busy||!code.trim())?0.5:1, width:"100%" }}>
            {busy ? "JOINING…" : "⚔️ JOIN TOURNAMENT"}
          </button>
        </div>
      )}

      <div style={{ marginTop:"2rem",display:"flex",gap:".75rem",flexWrap:"wrap" }}>
        <Link to="/arena" style={{ ...btnBase, background:CARD, border:`1px solid ${BORDER}`, color:TEXT, textDecoration:"none", display:"inline-block" }}>← ARENA HUB</Link>
      </div>
    </div>
    </>
  );
}
