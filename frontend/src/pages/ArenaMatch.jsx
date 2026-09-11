import { useState, useEffect, useRef, useCallback } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useAuth } from "../lib/AuthContext";
import { api } from "../lib/api";
import ArenaProvokeModal from "../components/arena/ArenaProvokeModal";
import SEO from "../components/SEO";

const ORBITRON = `@import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@400;600;700;900&display=swap');`;
const QUESTION_TIME = 30; // default; overridden per match below
function getQuestionTime(maxQ) {
  if (maxQ <= 5)  return 30; // easy
  if (maxQ <= 10) return 30; // normal
  if (maxQ <= 15) return 20; // hard
  return 15;                 // expert
}

export default function ArenaMatch() {
  const { matchId } = useParams();
  const { session } = useAuth();
  const user = session?.user;
  const navigate = useNavigate();

  // ── Core match state ──────────────────────────────────────────────
  const [matchData, setMatchData] = useState(null);
  const [questions, setQuestions]   = useState([]);
  const [players, setPlayers]       = useState([]);
  const [phase, setPhase]           = useState("waiting"); // waiting | active | finished
  const [loading, setLoading]       = useState(true);

  // ── Turn-based state (derived from events) ────────────────────────
  const [currentQIdx, setCurrentQIdx]       = useState(0);
  const [activePlayerId, setActivePlayerId] = useState(null);
  const [totalQuestions, setTotalQuestions] = useState(10);

  // ── Per-turn UI state ─────────────────────────────────────────────
  const [timeLeft, setTimeLeft]     = useState(30); // initial; reset uses questionTime
  const [selectedIdx, setSelectedIdx] = useState(null);   // chosen option
  const [turnResult, setTurnResult] = useState(null);     // {correct, reason} after answer submitted
  const [submitted, setSubmitted]   = useState(false);    // locked after submit until it's MY turn again
  const [showProvoke, setShowProvoke] = useState(false);
  const [events, setEvents]         = useState([]);

  // ── Power-ups (one use each, per match) ────────────────────────
  const [pwUsed, setPwUsed] = useState({ freeze: false, skip: false, fifty: false, shield: false });
  const [shielded, setShielded] = useState(false);    // shield absorbs next wrong answer
  const [hiddenOpts, setHiddenOpts] = useState([]);   // options hidden by 50/50

  const timerRef  = useRef(null);
  const pollRef   = useRef(null);
  const qStartRef = useRef(new Date().toISOString());
  const submittedRef = useRef(false);  // guard double-submit
  const prevQIdxRef  = useRef(-1);        // for turn-reset detection
  const prevActiveRef = useRef(null);     // for turn-reset detection
  const matchDataRef   = useRef(null);     // fallback when no turn_change events yet
  const autoStartedRef = useRef(false);    // prevent duplicate auto-start calls

  // ── Fetch match + questions ───────────────────────────────────────
  const fetchMatch = useCallback(async () => {
    try {
      const data = await api.get(`/api/arena/match/${matchId}`);
      setMatchData(data);
      matchDataRef.current = data;
      setPlayers(data.players || []);
      // Auto-start: game begins automatically when 2 players are present
      if (data.match?.status === "waiting" && (data.players || []).length >= 2
          && data.match?.host_id === user?.id && !autoStartedRef.current) {
        autoStartedRef.current = true;
        startMatch();
      }
      if (data.match?.status === "active" && data.questions?.length) {
        setQuestions(data.questions);
        if (phase === "waiting") setPhase("active");
      }
      if (data.match?.status === "finished") {
        clearInterval(pollRef.current);
        clearInterval(timerRef.current);
        setTimeout(() => navigate(`/arena/result/${matchId}`), 1500);
      }
    } catch {}
    setLoading(false);
  }, [matchId, phase, navigate]);

  // ── Fetch events to get current turn state ────────────────────────
  const fetchTurnState = useCallback(async () => {
    try {
      const evs = await api.get(`/api/arena/match/${matchId}/events`);
      setEvents(evs);

      // Find latest turn_change event
      const turnEvs = evs.filter(e => e.event_type === "turn_change");
      if (turnEvs.length) {
        const latest = turnEvs[turnEvs.length - 1].payload;
        const newQIdx = latest.question_index ?? 0;
        const newActive = latest.active_player_id;
        const newTotal = latest.total_questions ?? totalQuestions;

        // Update turn state — reset is handled by the effect below
        setCurrentQIdx(newQIdx);
        setActivePlayerId(newActive);
        setTotalQuestions(newTotal);
      } else {
        // No turn_change event yet — fallback: host goes first at question 0
        const m = matchDataRef.current?.match;
        if (m?.status === "active" && m?.host_id) {
          setActivePlayerId(m.host_id);
          setCurrentQIdx(m.current_question_index || 0);
        }
      }

      // Check for match_end
      const endEv = evs.find(e => e.event_type === "match_end");
      if (endEv) {
        clearInterval(pollRef.current);
        clearInterval(timerRef.current);
        setTimeout(() => navigate(`/arena/result/${matchId}`), 1500);
      }
    } catch {}
  }, [matchId, totalQuestions, navigate]);

  // ── Detect turn changes and reset per-turn UI ───────────────────
  // submitted / submittedRef only clear when it's EXPLICITLY my turn —
  // so a wrong answer locks the player out until the turn rotates back to them.
  useEffect(() => {
    const qChanged      = prevQIdxRef.current  !== -1   && prevQIdxRef.current  !== currentQIdx;
    const activeChanged = prevActiveRef.current !== null && prevActiveRef.current !== activePlayerId;
    if (qChanged || activeChanged) {
      setSelectedIdx(null);
      setTurnResult(null);
      setTimeLeft(questionTime);
      setHiddenOpts([]);
      qStartRef.current = new Date().toISOString();
      // Only unlock the player when it is explicitly THEIR turn again
      if (activePlayerId === user?.id) {
        submittedRef.current = false;
        setSubmitted(false);
      }
    }
    prevQIdxRef.current  = currentQIdx;
    prevActiveRef.current = activePlayerId;
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentQIdx, activePlayerId]);

  // ── Polling ───────────────────────────────────────────────────────
  useEffect(() => {
    fetchMatch();
    fetchTurnState();
    pollRef.current = setInterval(() => {
      fetchMatch();
      fetchTurnState();
    }, 2000);
    return () => clearInterval(pollRef.current);
  }, [fetchMatch, fetchTurnState]);

  // ── Timer: only runs for active player ───────────────────────────
  const isMyTurn = activePlayerId === user?.id;

  useEffect(() => {
    clearInterval(timerRef.current);
    if (phase !== "active" || !isMyTurn || selectedIdx !== null || turnResult !== null) return;

    timerRef.current = setInterval(() => {
      setTimeLeft(t => {
        if (t <= 1) {
          clearInterval(timerRef.current);
          handleTimeout();
          return 0;
        }
        return t - 1;
      });
    }, 1000);
    return () => clearInterval(timerRef.current);
  }, [phase, isMyTurn, activePlayerId, currentQIdx, selectedIdx, turnResult]);

  // ── Submit answer ─────────────────────────────────────────────────
  async function submitAnswer(answerIndex) {
    if (submittedRef.current) return;
    submittedRef.current = true;
    setSubmitted(true);           // reactive lock so disabled prop updates immediately
    clearInterval(timerRef.current);
    setSelectedIdx(answerIndex);

    const q = questions[currentQIdx];
    if (!q) return;

    try {
      const res = await api.post("/api/arena/match/answer", {
        match_id: matchId,
        question_id: q.id,
        answer_index: answerIndex,
        time_remaining: timeLeft,
        question_sent_at: qStartRef.current,
      });
      // Shield: absorb a wrong answer — unlock player and don't show wrong result
      if (!res.correct && shielded) {
        setShielded(false);
        submittedRef.current = false;
        setSubmitted(false);
        setSelectedIdx(null);
        setTurnResult(null);
        setTimeLeft(questionTime);
        return;
      }
      setTurnResult({ correct: res.correct, timeout: false });
      if (res.match_ended) {
        setTimeout(() => navigate(`/arena/result/${matchId}`), 2000);
      }
    } catch (e) {
      // Server rejected (400 = not your turn) or network error.
      // Keep submitted=true so the player stays locked.
      // The turn-change useEffect will unlock them when it's their turn again.
      console.error("submitAnswer error:", e?.message || e);
    }
  }

  async function handleTimeout() {
    if (submittedRef.current) return;
    submittedRef.current = true;
    setSubmitted(true);
    setTurnResult({ correct: false, timeout: true });
    try {
      await api.post("/api/arena/match/answer", {
        match_id: matchId,
        question_id: questions[currentQIdx]?.id || "",
        answer_index: -1,
        time_remaining: 0,
        question_sent_at: qStartRef.current,
      });
    } catch {}
  }

  // ── Power-ups ───────────────────────────────────────────────────────
  function usePowerUp(key) {
    if (pwUsed[key] || !isMyTurn || submitted || turnResult) return;
    setPwUsed(prev => ({ ...prev, [key]: true }));
    if (key === 'freeze') {
      setTimeLeft(t => Math.min(t + 15, questionTime + 15));
    } else if (key === 'skip') {
      // Treat as a timeout — call answer with index -1
      if (submittedRef.current) return;
      submittedRef.current = true;
      setSubmitted(true);
      clearInterval(timerRef.current);
      setTurnResult({ correct: false, timeout: true });
      api.post('/api/arena/match/answer', {
        match_id: matchId,
        question_id: questions[currentQIdx]?.id || '',
        answer_index: -1,
        time_remaining: 0,
        question_sent_at: qStartRef.current,
      }).catch(() => {});
    } else if (key === 'fifty') {
      // Call backend to safely get which 2 wrong options to hide
      const q = questions[currentQIdx];
      if (!q) return;
      api.get(`/api/arena/match/${matchId}/fifty/${q.id}`)
        .then(data => { setHiddenOpts(data.hide || []); })
        .catch(() => {
          // fallback: hide random 2 (indices, best-effort)
          const opts = q.options || [];
          const indices = opts.map((_,i) => i);
          const toHide = indices.sort(() => Math.random() - 0.5).slice(0, 2);
          setHiddenOpts(toHide);
        });
    } else if (key === 'shield') {
      setShielded(true);
    }
  }

  // ── Start match (host only) ───────────────────────────────────────
  async function startMatch() {
    try {
      const data = await api.post(`/api/arena/match/${matchId}/start`, {});
      setQuestions(data.questions || []);
      setPhase("active");
    } catch (e) { alert(e.message); }
  }

  // ── Provoke ────────────────────────────────────────────────────────
  async function sendTaunt(key) {
    try { await api.post("/api/arena/match/taunt", { match_id: matchId, taunt_key: key }); } catch {}
  }

  // ── Scores from player rows ────────────────────────────────────────
  const scoresMap = {};
  players.forEach(p => { scoresMap[p.user_id] = p; });

  const myPlayer    = scoresMap[user?.id];
  const otherPlayer = players.find(p => p.user_id !== user?.id);

  const q = questions[currentQIdx];
  const timerPct   = (timeLeft / questionTime) * 100;
  const timerColor = timeLeft > 15 ? "#00C8FF" : timeLeft > 7 ? "#FFB300" : "#FF5722";
  const isHost     = matchData?.match?.host_id === user?.id;
  // Spectator: logged-in user who is not one of the two players
  const isSpectator = phase !== "waiting" && players.length > 0 && !players.some(p => p.user_id === user?.id);
  // Dynamic question time based on difficulty (inferred from max_questions)
  const questionTime = getQuestionTime(matchData?.match?.max_questions || 10);

  // ── Option button color ────────────────────────────────────────────
  function optionStyle(idx) {
    const canClick = isMyTurn && !turnResult && selectedIdx === null && !submitted && !isSpectator;
    const base = {
      width: "100%", textAlign: "left", padding: ".9rem 1.1rem",
      border: "1px solid rgba(0,200,255,.2)", borderRadius: 8,
      background: "#0C1220", color: "#E8EEFF", cursor: canClick ? "pointer" : "not-allowed",
      fontFamily: "inherit", fontSize: ".92rem", lineHeight: 1.4,
      transition: "all .15s", opacity: canClick ? 1 : 0.5,
    };
    if (selectedIdx === idx) {
      if (turnResult?.correct)  return { ...base, background: "rgba(0,230,118,.15)", border: "1px solid #00E676", color: "#00E676" };
      if (!turnResult?.correct) return { ...base, background: "rgba(255,87,34,.15)", border: "1px solid #FF5722", color: "#FF5722" };
    }
    return base;
  }

  if (loading) return (
          <>
            <SEO title="Arena Match" description="Live 1v1 quiz battle on CodeGoLive Arena." robots="noindex, nofollow" />
      <div style={{ display:"flex",alignItems:"center",justifyContent:"center",minHeight:"60vh" }}>
      <div style={{ fontFamily:"'Orbitron',sans-serif",color:"#00C8FF" }}>Loading match…</div>
    </div>
  );

  return (
    <div style={{ maxWidth:1400, margin:"0 auto", width:"100%", boxSizing:"border-box", padding:"1.5rem 2.5rem 3rem" }}>
      <style>{ORBITRON}
        {`@keyframes pulse { 0%,100%{opacity:1;transform:scale(1)} 50%{opacity:.4;transform:scale(.75)} }`}
      </style>

      {/* Back nav */}
      <div style={{ display:"flex",alignItems:"center",marginBottom:"1rem" }}>
        <button onClick={() => navigate("/arena")} style={{ display:"flex",alignItems:"center",gap:".4rem",background:"transparent",border:"1px solid rgba(0,200,255,.2)",borderRadius:4,padding:".35rem .85rem",color:"#7B8DB0",fontFamily:"'Orbitron', sans-serif",fontSize:".58rem",letterSpacing:".08em",cursor:"pointer" }}>← ARENA HUB</button>
      </div>

      {/* Spectator banner */}
      {isSpectator && (
        <div style={{ display:"flex",alignItems:"center",gap:".65rem",background:"rgba(168,85,247,.08)",border:"1px solid rgba(168,85,247,.3)",borderRadius:6,padding:".55rem 1rem",marginBottom:"1rem" }}>
          <span style={{ fontSize:"1rem" }}>👁️</span>
          <div>
            <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".62rem",fontWeight:700,color:"#A855F7",letterSpacing:".1em" }}>SPECTATING</div>
            <div style={{ fontSize:".75rem",color:"#7B8DB0",marginTop:2 }}>You're watching this match live. Join a battle at <span style={{ color:"#00C8FF" }}>/arena/lobby</span></div>
          </div>
        </div>
      )}

      {/* Header */}
      <div style={{ display:"flex",alignItems:"center",justifyContent:"space-between",marginBottom:"1.25rem" }}>
        <div style={{ display:"flex",alignItems:"center",gap:".75rem" }}>
          <span style={{ fontFamily:"'Orbitron',sans-serif",fontWeight:700,fontSize:"1rem",color:"#E8EEFF" }}>⚔️ Arena Match</span>
          {matchData?.match?.room_code && (
            <code style={{ fontFamily:"'Orbitron',monospace",background:"#0C1220",border:"1px solid rgba(0,200,255,.25)",padding:".15rem .5rem",borderRadius:4,fontSize:".75rem",color:"#00C8FF",letterSpacing:".1em" }}>
              {matchData.match.room_code}
            </code>
          )}
        </div>
        {phase === "active" && !isSpectator && (
          <button onClick={() => setShowProvoke(true)} style={{ padding:".35rem .8rem",background:"rgba(255,87,34,.08)",border:"1px solid rgba(255,87,34,.3)",borderRadius:5,cursor:"pointer",color:"#FF5722",fontFamily:"'Orbitron',sans-serif",fontSize:".6rem",letterSpacing:".08em",fontWeight:700 }}>⚡ PROVOKE</button>
        )}
      </div>

      {/* Score cards */}
      <div style={{ display:"flex",gap:".75rem",marginBottom:"1.25rem",flexWrap:"wrap" }}>
        {players.map(p => {
          const isMe = p.user_id === user?.id;
          const isActive = p.user_id === activePlayerId && phase === "active";
          return (
            <div key={p.user_id} style={{
              flex:1, minWidth:160, background:"#0C1220",
              border: isSpectator ? "1px solid rgba(0,200,255,.12)" : isMe ? "1px solid rgba(0,200,255,.45)" : "1px solid rgba(0,200,255,.12)",
              borderTop: isActive ? "3px solid #00E676" : isMe ? "3px solid #00C8FF" : "3px solid #1E2B42",
              borderRadius:8, padding:".75rem 1rem",
              boxShadow: isActive ? "0 0 18px rgba(0,230,118,.15)" : isMe ? "0 0 12px rgba(0,200,255,.08)" : "none",
              transition:"all .3s",
            }}>
              <div style={{ display:"flex",alignItems:"center",gap:".5rem",marginBottom:".3rem" }}>
                <span style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".62rem",color: isMe?"#00C8FF":"#7B8DB0",fontWeight:700 }}>
                  {isSpectator ? (p.is_host ? "HOST" : "GUEST") : isMe ? "YOU" : "OPPONENT"}
                </span>
                {isActive && (
                  <span style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".52rem",background:"rgba(0,230,118,.15)",border:"1px solid rgba(0,230,118,.4)",color:"#00E676",padding:".1rem .4rem",borderRadius:3,letterSpacing:".08em" }}>
                    ● TURN
                  </span>
                )}
              </div>
              <div style={{ fontFamily:"'Orbitron',sans-serif",fontWeight:700,fontSize:".72rem",color:"#E8EEFF",marginBottom:".2rem" }}>
                {p.display_name || "Player"}
              </div>
              <div style={{ display:"flex",gap:"1rem" }}>
                <span style={{ fontFamily:"'Orbitron',monospace",fontSize:".9rem",color:"#00C8FF",fontWeight:700 }}>
                  {p.score_xp || 0} <span style={{ fontSize:".55rem",color:"#7B8DB0" }}>XP</span>
                </span>
                <span style={{ fontFamily:"'Orbitron',monospace",fontSize:".75rem",color:"#FFB300" }}>
                  {p.correct_count || 0}✓
                </span>
              </div>
            </div>
          );
        })}
      </div>

      {/* ── WAITING PHASE ── */}
      {phase === "waiting" && (
        <div style={{ background:"#0C1220",border:"1px solid rgba(0,200,255,.2)",borderRadius:10,padding:"2.5rem",textAlign:"center" }}>
          <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".72rem",color:"#7B8DB0",letterSpacing:".1em",marginBottom:"1rem" }}>
            WAITING FOR PLAYERS…
          </div>
          {matchData?.match?.room_code && (
            <div style={{ marginBottom:"1.5rem" }}>
              <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".58rem",color:"#7B8DB0",letterSpacing:".1em",marginBottom:".4rem" }}>SHARE ROOM CODE</div>
              <div style={{ fontFamily:"'Orbitron',monospace",fontSize:"2rem",fontWeight:900,color:"#00C8FF",letterSpacing:".25em" }}>
                {matchData.match.room_code}
              </div>
            </div>
          )}
          <button
            onClick={() => { navigator.clipboard?.writeText(window.location.href); }}
            style={{ marginBottom:"1.25rem",padding:".45rem 1rem",background:"#141D2E",border:"1px solid rgba(0,200,255,.2)",borderRadius:4,color:"#7B8DB0",fontFamily:"'Orbitron',sans-serif",fontSize:".58rem",letterSpacing:".08em",cursor:"pointer" }}
          >
            🔗 COPY SPECTATOR LINK
          </button>

          {/* Difficulty info */}
          {matchData?.match?.max_questions && (() => {
            const maxQ = matchData.match.max_questions;
            const diff = maxQ <= 5 ? ["🟢","EASY",30] : maxQ <= 10 ? ["🔵","NORMAL",30] : maxQ <= 15 ? ["🟠","HARD",20] : ["🔴","EXPERT",15];
            return (
              <div style={{ display:"flex",gap:".75rem",justifyContent:"center",marginBottom:"1.25rem",flexWrap:"wrap" }}>
                <div style={{ background:"#141D2E",border:"1px solid rgba(0,200,255,.15)",borderRadius:5,padding:".4rem .9rem",fontFamily:"'Orbitron',sans-serif",fontSize:".6rem",color:"#E8EEFF",letterSpacing:".08em" }}>{diff[0]} {diff[1]}</div>
                <div style={{ background:"#141D2E",border:"1px solid rgba(0,200,255,.15)",borderRadius:5,padding:".4rem .9rem",fontFamily:"'Orbitron',sans-serif",fontSize:".6rem",color:"#00C8FF",letterSpacing:".08em" }}>{maxQ} QUESTIONS</div>
                <div style={{ background:"#141D2E",border:"1px solid rgba(0,200,255,.15)",borderRadius:5,padding:".4rem .9rem",fontFamily:"'Orbitron',sans-serif",fontSize:".6rem",color:"#FFB300",letterSpacing:".08em" }}>{diff[2]}s / QUESTION</div>
              </div>
            );
          })()}

          {players.length >= 2 ? (
            <div style={{ color:"#00C8FF",fontFamily:"'Orbitron',sans-serif",fontSize:".68rem",letterSpacing:".1em",
              display:"flex",alignItems:"center",gap:".5rem" }}>
              <span style={{ display:"inline-block",width:8,height:8,borderRadius:"50%",background:"#00C8FF",
                animation:"pulse 1s infinite" }} />
              MATCH STARTING…
            </div>
          ) : (
            <div style={{ color:"#7B8DB0",fontFamily:"'Orbitron',sans-serif",fontSize:".65rem",letterSpacing:".08em" }}>
              Waiting for opponent to join…
            </div>
          )}
        </div>
      )}

      {/* ── ACTIVE PHASE ── */}
      {phase === "active" && q && (
        <div>
          {/* Progress + Turn indicator */}
          <div style={{ display:"flex",alignItems:"center",justifyContent:"space-between",marginBottom:".75rem" }}>
            <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".62rem",color:"#7B8DB0",letterSpacing:".08em" }}>
              QUESTION {currentQIdx + 1} / {totalQuestions}
            </div>
            <div style={{
              fontFamily:"'Orbitron',sans-serif",fontSize:".65rem",fontWeight:700,
              letterSpacing:".08em",padding:".3rem .85rem",borderRadius:4,
              background: isSpectator ? "rgba(168,85,247,.08)" : isMyTurn ? "rgba(0,230,118,.12)" : "rgba(0,200,255,.08)",
              border: isSpectator ? "1px solid rgba(168,85,247,.3)" : isMyTurn ? "1px solid rgba(0,230,118,.4)" : "1px solid rgba(0,200,255,.2)",
              color: isSpectator ? "#A855F7" : isMyTurn ? "#00E676" : "#7B8DB0",
            }}>
              {isSpectator
                ? `👁 ${players.find(p => p.user_id === activePlayerId)?.display_name || "?"}'s TURN`
                : isMyTurn ? "⚡ YOUR TURN" : "⏳ OPPONENT'S TURN"}
            </div>
          </div>

          {/* Progress bar */}
          <div style={{ height:3,background:"#1E2B42",borderRadius:2,overflow:"hidden",marginBottom:"1.25rem" }}>
            <div style={{ height:"100%",width:`${((currentQIdx) / totalQuestions) * 100}%`,background:"linear-gradient(90deg,#00C8FF,#006FFF)",transition:"width .4s" }} />
          </div>

          {/* Timer — always visible; counts down for active player */}
          {!turnResult && (
            <div style={{ marginBottom:"1rem" }}>
              <div style={{ display:"flex",alignItems:"center",justifyContent:"space-between",marginBottom:".3rem" }}>
                <span style={{ fontFamily:"'Orbitron',monospace",fontSize:"1.5rem",fontWeight:900,
                  color: isMyTurn ? timerColor : "#3A4860",letterSpacing:".05em" }}>
                  {isSpectator ? "—" : isMyTurn ? String(timeLeft).padStart(2,"0") : "—"}
                </span>
                <span style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".55rem",
                  color: isMyTurn ? "#7B8DB0" : "#3A4860",letterSpacing:".1em" }}>
                  {isMyTurn ? "SECONDS LEFT" : "OPPONENT'S TURN"}
                </span>
              </div>
              <div style={{ height:5,background:"#1E2B42",borderRadius:3,overflow:"hidden" }}>
                <div style={{ height:"100%",
                  width: isMyTurn ? `${timerPct}%` : "100%",
                  background: isMyTurn ? timerColor : "#1E2B42",
                  borderRadius:3,
                  transition: isMyTurn ? "width 1s linear" : "none",
                  boxShadow: isMyTurn ? `0 0 6px ${timerColor}` : "none" }} />
              </div>
            </div>
          )}

          {/* Question card */}
          <div style={{ background:"#0C1220",border:"1px solid rgba(0,200,255,.2)",borderRadius:10,padding:"1.5rem",marginBottom:".85rem" }}>
            <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".55rem",color:"#7B8DB0",letterSpacing:".12em",marginBottom:".75rem" }}>
              Q{currentQIdx + 1}
            </div>
            <p style={{ color:"#E8EEFF",fontSize:"1.05rem",lineHeight:1.65,margin:0,fontWeight:500 }}>
              {q.question}
            </p>
          </div>

          {/* Options */}
          <div style={{ display:"flex",flexDirection:"column",gap:".55rem",marginBottom:"1rem" }}>
            {(q.options || []).filter((_,idx) => !hiddenOpts.includes(idx)).map((opt, idx) => {
              const realIdx = (q.options || []).indexOf(opt);
              return (
              <button
                key={realIdx}
                onClick={() => { if (isMyTurn && !turnResult && selectedIdx === null && !submitted && !isSpectator) submitAnswer(realIdx); }}
                disabled={!isMyTurn || !!turnResult || selectedIdx !== null || submitted || isSpectator}
                style={optionStyle(realIdx)}
                onMouseOver={e => { if (isMyTurn && !turnResult && selectedIdx === null && !submitted) { e.currentTarget.style.background="#141D2E"; e.currentTarget.style.borderColor="rgba(0,200,255,.5)"; } }}
                onMouseOut={e => { if (!selectedIdx && !turnResult) { e.currentTarget.style.background="#0C1220"; e.currentTarget.style.borderColor="rgba(0,200,255,.2)"; } }}
              >
                <span style={{ fontFamily:"'Orbitron',monospace",fontSize:".62rem",color:"#7B8DB0",marginRight:".65rem",letterSpacing:".06em" }}>
                  {String.fromCharCode(65+realIdx)}
                </span>
                {opt}
              </button>
            );
            })}
          </div>

          {/* Power-up bar — only for active player, before answering */}
          {isMyTurn && !isSpectator && !turnResult && (
            <div style={{ display:"flex",gap:".45rem",marginBottom:"1rem",flexWrap:"wrap" }}>
              {[
                { key:"freeze", icon:"⏱", label:"FREEZE",  desc:"+15s",           color:"#00C8FF" },
                { key:"skip",   icon:"⏭", label:"SKIP",    desc:"Pass turn",      color:"#FFB300" },
                { key:"fifty",  icon:"🎯", label:"50/50",   desc:"Remove 2 wrong", color:"#00E676" },
                { key:"shield", icon:"🛡", label:"SHIELD",  desc:"Block 1 wrong",  color:"#A855F7" },
              ].map(pw => {
                const used = pwUsed[pw.key];
                const active = pw.key === "shield" && shielded;
                return (
                  <button key={pw.key} onClick={() => usePowerUp(pw.key)}
                    disabled={used}
                    title={pw.desc}
                    style={{
                      flex:1, minWidth:60, padding:".4rem .3rem",
                      background: active ? `${pw.color}22` : used ? "#0C1220" : "#141D2E",
                      border: `1px solid ${active ? pw.color : used ? "#1E2B42" : pw.color + "44"}`,
                      borderRadius:5, cursor: used ? "not-allowed" : "pointer",
                      opacity: used ? 0.35 : 1, transition:"all .15s", textAlign:"center",
                    }}
                  >
                    <div style={{ fontSize:".9rem" }}>{pw.icon}</div>
                    <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".48rem",color: used ? "#3A4A68" : pw.color,letterSpacing:".06em",marginTop:2 }}>
                      {used ? "USED" : pw.label}
                    </div>
                  </button>
                );
              })}
              {shielded && (
                <div style={{ alignSelf:"center",fontSize:".68rem",color:"#A855F7",fontFamily:"'Orbitron',sans-serif",letterSpacing:".06em" }}>🛡 SHIELDED</div>
              )}
            </div>
          )}

          {/* Feedback after answer */}
          {turnResult && (
            <div style={{
              padding:"1rem 1.25rem", borderRadius:8, marginBottom:".75rem",
              background: turnResult.correct ? "rgba(0,230,118,.1)" : "rgba(255,87,34,.1)",
              border: `1px solid ${turnResult.correct ? "#00E676" : "#FF5722"}`,
              fontFamily:"'Orbitron',sans-serif",fontSize:".72rem",fontWeight:700,letterSpacing:".08em",
              color: turnResult.correct ? "#00E676" : "#FF5722",
              textAlign:"center",
            }}>
              {turnResult.timeout ? "⏰ TIME'S UP! Passing turn…"
               : turnResult.correct ? "✓ CORRECT! Next question loading…"
               : "✗ WRONG! Passing turn to opponent…"}
            </div>
          )}


        </div>
      )}

      {/* Provoke modal */}
      {showProvoke && (
        <ArenaProvokeModal onSelect={sendTaunt} onClose={() => setShowProvoke(false)} />
      )}
    </div>
    </>
  );
}
