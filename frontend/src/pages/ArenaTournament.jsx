import { useState, useEffect, useRef, useCallback } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../lib/AuthContext';
import { api } from '../lib/api';
import SEO from "../components/SEO";

const ORBITRON = `@import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@400;600;700;900&display=swap');`;
const BG    = "#070B16";
const CARD  = "#0C1220";
const CARD2 = "#141D2E";
const CYAN  = "#00C8FF";
const GREEN = "#00E676";
const GOLD  = "#FFB300";
const RED   = "#FF5722";
const PURPLE = "#A855F7";
const TEXT  = "#E8EEFF";
const MUTED = "#7B8DB0";
const BORDER = "rgba(0,200,255,.14)";

function getInitials(name) {
  if (!name) return '?';
  return name.split(' ').map(w => w[0]).join('').toUpperCase().slice(0, 2);
}

function Avatar({ name, color = CYAN, size = 32 }) {
  return (
      <div style={{
      width: size, height: size, borderRadius: "50%",
      background: `${color}22`, border: `1px solid ${color}55`,
      display: "flex", alignItems: "center", justifyContent: "center",
      fontSize: size * 0.32, fontWeight: 700, color, fontFamily: "'Orbitron',sans-serif",
      flexShrink: 0,
    }}>{getInitials(name)}</div>
  );
}

function MatchCard({ match, players, userId, onNavigate }) {
  const p1 = players.find(p => p.user_id === match.player1_id);
  const p2 = players.find(p => p.user_id === match.player2_id);
  const isMyMatch = match.player1_id === userId || match.player2_id === userId;
  const isActive  = match.status === "active";
  const isFinished = match.status === "finished";

  const borderColor = isMyMatch && isActive ? CYAN
    : isFinished ? "rgba(0,230,118,.2)"
    : BORDER;

  return (
    <div style={{
      background: CARD2, border: `1px solid ${borderColor}`,
      borderRadius: 8, overflow: "hidden", minWidth: 200,
      boxShadow: isMyMatch && isActive ? `0 0 16px ${CYAN}22` : "none",
    }}>
      {/* Status strip */}
      <div style={{
        padding: "3px 10px", fontSize: ".55rem", fontFamily: "'Orbitron',sans-serif",
        letterSpacing: ".1em", fontWeight: 700,
        background: isActive ? `${CYAN}18` : isFinished ? `${GREEN}15` : "rgba(255,255,255,.04)",
        color: isActive ? CYAN : isFinished ? GREEN : MUTED,
      }}>
        {isActive ? "🔴 LIVE" : isFinished ? "✅ DONE" : "⏳ PENDING"}
      </div>

      {/* Player rows */}
      {[{ player: p1, id: match.player1_id }, { player: p2, id: match.player2_id }].map(({ player, id }, i) => {
        const isWinner = match.winner_id === id;
        const isLoser  = isFinished && match.winner_id && match.winner_id !== id;
        return (
          <div key={i} style={{
            display: "flex", alignItems: "center", gap: ".5rem",
            padding: ".4rem .7rem",
            background: isWinner ? "rgba(0,230,118,.07)" : isLoser ? "rgba(0,0,0,.1)" : "transparent",
            borderBottom: i === 0 ? "1px solid rgba(255,255,255,.06)" : "none",
          }}>
            <Avatar name={player?.display_name} color={id === userId ? CYAN : "#5A6A8A"} size={26} />
            <span style={{
              flex: 1, fontSize: ".75rem", fontWeight: id === userId ? 700 : 400,
              color: isWinner ? GREEN : isLoser ? MUTED : TEXT,
              overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap",
            }}>
              {player?.display_name || "TBD"} {id === userId && <span style={{ color: CYAN, fontSize: ".6rem" }}>(you)</span>}
            </span>
            {isWinner && <span style={{ fontSize: ".75rem" }}>🏆</span>}
            {isLoser  && <span style={{ fontSize: ".65rem", color: MUTED }}>✗</span>}
          </div>
        );
      })}

      {/* Go to match CTA */}
      {isMyMatch && isActive && (
        <div style={{ padding: ".5rem .7rem", borderTop: "1px solid rgba(0,200,255,.1)" }}>
          <button onClick={() => onNavigate(match.match_id)}
            style={{ width: "100%", background: CYAN, color: "#070B16", border: "none", borderRadius: 3, padding: ".4rem", fontFamily: "'Orbitron',sans-serif", fontSize: ".6rem", fontWeight: 700, letterSpacing: ".08em", cursor: "pointer" }}>
            ⚔️ ENTER MATCH
          </button>
        </div>
      )}
    </div>
  );
}

