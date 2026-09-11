import { useState, useEffect, useRef } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useAuth } from "../lib/AuthContext";
import { api } from "../lib/api";
import SEO from "../components/SEO";

const ORBITRON = `@import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@400;600;700;900&display=swap');`;

// Derive per-question results from turn_change events
function buildQuestionLog(events, players, totalQuestions) {
  const turnEvs = events.filter(e => e.event_type === "turn_change");
  const log = {}; // { qIdx: [{userId, result, reason}] }

  for (const ev of turnEvs) {
    const p = ev.payload || {};
    const reason = p.reason;
    if (reason === "start") continue;

    // Which question was just answered?
    const qAnswered = reason === "correct" ? (p.question_index - 1) : p.question_index;
    if (qAnswered < 0) continue;

    if (!log[qAnswered]) log[qAnswered] = [];
    log[qAnswered].push({ userId: ev.user_id, result: reason }); // "correct"|"wrong"|"timeout"
  }

  const rows = [];
  for (let i = 0; i < totalQuestions; i++) {
    rows.push({ qIdx: i, attempts: log[i] || [] });
  }
  return rows;
}

export default function ArenaResult() {
  const { matchId } = useParams();
  const { session } = useAuth();
  const user = session?.user;
  const navigate = useNavigate();
  const [matchData, setMatchData]   = useState(null);
  const [events, setEvents]         = useState([]);
  const [loading, setLoading]       = useState(true);
  const [rematching, setRematching] = useState(false);
  const [showBreakdown, setShowBreakdown] = useState(false);
  const [confettiFired, setConfettiFired] = useState(false);
  const heroRef = useRef(null);

  useEffect(() => {
    Promise.all([
      api.get(`/api/arena/match/${matchId}`),
      api.get(`/api/arena/match/${matchId}/events`),
    ]).then(([d, evs]) => {
      setMatchData(d);
      setEvents(evs);
      setLoading(false);
    }).catch(() => setLoading(false));
  }, [matchId]);

  // Confetti burst for winner
  useEffect(() => {
    if (!matchData || confettiFired) return;
    const players = (matchData.players || []).sort((a, b) => (b.score_xp || 0) - (a.score_xp || 0));
    if (players[0]?.user_id === user?.id) {
      setConfettiFired(true);
      spawnConfetti();
    }
  }, [matchData]);

  function spawnConfetti() {
    const colors = ["#00C8FF", "#00E676", "#FFB300", "#FF5722", "#A855F7", "#E8EEFF"];
    const container = document.getElementById("confetti-container");
    if (!container) return;
    for (let i = 0; i < 80; i++) {
      const el = document.createElement("div");
      const size = 6 + Math.random() * 8;
      el.style.cssText = `
        position:absolute; width:${size}px; height:${size}px;
        background:${colors[Math.floor(Math.random() * colors.length)]};
        border-radius:${Math.random() > 0.5 ? "50%" : "2px"};
        left:${Math.random() * 100}%; top:-10px;
        animation: fall ${1.5 + Math.random() * 2}s linear ${Math.random() * 0.5}s forwards;
        opacity:0.9;
      `;
      container.appendChild(el);
      setTimeout(() => el.remove(), 4000);
    }
  }

  async function doRematch() {
    setRematching(true);
    try {
      const res = await api.post(`/api/arena/match/${matchId}/rematch`, {});
      navigate(`/arena/match/${res.match_id}`);
    } catch (e) {
      alert("Could not create rematch: " + (e.message || "Try again"));
      setRematching(false);
    }
  }

  if (loading) return (
    <>
      <SEO title="Match Result" description="Your CodeGoLive Arena match result and XP breakdown." robots="noindex, nofollow" />
      <div style={{ display:"flex", alignItems:"center", justifyContent:"center", minHeight:"60vh" }}>
        <div style={{ fontFamily:"'Orbitron',sans-serif", color:"#00C8FF" }}>Loading results…</div>
      </div>
    </>
  );

  if (!matchData) return (
    <div style={{ maxWidth:860, margin:"2rem auto", padding:"1rem", textAlign:"center" }}>
      <p style={{ color:"#7B8DB0" }}>Match not found.</p>
      <button onClick={() => navigate("/arena")} style={{ marginTop:"1rem", padding:".6rem 1.4rem", background:"#00C8FF", color:"#070B16", border:"none", borderRadius:4, fontFamily:"'Orbitron',sans-serif", fontSize:".68rem", fontWeight:700, cursor:"pointer" }}>BACK TO ARENA</button>
    </div>
  );

  const players  = (matchData.players || []).sort((a, b) => (b.score_xp || 0) - (a.score_xp || 0));
  const winner   = players[0];
  const isWinner = winner?.user_id === user?.id;
  const myPlayer = players.find(p => p.user_id === user?.id);
  const opponent = players.find(p => p.user_id !== user?.id);
  const isDraw   = players.length >= 2 && (players[0].score_xp || 0) === (players[1].score_xp || 0);
  const totalQuestions = matchData.match?.max_questions || 10;
  const qLog = buildQuestionLog(events, players, totalQuestions);
  const myAccuracy = myPlayer?.total_answered
    ? Math.round(((myPlayer.correct_count || 0) / myPlayer.total_answered) * 100)
    : 0;
  const MEDAL = ["🥇","🥈","🥉"];

  return (
    <>
      <SEO title="Match Result" description="Your CodeGoLive Arena match result and XP breakdown." robots="noindex, nofollow" />
      <div style={{ maxWidth:1100, margin:"0 auto", padding:"1.5rem 2rem 4rem", width:"100%", boxSizing:"border-box", background:"#070B16", minHeight:"100vh" }}>
      <style>{ORBITRON}{`
        @keyframes fall {
          to { transform: translateY(100vh) rotate(360deg); opacity: 0; }
        }
        @keyframes slideUp {
          from { opacity:0; transform:translateY(24px); }
          to   { opacity:1; transform:translateY(0); }
        }
        @keyframes pulse {
          0%,100%{transform:scale(1);} 50%{transform:scale(1.06);}
        }
        @keyframes shimmer {
          0%{background-position:200% center;}
          100%{background-position:-200% center;}
        }
        .result-card { animation: slideUp .5s ease both; }
        .result-card:nth-child(2) { animation-delay:.1s; }
        .result-card:nth-child(3) { animation-delay:.2s; }
        .result-card:nth-child(4) { animation-delay:.3s; }
      `}</style>

      {/* Confetti layer */}
      <div id="confetti-container" style={{ position:"fixed", inset:0, pointerEvents:"none", zIndex:999, overflow:"hidden" }} />

      {/* Back nav */}
      <div style={{ display:"flex", alignItems:"center", marginBottom:"1.25rem" }}>
        <button onClick={() => navigate("/arena")} style={{ display:"flex",alignItems:"center",gap:".4rem",background:"transparent",border:"1px solid rgba(0,200,255,.2)",borderRadius:4,padding:".35rem .85rem",color:"#7B8DB0",fontFamily:"'Orbitron',sans-serif",fontSize:".58rem",letterSpacing:".08em",cursor:"pointer" }}>← ARENA HUB</button>
      </div>

      {/* Hero banner */}
      <div className="result-card" style={{
        textAlign:"center", borderRadius:12, padding:"2.5rem 2rem 2rem",
        marginBottom:"1.25rem", position:"relative", overflow:"hidden",
        background: isDraw
          ? "linear-gradient(135deg,rgba(255,179,0,.08),#0C1220)"
          : isWinner
            ? "linear-gradient(135deg,rgba(0,230,118,.1),#0C1220 60%)"
            : "linear-gradient(135deg,rgba(255,87,34,.06),#0C1220 60%)",
        border: `1px solid ${isDraw ? "rgba(255,179,0,.35)" : isWinner ? "rgba(0,230,118,.4)" : "rgba(255,87,34,.25)"}`,
        boxShadow: isWinner ? "0 0 40px rgba(0,230,118,.08)" : "none",
      }}>
        <div style={{ position:"absolute", inset:0, pointerEvents:"none",
          background:`radial-gradient(ellipse 70% 60% at 50% -10%, ${isWinner ? "rgba(0,230,118,.07)" : isDraw ? "rgba(255,179,0,.05)" : "rgba(255,87,34,.04)"} 0%, transparent 70%)` }} />

        <div style={{ fontSize:"4rem", marginBottom:".5rem",
          animation: isWinner ? "pulse 1.5s ease infinite" : "none" }}>
          {isDraw ? "🤝" : isWinner ? "🏆" : "💀"}
        </div>

        <h1 style={{
          fontFamily:"'Orbitron',sans-serif", fontWeight:900, letterSpacing:".06em",
          margin:"0 0 .5rem", fontSize:"clamp(1.6rem,5vw,2.4rem)",
          background: isDraw
            ? "linear-gradient(90deg,#FFB300,#FF9800,#FFB300)"
            : isWinner
              ? "linear-gradient(90deg,#00E676,#00C8FF,#00E676)"
              : "linear-gradient(90deg,#FF5722,#FF8A65,#FF5722)",
          backgroundSize:"200% auto",
          WebkitBackgroundClip:"text", WebkitTextFillColor:"transparent",
          animation:"shimmer 3s linear infinite",
        }}>
          {isDraw ? "IT'S A DRAW!" : isWinner ? "VICTORY!" : "DEFEATED"}
        </h1>

        <p style={{ margin:0, color:"#7B8DB0", fontSize:".9rem" }}>
          {isDraw
            ? "Both players matched perfectly."
            : isWinner
              ? `You defeated ${opponent?.display_name || "your opponent"}!`
              : `${winner?.display_name || "Opponent"} wins this round. Come back stronger!`}
        </p>
      </div>

      {/* Score cards */}
      <div className="result-card" style={{ display:"flex", gap:".75rem", marginBottom:"1.25rem", flexWrap:"wrap" }}>
        {players.map((p, i) => {
          const isMe = p.user_id === user?.id;
          const isTopPlayer = i === 0 && !isDraw;
          const acc = p.total_answered
            ? Math.round(((p.correct_count || 0) / p.total_answered) * 100) : 0;
          return (
            <div key={p.user_id} style={{
              flex:1, minWidth:180,
              background: isTopPlayer ? "rgba(0,230,118,.06)" : isMe ? "rgba(0,200,255,.04)" : "#0C1220",
              border: `1px solid ${isTopPlayer ? "rgba(0,230,118,.35)" : isMe ? "rgba(0,200,255,.3)" : "rgba(0,200,255,.12)"}`,
              borderTop: `3px solid ${isTopPlayer ? "#00E676" : isMe ? "#00C8FF" : "#1E2B42"}`,
              borderRadius:8, padding:"1rem 1.1rem",
              boxShadow: isTopPlayer ? "0 0 20px rgba(0,230,118,.1)" : "none",
            }}>
              <div style={{ display:"flex", alignItems:"center", gap:".5rem", marginBottom:".6rem" }}>
                <span style={{ fontSize:"1.4rem" }}>{MEDAL[i] || `${i+1}.`}</span>
                <div>
                  <div style={{ fontFamily:"'Orbitron',sans-serif", fontSize:".62rem", color: isMe?"#00C8FF":"#7B8DB0", fontWeight:700 }}>
                    {isMe ? "YOU" : "OPPONENT"}
                  </div>
                  <div style={{ color:"#E8EEFF", fontWeight:600, fontSize:".88rem" }}>{p.display_name}</div>
                </div>
              </div>
              <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:".4rem" }}>
                {[
                  { label:"XP", value: `${p.score_xp || 0}`, color:"#00C8FF" },
                  { label:"AP", value: `+${p.score_ap || 0}`, color:"#FFB300" },
                  { label:"CORRECT", value: `${p.correct_count || 0}/${p.total_answered || 0}`, color:"#00E676" },
                  { label:"ACCURACY", value: `${acc}%`, color:"#A855F7" },
                ].map(s => (
                  <div key={s.label} style={{ background:"rgba(255,255,255,.03)", borderRadius:4, padding:".4rem .5rem" }}>
                    <div style={{ fontFamily:"'Orbitron',monospace", fontSize:".85rem", fontWeight:700, color:s.color }}>{s.value}</div>
                    <div style={{ fontFamily:"'Orbitron',sans-serif", fontSize:".48rem", letterSpacing:".08em", color:"#7B8DB0", marginTop:2 }}>{s.label}</div>
                  </div>
                ))}
              </div>
            </div>
          );
        })}
      </div>

      {/* My stat tiles */}
      {myPlayer && (
        <div className="result-card" style={{ display:"grid", gridTemplateColumns:"repeat(4,1fr)", gap:".65rem", marginBottom:"1.25rem" }}>
          {[
            { label:"XP EARNED",   value:`+${myPlayer.score_xp || 0}`,  color:"#00C8FF", bg:"rgba(0,200,255,.07)",  bd:"rgba(0,200,255,.2)"  },
            { label:"AP EARNED",   value:`+${myPlayer.score_ap || 0}`,  color:"#FFB300", bg:"rgba(255,179,0,.07)",  bd:"rgba(255,179,0,.2)"  },
            { label:"ACCURACY",    value:`${myAccuracy}%`,               color:"#A855F7", bg:"rgba(168,85,247,.07)", bd:"rgba(168,85,247,.2)" },
            { label:"STREAK BEST", value:`×${myPlayer.streak || 0}`,    color:"#FF5722", bg:"rgba(255,87,34,.07)",  bd:"rgba(255,87,34,.2)"  },
          ].map(s => (
            <div key={s.label} style={{ background:s.bg, border:`1px solid ${s.bd}`, borderRadius:6, padding:".85rem .75rem", textAlign:"center" }}>
              <div style={{ fontFamily:"'Orbitron',monospace", fontSize:"1.3rem", fontWeight:800, color:s.color }}>{s.value}</div>
              <div style={{ fontFamily:"'Orbitron',sans-serif", fontSize:".5rem", letterSpacing:".1em", color:"#7B8DB0", marginTop:3 }}>{s.label}</div>
            </div>
          ))}
        </div>
      )}

      {/* Question breakdown toggle */}
      {qLog.some(r => r.attempts.length > 0) && (
        <div className="result-card" style={{ marginBottom:"1.25rem" }}>
          <button
            onClick={() => setShowBreakdown(v => !v)}
            style={{ width:"100%", padding:".7rem 1rem", background:"#0C1220", border:"1px solid rgba(0,200,255,.2)", borderRadius: showBreakdown ? "8px 8px 0 0" : 8, cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"space-between", fontFamily:"'Orbitron',sans-serif", fontSize:".62rem", letterSpacing:".1em", color:"#7B8DB0" }}>
            <span>📋 QUESTION BREAKDOWN</span>
            <span style={{ color:"#00C8FF" }}>{showBreakdown ? "▲ HIDE" : "▼ SHOW"}</span>
          </button>

          {showBreakdown && (
            <div style={{ background:"#0C1220", border:"1px solid rgba(0,200,255,.2)", borderTop:"none", borderRadius:"0 0 8px 8px", overflow:"hidden" }}>
              {/* Header */}
              <div style={{ display:"grid", gridTemplateColumns:"3rem 1fr repeat(2,5rem)", padding:".5rem 1rem", borderBottom:"1px solid rgba(0,200,255,.1)", fontFamily:"'Orbitron',sans-serif", fontSize:".52rem", letterSpacing:".1em", color:"#7B8DB0" }}>
                <span>#</span><span>QUESTION</span>
                {players.map(p => (
                  <span key={p.user_id} style={{ textAlign:"center", color: p.user_id===user?.id?"#00C8FF":"#7B8DB0" }}>
                    {p.user_id===user?.id?"YOU":p.display_name?.split(" ")[0]||"OPP"}
                  </span>
                ))}
              </div>
              {qLog.map(({ qIdx, attempts }) => {
                const qObj = (matchData.questions || [])[qIdx];
                return (
                  <div key={qIdx} style={{ display:"grid", gridTemplateColumns:"3rem 1fr repeat(2,5rem)", padding:".55rem 1rem", borderBottom:"1px solid rgba(0,200,255,.06)", alignItems:"center" }}>
                    <span style={{ fontFamily:"'Orbitron',monospace", fontSize:".7rem", color:"#7B8DB0" }}>Q{qIdx+1}</span>
                    <span style={{ fontSize:".78rem", color:"#E8EEFF", paddingRight:"1rem", overflow:"hidden", textOverflow:"ellipsis", whiteSpace:"nowrap" }}>
                      {qObj?.question || "—"}
                    </span>
                    {players.map(p => {
                      const att = attempts.filter(a => a.userId === p.user_id);
                      const lastAtt = att[att.length - 1];
                      const icon = !lastAtt ? "—"
                        : lastAtt.result === "correct" ? "✓"
                        : lastAtt.result === "timeout" ? "⏰"
                        : "✗";
                      const color = !lastAtt ? "#3A4860"
                        : lastAtt.result === "correct" ? "#00E676"
                        : lastAtt.result === "timeout" ? "#FFB300"
                        : "#FF5722";
                      return (
                        <span key={p.user_id} style={{ textAlign:"center", fontFamily:"'Orbitron',monospace", fontSize:".9rem", fontWeight:700, color }}>
                          {icon}
                          {att.length > 1 && <span style={{ fontSize:".48rem", color:"#7B8DB0", marginLeft:2 }}>×{att.length}</span>}
                        </span>
                      );
                    })}
                  </div>
                );
              })}
            </div>
          )}
        </div>
      )}

      {/* Action buttons */}
      <div className="result-card" style={{ display:"flex", gap:".75rem", flexWrap:"wrap" }}>
        <button
          onClick={doRematch}
          disabled={rematching}
          style={{ flex:1, minWidth:150, padding:".85rem", background: rematching ? "#1E2B42" : "#00C8FF", color: rematching ? "#7B8DB0" : "#070B16", border:"none", borderRadius:6, fontFamily:"'Orbitron',sans-serif", fontWeight:700, fontSize:".7rem", letterSpacing:".08em", cursor: rematching ? "not-allowed" : "pointer", boxShadow: rematching ? "none" : "0 0 20px rgba(0,200,255,.35)", transition:"all .2s" }}>
          {rematching ? "CREATING…" : "⚔️ REMATCH"}
        </button>
        <button onClick={() => navigate("/arena/lobby")} style={{ flex:1, minWidth:150, padding:".85rem", background:"rgba(0,230,118,.1)", color:"#00E676", border:"1px solid rgba(0,230,118,.3)", borderRadius:6, fontFamily:"'Orbitron',sans-serif", fontSize:".7rem", letterSpacing:".08em", cursor:"pointer" }}>
          🎮 NEW MATCH
        </button>
        <button onClick={() => navigate("/arena")} style={{ flex:1, minWidth:150, padding:".85rem", background:"#0C1220", color:"#E8EEFF", border:"1px solid rgba(0,200,255,.2)", borderRadius:6, fontFamily:"'Orbitron',sans-serif", fontSize:".7rem", letterSpacing:".08em", cursor:"pointer" }}>
          ARENA HUB
        </button>
        <button onClick={() => navigate("/arena/history")} style={{ flex:1, minWidth:150, padding:".85rem", background:"rgba(0,200,255,.08)", color:"#00C8FF", border:"1px solid rgba(0,200,255,.25)", borderRadius:6, fontFamily:"'Orbitron',sans-serif", fontSize:".7rem", letterSpacing:".08em", cursor:"pointer" }}>
          📜 HISTORY
        </button>
        <button onClick={() => navigate("/arena/ranks")} style={{ flex:1, minWidth:150, padding:".85rem", background:"rgba(168,85,247,.1)", color:"#A855F7", border:"1px solid rgba(168,85,247,.25)", borderRadius:6, fontFamily:"'Orbitron',sans-serif", fontSize:".7rem", letterSpacing:".08em", cursor:"pointer" }}>
          📊 LEADERBOARD
        </button>
      </div>
    </div>
    </>
  );
}
