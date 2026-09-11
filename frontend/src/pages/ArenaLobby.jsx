import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "../lib/api";
import ArenaChallengeCard from "../components/arena/ArenaChallengeCard";

const ORBITRON = `@import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@400;600;700;900&display=swap');`;

export default function ArenaLobby() {
  const navigate = useNavigate();
  const [tab, setTab] = useState("create");
  const [roomCode, setRoomCode] = useState("");
  const [topic, setTopic] = useState("sap-btp");
  const [questions, setQuestions] = useState(10);
  const [difficulty, setDifficulty] = useState("normal");
  const [openMatches, setOpenMatches] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => { if (tab === "browse") fetchOpen(); }, [tab]);

  async function fetchOpen() {
    try { const data = await api.get("/api/arena/match/open"); setOpenMatches(data); }
    catch (e) { setOpenMatches([]); }
  }

  async function createMatch() {
    setLoading(true); setError("");
    try {
      const preset = DIFFICULTY_PRESETS.find(d => d.key === difficulty) || DIFFICULTY_PRESETS[1];
      const data = await api.post("/api/arena/match/create", { topic_id: topic, max_questions: preset.questions });
      navigate(`/arena/match/${data.match_id}`);
    } catch (e) { setError(e.message); setLoading(false); }
  }

  async function joinMatch(code) {
    setLoading(true); setError("");
    try {
      const data = await api.post("/api/arena/match/join", { room_code: code || roomCode });
      navigate(`/arena/match/${data.match_id}`);
    } catch (e) { setError(e.message); setLoading(false); }
  }

  const DIFFICULTY_PRESETS = [
    { key: "easy",   label: "Easy",   icon: "🟢", questions: 5,  seconds: 30, desc: "5 Qs · 30s each · Perfect to start" },
    { key: "normal", label: "Normal", icon: "🔵", questions: 10, seconds: 30, desc: "10 Qs · 30s each · Standard match" },
    { key: "hard",   label: "Hard",   icon: "🟠", questions: 15, seconds: 20, desc: "15 Qs · 20s each · Fast and intense" },
    { key: "expert", label: "Expert", icon: "🔴", questions: 20, seconds: 15, desc: "20 Qs · 15s each · Pros only" },
  ];

  const TOPICS = [
    { value: "sap-btp", label: "SAP BTP" },
    { value: "sap-ai", label: "SAP AI Core" },
    { value: "dev-quickstart", label: "Dev Quickstart" },
  ];

  const TABS = [["create","⚡ Create"],["join","🔑 Join"],["browse","🌐 Browse"]];

  return (
    <div style={{ maxWidth: 1400, margin: "0 auto", padding: "1.75rem 2.5rem 3rem", width: "100%", boxSizing: "border-box" }}>
      <style>{ORBITRON}</style>

      {/* Back navigation */}
      <div style={{ display: "flex", alignItems: "center", marginBottom: "1.25rem" }}>
        <button onClick={() => navigate("/arena")} style={{
          display: "flex", alignItems: "center", gap: ".4rem",
          background: "transparent", border: "1px solid rgba(0,200,255,.2)",
          borderRadius: 4, padding: ".35rem .85rem", color: "#7B8DB0",
          fontFamily: "'Orbitron', sans-serif", fontSize: ".58rem", letterSpacing: ".08em",
          cursor: "pointer",
        }}>← ARENA HUB</button>
      </div>

      <div style={{ marginBottom: "1.5rem" }}>
        <div style={{ fontFamily: "'Orbitron', sans-serif", fontSize: ".6rem", letterSpacing: ".16em", color: "#00C8FF", marginBottom: 4 }}>ARENA</div>
        <h1 style={{ fontFamily: "'Orbitron', sans-serif", fontSize: "clamp(1.2rem,3vw,1.6rem)", fontWeight: 700, margin: 0, color: "#E8EEFF" }}>⚔️ Battle Lobby</h1>
        <p style={{ color: "#7B8DB0", margin: ".3rem 0 0", fontSize: ".82rem" }}>Challenge others. Prove your knowledge.</p>
      </div>

      {/* Tabs */}
      <div style={{ display: "flex", gap: ".4rem", marginBottom: "1.5rem", borderBottom: "1px solid rgba(0,200,255,.12)", paddingBottom: 0 }}>
        {TABS.map(([id, label]) => (
          <button key={id} onClick={() => setTab(id)} style={{
            padding: ".5rem 1rem", border: "none", background: "none",
            borderBottom: tab === id ? "2px solid #00C8FF" : "2px solid transparent",
            color: tab === id ? "#00C8FF" : "#7B8DB0",
            fontFamily: "'Orbitron', sans-serif", fontSize: ".62rem", letterSpacing: ".08em",
            fontWeight: tab === id ? 700 : 400, cursor: "pointer", transition: "all .15s",
          }}>{label}</button>
        ))}
      </div>

      {error && (
        <div style={{ background: "rgba(255,68,51,.12)", border: "1px solid rgba(255,68,51,.4)", color: "#ff6655", padding: ".75rem 1rem", borderRadius: 6, marginBottom: "1rem", fontSize: ".85rem" }}>
          {error}
        </div>
      )}

      {/* Create Match */}
      {tab === "create" && (
        <div style={{ background: "#0C1220", border: "1px solid rgba(0,200,255,.18)", borderLeft: "3px solid #00C8FF", borderRadius: 6, padding: "1.5rem" }}>
          <div style={{ fontFamily: "'Orbitron', sans-serif", fontSize: ".72rem", fontWeight: 700, color: "#E8EEFF", marginBottom: "1.25rem", letterSpacing: ".04em" }}>CREATE MATCH ROOM</div>
          <div style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
            <div>
              <label style={{ fontFamily: "'Orbitron', sans-serif", fontSize: ".58rem", letterSpacing: ".1em", color: "#7B8DB0", display: "block", marginBottom: 6 }}>TOPIC</label>
              <select value={topic} onChange={e => setTopic(e.target.value)} style={{
                width: "100%", padding: ".65rem .8rem", borderRadius: 4,
                border: "1px solid rgba(0,200,255,.18)", background: "#141D2E", color: "#E8EEFF",
                fontFamily: "'Orbitron', sans-serif", fontSize: ".72rem",
              }}>
                {TOPICS.map(t => <option key={t.value} value={t.value}>{t.label}</option>)}
              </select>
            </div>
            <div>
              <label style={{ fontFamily: "'Orbitron', sans-serif", fontSize: ".58rem", letterSpacing: ".1em", color: "#7B8DB0", display: "block", marginBottom: 8 }}>DIFFICULTY</label>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: ".5rem" }}>
                {DIFFICULTY_PRESETS.map(d => (
                  <button key={d.key} onClick={() => setDifficulty(d.key)} style={{
                    padding: ".65rem .75rem", borderRadius: 6, cursor: "pointer",
                    background: difficulty === d.key ? "rgba(0,200,255,.1)" : "#141D2E",
                    border: difficulty === d.key ? "1px solid rgba(0,200,255,.5)" : "1px solid rgba(0,200,255,.12)",
                    textAlign: "left", transition: "all .15s",
                  }}>
                    <div style={{ display: "flex", alignItems: "center", gap: ".4rem", marginBottom: 3 }}>
                      <span>{d.icon}</span>
                      <span style={{ fontFamily: "'Orbitron', sans-serif", fontSize: ".62rem", fontWeight: 700, color: difficulty === d.key ? "#00C8FF" : "#E8EEFF", letterSpacing: ".06em" }}>{d.label.toUpperCase()}</span>
                    </div>
                    <div style={{ fontSize: ".68rem", color: "#7B8DB0", lineHeight: 1.3 }}>{d.desc}</div>
                  </button>
                ))}
              </div>
            </div>
            <button onClick={createMatch} disabled={loading} style={{
              padding: ".8rem 1.5rem", background: "#00C8FF", color: "#070B16",
              border: "none", borderRadius: 4, fontFamily: "'Orbitron', sans-serif",
              fontWeight: 700, fontSize: ".72rem", letterSpacing: ".08em",
              cursor: "pointer", boxShadow: "0 0 16px rgba(0,200,255,.35)",
              opacity: loading ? 0.7 : 1,
            }}>
              {loading ? "CREATING…" : "⚡ CREATE MATCH ROOM"}
            </button>
          </div>
        </div>
      )}

      {/* Join by Code */}
      {tab === "join" && (
        <div style={{ background: "#0C1220", border: "1px solid rgba(0,200,255,.18)", borderLeft: "3px solid #00C8FF", borderRadius: 6, padding: "1.5rem" }}>
          <div style={{ fontFamily: "'Orbitron', sans-serif", fontSize: ".72rem", fontWeight: 700, color: "#E8EEFF", marginBottom: "1.25rem", letterSpacing: ".04em" }}>ENTER ROOM CODE</div>
          <div style={{ display: "flex", gap: ".75rem", flexWrap: "wrap" }}>
            <input
              value={roomCode} onChange={e => setRoomCode(e.target.value.toUpperCase())}
              placeholder="e.g. AB3X7K"
              onKeyDown={e => e.key === "Enter" && joinMatch()}
              style={{
                flex: 1, minWidth: 160, padding: ".65rem .9rem",
                borderRadius: 4, border: "1px solid rgba(0,200,255,.25)",
                background: "#141D2E", color: "#00C8FF",
                fontSize: "1.3rem", letterSpacing: ".15em", fontFamily: "'Orbitron', monospace",
              }}
            />
            <button onClick={() => joinMatch()} disabled={loading || !roomCode} style={{
              padding: ".65rem 1.4rem", background: "#00C8FF", color: "#070B16",
              border: "none", borderRadius: 4, fontFamily: "'Orbitron', sans-serif",
              fontWeight: 700, fontSize: ".68rem", letterSpacing: ".08em",
              cursor: loading || !roomCode ? "not-allowed" : "pointer",
              opacity: !roomCode ? 0.5 : 1,
            }}>
              {loading ? "JOINING…" : "JOIN"}
            </button>
          </div>
        </div>
      )}

      {/* Browse Open Matches */}
      {tab === "browse" && (
        <div>
          {openMatches.length === 0 ? (
            <div style={{ textAlign: "center", padding: "3rem", color: "#7B8DB0", background: "#0C1220", border: "1px solid rgba(0,200,255,.1)", borderRadius: 6 }}>
              <div style={{ fontSize: "2.5rem", marginBottom: ".75rem" }}>🎯</div>
              <p style={{ fontFamily: "'Orbitron', sans-serif", fontSize: ".75rem" }}>No open matches right now.<br />Create one and share the code!</p>
            </div>
          ) : (
            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))", gap: ".75rem" }}>
              {openMatches.map(m => (
                <ArenaChallengeCard key={m.id} match={m} onJoin={() => joinMatch(m.room_code)} />
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