function BracketRound({ title, matches, players, userId, onNavigate }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: ".75rem", minWidth: 215 }}>
      <div style={{ fontFamily: "'Orbitron',sans-serif", fontSize: ".58rem", letterSpacing: ".16em", color: MUTED, textAlign: "center", paddingBottom: ".25rem", borderBottom: `1px solid ${BORDER}` }}>
        {title}
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: ".75rem", justifyContent: "space-around", flex: 1 }}>
        {matches.map(m => (
          <MatchCard key={m.id} match={m} players={players} userId={userId} onNavigate={onNavigate} />
        ))}
      </div>
    </div>
  );
}

export default function ArenaTournament() {
  const { tournamentId } = useParams();
  const { session } = useAuth();
  const navigate = useNavigate();
  const userId = session?.user?.id;

  const [data, setData]   = useState(null);
  const [busy, setBusy]   = useState(false);
  const [err,  setErr]    = useState(null);
  const pollRef = useRef(null);

  const load = useCallback(async () => {
    try {
      const d = await api.get(`/api/arena/tournament/${tournamentId}`);
      setData(d);
    } catch (e) { setErr(e.message); }
  }, [tournamentId]);

  useEffect(() => {
    load();
    pollRef.current = setInterval(load, 4000);
    return () => clearInterval(pollRef.current);
  }, [load]);

  async function handleStart() {
    setBusy(true); setErr(null);
    try {
      await api.post(`/api/arena/tournament/${tournamentId}/start`, {});
      await load();
    } catch (e) { setErr(e.message); }
    setBusy(false);
  }

  function copyCode() {
    if (data?.tournament?.room_code) {
      navigator.clipboard?.writeText(data.tournament.room_code);
    }
  }

  if (!data) return (
    <div style={{ display:"flex",alignItems:"center",justifyContent:"center",minHeight:"60vh",background:BG }}>
      <div style={{ fontFamily:"'Orbitron',sans-serif",color:CYAN,fontSize:".8rem",letterSpacing:".1em" }}>LOADING TOURNAMENT…</div>
    </div>
  );

  const { tournament: t, players, bracket, my_active_match, is_host, player_count } = data;

  // Group bracket by round
  const rounds = {};
  for (const m of bracket) {
    if (!rounds[m.round]) rounds[m.round] = [];
    rounds[m.round].push(m);
  }
  const roundNums = Object.keys(rounds).map(Number).sort((a, b) => a - b);

  const totalRounds = t.max_players === 4 ? 2 : 3;
  const roundNames  = totalRounds === 2
    ? { 1: "SEMI-FINALS", 2: "FINAL" }
    : { 1: "QUARTER-FINALS", 2: "SEMI-FINALS", 3: "FINAL" };

  const statusColor = t.status === "waiting" ? GOLD : t.status === "active" ? CYAN : GREEN;
  const statusLabel = t.status === "waiting" ? "⏳ WAITING FOR PLAYERS"
    : t.status === "active" ? "🔴 IN PROGRESS"
    : "✅ FINISHED";

  const champion = t.winner_id ? players.find(p => p.user_id === t.winner_id) : null;

  return (
    <>
      <SEO title="Tournament" description="CodeGoLive Arena tournament bracket and live match." robots="noindex, nofollow" />
      <div style={{ maxWidth: 1100, margin: "0 auto", padding: "1.75rem 1.5rem 4rem", background: BG, minHeight: "100vh" }}>
      <style>{ORBITRON}</style>

      {/* Header */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "1.5rem", gap: "1rem", flexWrap: "wrap" }}>
        <div>
          <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".58rem",letterSpacing:".2em",color:CYAN,marginBottom:4 }}>ARENA · TOURNAMENT</div>
          <h1 style={{ fontFamily:"'Orbitron',sans-serif",fontSize:"clamp(1.2rem,3vw,1.7rem)",fontWeight:900,margin:0,color:TEXT }}>
            🏟️ {t.max_players}-PLAYER BRACKET
          </h1>
          <div style={{ display:"flex",alignItems:"center",gap:"1rem",marginTop:".4rem",flexWrap:"wrap" }}>
            <span style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".6rem",color:statusColor,letterSpacing:".1em" }}>{statusLabel}</span>
            <span style={{ fontSize:".72rem",color:MUTED }}>Round {t.current_round}/{totalRounds}</span>
          </div>
        </div>
        {/* Room code */}
        {t.status === "waiting" && (
          <button onClick={copyCode} title="Click to copy"
            style={{ background:CARD,border:`1px solid ${GOLD}44`,borderRadius:6,padding:".6rem 1rem",cursor:"pointer",textAlign:"center" }}>
            <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".52rem",color:MUTED,marginBottom:2 }}>ROOM CODE</div>
            <div style={{ fontFamily:"'Orbitron',monospace",fontSize:"1.4rem",fontWeight:900,color:GOLD,letterSpacing:".15em" }}>{t.room_code}</div>
            <div style={{ fontSize:".55rem",color:MUTED,marginTop:2 }}>click to copy</div>
          </button>
        )}
      </div>

      {/* Champion banner */}
      {champion && (
        <div style={{ background:`linear-gradient(135deg, rgba(255,179,0,.12), rgba(255,107,53,.08))`, border:`1px solid ${GOLD}44`, borderRadius:10, padding:"1.25rem", marginBottom:"1.25rem", textAlign:"center" }}>
          <div style={{ fontSize:"3rem",marginBottom:".25rem" }}>👑</div>
          <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".6rem",letterSpacing:".2em",color:GOLD,marginBottom:4 }}>CHAMPION</div>
          <div style={{ fontSize:"1.2rem",fontWeight:700,color:TEXT }}>{champion.display_name}</div>
          {champion.user_id === userId && <div style={{ color:GOLD,fontSize:".78rem",marginTop:".25rem" }}>That's you! 🎉</div>}
        </div>
      )}

      {/* Waiting lobby */}
      {t.status === "waiting" && (
        <div style={{ background:CARD,border:`1px solid ${BORDER}`,borderRadius:10,padding:"1.25rem",marginBottom:"1.25rem" }}>
          <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".6rem",letterSpacing:".14em",color:MUTED,marginBottom:".75rem" }}>
            PLAYERS ({player_count}/{t.max_players})
          </div>
          <div style={{ display:"flex",flexWrap:"wrap",gap:".6rem",marginBottom:"1rem" }}>
            {players.map(p => (
              <div key={p.user_id} style={{ display:"flex",alignItems:"center",gap:".5rem",background:CARD2,border:`1px solid ${p.user_id===userId?CYAN:BORDER}`,borderRadius:6,padding:".4rem .7rem" }}>
                <Avatar name={p.display_name} color={p.user_id===userId?CYAN:"#5A6A8A"} size={24} />
                <span style={{ fontSize:".78rem",color:p.user_id===userId?CYAN:TEXT }}>{p.display_name}</span>
                {p.is_host && <span style={{ fontSize:".55rem",color:GOLD,fontFamily:"'Orbitron',sans-serif" }}>HOST</span>}
              </div>
            ))}
            {Array.from({ length: Math.max(0, t.max_players - player_count) }).map((_, i) => (
              <div key={i} style={{ display:"flex",alignItems:"center",gap:".5rem",background:CARD2,border:`1px dashed rgba(255,255,255,.08)`,borderRadius:6,padding:".4rem .7rem",opacity:.5 }}>
                <div style={{ width:24,height:24,borderRadius:"50%",background:"rgba(255,255,255,.05)" }} />
                <span style={{ fontSize:".75rem",color:MUTED }}>Waiting…</span>
              </div>
            ))}
          </div>

          {is_host && player_count >= 4 && (
            <button onClick={handleStart} disabled={busy}
              style={{ width:"100%",background:GOLD,color:"#070B16",border:"none",borderRadius:4,padding:".75rem",fontFamily:"'Orbitron',sans-serif",fontSize:".68rem",fontWeight:700,letterSpacing:".1em",cursor:busy?"not-allowed":"pointer",opacity:busy?.6:1 }}>
              {busy ? "STARTING…" : "🚀 START TOURNAMENT"}
            </button>
          )}
          {is_host && player_count < 4 && (
            <div style={{ color:MUTED,fontSize:".75rem",textAlign:"center",padding:".5rem" }}>
              Need at least 4 players to start ({4 - player_count} more needed)
            </div>
          )}
          {!is_host && (
            <div style={{ color:MUTED,fontSize:".75rem",textAlign:"center",padding:".5rem" }}>
              Waiting for host to start the tournament…
            </div>
          )}
        </div>
      )}

      {/* My match CTA */}
      {my_active_match && (
        <div style={{ background:"rgba(0,200,255,.08)",border:`1px solid ${CYAN}44`,borderRadius:8,padding:"1rem 1.25rem",marginBottom:"1.25rem",display:"flex",justifyContent:"space-between",alignItems:"center",gap:"1rem",flexWrap:"wrap" }}>
          <div>
            <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".6rem",letterSpacing:".14em",color:CYAN,marginBottom:3 }}>YOUR MATCH IS READY</div>
            <div style={{ fontSize:".82rem",color:TEXT }}>It's your turn to battle!</div>
          </div>
          <button onClick={() => navigate(`/arena/match/${my_active_match}`)}
            style={{ background:CYAN,color:"#070B16",border:"none",borderRadius:4,padding:".65rem 1.25rem",fontFamily:"'Orbitron',sans-serif",fontSize:".68rem",fontWeight:700,letterSpacing:".1em",cursor:"pointer" }}>
            ⚔️ ENTER MATCH →
          </button>
        </div>
      )}

      {err && <div style={{ color:RED,fontSize:".78rem",padding:".5rem",background:"rgba(255,87,34,.08)",borderRadius:4,marginBottom:"1rem" }}>{err}</div>}

      {/* Bracket */}
      {roundNums.length > 0 && (
        <div>
          <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".6rem",letterSpacing:".16em",color:MUTED,marginBottom:".75rem" }}>BRACKET</div>
          <div style={{ display:"flex",gap:"2rem",overflowX:"auto",paddingBottom:"1rem",alignItems:"flex-start" }}>
            {roundNums.map(r => (
              <BracketRound
                key={r}
                title={roundNames[r] || `ROUND ${r}`}
                matches={rounds[r]}
                players={players}
                userId={userId}
                onNavigate={matchId => navigate(`/arena/match/${matchId}`)}
              />
            ))}
          </div>
        </div>
      )}

      {/* Nav */}
      <div style={{ marginTop:"2rem",display:"flex",gap:".75rem",flexWrap:"wrap" }}>
        <Link to="/arena" style={{ padding:".5rem 1rem",background:CARD,border:`1px solid ${BORDER}`,borderRadius:4,color:TEXT,textDecoration:"none",fontFamily:"'Orbitron',sans-serif",fontSize:".62rem",letterSpacing:".08em" }}>← ARENA HUB</Link>
        <Link to="/arena/tournament" style={{ padding:".5rem 1rem",background:CARD,border:`1px solid ${BORDER}`,borderRadius:4,color:TEXT,textDecoration:"none",fontFamily:"'Orbitron',sans-serif",fontSize:".62rem",letterSpacing:".08em" }}>🏟️ NEW TOURNAMENT</Link>
      </div>
    </div>
    </>
  );
}
