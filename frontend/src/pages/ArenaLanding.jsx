import { useState, useEffect, useRef, useCallback } from "react";
import { useNavigate, Link } from "react-router-dom";
import { api } from "../lib/api";
import { useAuth } from "../lib/AuthContext";
import SEO from "../components/SEO";

const ORBITRON = `@import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@400;600;700;900&display=swap');`;

/* ── Topics for guest quiz ──────────────────────────────────── */
const TOPICS = [
  { value: "sap-btp", label: "SAP BTP",       icon: "☁️" },
  { value: "sap-cap", label: "SAP CAP",       icon: "🛠️" },
  { value: "sap-ai",  label: "SAP AI Core",   icon: "🤖" },
  { value: "dev-quickstart", label: "Dev Quickstart", icon: "🚀" },
];

/* ── Locked features shown to guests ───────────────────────── */
const LOCKED = [
  { icon: "⚔️", name: "1v1 Battles",      desc: "Challenge others live and prove your skills in real-time" },
  { icon: "🏆", name: "Leaderboards",     desc: "Climb the global ranks and show your name at the top" },
  { icon: "🎯", name: "Daily Quests",     desc: "Complete missions, earn AP and unlock rewards every day" },
  { icon: "🏅", name: "Trophies",         desc: "Collect achievement badges for milestones you reach" },
  { icon: "🌀", name: "Spin Wheel",       desc: "Win bonus XP, AP and exclusive rewards with free spins" },
  { icon: "🗓️", name: "Season Ranks",    desc: "Compete each season and earn your place in the hall of fame" },
];

const OPT_KEYS = ["A", "B", "C", "D"];

function getGrade(pct) {
  if (pct >= 90) return { g: "S", color: "#FFD700", label: "LEGENDARY 👑" };
  if (pct >= 75) return { g: "A", color: "#00C8FF", label: "EXCELLENT ⚡" };
  if (pct >= 60) return { g: "B", color: "#22C55E", label: "SKILLED 🎯" };
  if (pct >= 45) return { g: "C", color: "#FACC15", label: "LEARNING 📚" };
  return { g: "D", color: "#EF4444", label: "KEEP GOING 💪" };
}

/* ── CSS ────────────────────────────────────────────────────── */
const CSS = `
${ORBITRON}
.al-wrap { max-width:900px; margin:0 auto; padding:1.5rem 1.25rem 4rem; box-sizing:border-box; }

/* hero */
.al-hero { text-align:center; padding:2.5rem 1rem 2rem; }
.al-eyebrow { font-family:'Orbitron',sans-serif; font-size:.58rem; letter-spacing:.2em; color:#00C8FF; margin-bottom:.6rem; }
.al-title { font-family:'Orbitron',sans-serif; font-size:clamp(1.8rem,5vw,2.8rem); font-weight:900; color:#E8EEFF; margin:0 0 .5rem; line-height:1.1; }
.al-sub { font-family:'Inter',sans-serif; font-size:.9rem; color:rgba(255,255,255,.45); margin:0 auto 1.75rem; max-width:480px; line-height:1.6; }

/* quiz container */
.al-quiz-box { background:rgba(8,14,28,.92); border:1px solid rgba(0,200,255,.2); border-radius:12px; padding:1.75rem; margin-bottom:1.5rem; }
.al-topic-row { display:flex; gap:.5rem; flex-wrap:wrap; margin-bottom:1.25rem; }
.al-topic-btn { padding:.5rem .9rem; border-radius:8px; border:1px solid rgba(0,200,255,.18); background:rgba(20,30,50,.8); cursor:pointer; font-family:'Orbitron',sans-serif; font-size:.6rem; letter-spacing:.04em; color:rgba(255,255,255,.55); transition:all .18s; display:flex; align-items:center; gap:.35rem; }
.al-topic-btn:hover { border-color:rgba(0,200,255,.4); color:#E8EEFF; }
.al-topic-btn.active { border-color:#00C8FF; background:rgba(0,200,255,.1); color:#00C8FF; box-shadow:0 0 12px rgba(0,200,255,.2); }
.al-start-btn { width:100%; padding:.9rem; border:none; border-radius:8px; background:linear-gradient(135deg,#00C8FF 0%,#0088CC 100%); color:#050B18; font-family:'Orbitron',sans-serif; font-weight:700; font-size:.85rem; letter-spacing:.1em; cursor:pointer; box-shadow:0 0 24px rgba(0,200,255,.35); transition:all .2s; }
.al-start-btn:hover { transform:translateY(-2px); box-shadow:0 6px 32px rgba(0,200,255,.45); }
.al-start-btn:disabled { opacity:.6; cursor:not-allowed; transform:none; }

/* hud */
.al-hud { display:flex; align-items:center; justify-content:space-between; background:rgba(8,14,28,.8); border:1px solid rgba(0,200,255,.1); border-radius:8px; padding:.65rem 1.1rem; margin-bottom:1.1rem; }
.al-hud-num { font-family:'Orbitron',sans-serif; font-size:.65rem; color:rgba(255,255,255,.35); letter-spacing:.08em; }
.al-hud-score { font-family:'Orbitron',sans-serif; font-size:.95rem; font-weight:700; color:#FFD700; }
.al-hud-time { font-family:'Orbitron',monospace; font-size:1.2rem; font-weight:700; color:#00C8FF; min-width:2ch; text-align:right; }

/* progress */
.al-pbar { height:3px; background:rgba(0,200,255,.08); border-radius:2px; margin-bottom:1.1rem; overflow:hidden; }
.al-pfill { height:100%; background:linear-gradient(90deg,#00C8FF,#0066AA); border-radius:2px; transition:width .4s ease; }

/* question */
.al-qcard { background:rgba(8,14,28,.88); border:1px solid rgba(0,200,255,.14); border-radius:10px; padding:1.5rem; margin-bottom:.9rem; }
.al-qnum { font-family:'Orbitron',sans-serif; font-size:.52rem; letter-spacing:.14em; color:rgba(0,200,255,.6); margin-bottom:.5rem; }
.al-qtext { font-family:'Inter',sans-serif; font-size:1rem; font-weight:600; color:#E8EEFF; line-height:1.55; margin:0; }

/* options */
.al-opts { display:grid; grid-template-columns:1fr 1fr; gap:.55rem; }
@media (max-width:520px) { .al-opts { grid-template-columns:1fr; } }
.al-opt { padding:.8rem .9rem; border-radius:8px; border:1px solid rgba(0,200,255,.14); background:rgba(14,22,42,.9); cursor:pointer; display:flex; align-items:flex-start; gap:.6rem; transition:all .18s; text-align:left; }
.al-opt:not(:disabled):hover { border-color:rgba(0,200,255,.4); background:rgba(0,200,255,.06); }
.al-opt:disabled { cursor:default; }
.al-opt-key { flex-shrink:0; width:24px; height:24px; border-radius:5px; border:1px solid rgba(0,200,255,.3); background:rgba(0,200,255,.08); display:flex; align-items:center; justify-content:center; font-family:'Orbitron',sans-serif; font-size:.58rem; font-weight:700; color:#00C8FF; }
.al-opt-txt { font-family:'Inter',sans-serif; font-size:.82rem; color:#C8D8F0; line-height:1.4; }
.al-opt.opt-correct { border-color:#22C55E; background:rgba(34,197,94,.12); }
.al-opt.opt-correct .al-opt-key { border-color:#22C55E; color:#22C55E; background:rgba(34,197,94,.18); }
.al-opt.opt-correct .al-opt-txt { color:#86EFAC; }
.al-opt.opt-wrong { border-color:#EF4444; background:rgba(239,68,68,.1); }
.al-opt.opt-wrong .al-opt-key { border-color:#EF4444; color:#EF4444; background:rgba(239,68,68,.16); }
.al-opt.opt-wrong .al-opt-txt { color:#FCA5A5; }
.al-opt.opt-dim { opacity:.35; }

/* results */
.al-result-box { background:rgba(8,14,28,.92); border-radius:12px; padding:2rem; text-align:center; margin-bottom:1.5rem; }
.al-grade { width:110px; height:110px; border-radius:50%; display:flex; align-items:center; justify-content:center; margin:0 auto 1rem; font-family:'Orbitron',sans-serif; font-size:3.2rem; font-weight:900; }
@keyframes grade-pop { 0%{transform:scale(.3) rotate(-15deg);opacity:0} 60%{transform:scale(1.15) rotate(3deg);opacity:1} 100%{transform:scale(1) rotate(0deg);opacity:1} }
.al-grade { animation: grade-pop .6s cubic-bezier(.22,1,.36,1) forwards; }

/* login CTA */
.al-cta-box { background:linear-gradient(135deg,rgba(0,200,255,.06) 0%,rgba(168,85,247,.06) 100%); border:1px solid rgba(0,200,255,.2); border-radius:12px; padding:2rem; text-align:center; margin-bottom:1.75rem; }
.al-cta-title { font-family:'Orbitron',sans-serif; font-size:clamp(.9rem,2.5vw,1.2rem); font-weight:700; color:#E8EEFF; margin:0 0 .5rem; }
.al-cta-sub { font-family:'Inter',sans-serif; font-size:.82rem; color:rgba(255,255,255,.45); margin:0 0 1.5rem; }
.al-cta-btns { display:flex; gap:.75rem; justify-content:center; flex-wrap:wrap; }
.al-btn-primary { padding:.75rem 2rem; border:none; border-radius:8px; background:#00C8FF; color:#050B18; font-family:'Orbitron',sans-serif; font-weight:700; font-size:.72rem; letter-spacing:.08em; cursor:pointer; box-shadow:0 0 20px rgba(0,200,255,.3); transition:all .2s; text-decoration:none; display:inline-block; }
.al-btn-primary:hover { transform:translateY(-2px); box-shadow:0 6px 28px rgba(0,200,255,.45); }
.al-btn-outline { padding:.75rem 1.5rem; border:1px solid rgba(0,200,255,.35); border-radius:8px; background:transparent; color:#00C8FF; font-family:'Orbitron',sans-serif; font-weight:700; font-size:.72rem; letter-spacing:.08em; cursor:pointer; transition:all .18s; text-decoration:none; display:inline-block; }
.al-btn-outline:hover { background:rgba(0,200,255,.08); }

/* locked features */
.al-locked-grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(240px,1fr)); gap:.65rem; margin-bottom:1.75rem; }
.al-locked-card { background:rgba(8,14,28,.7); border:1px solid rgba(255,255,255,.06); border-radius:10px; padding:1rem; display:flex; align-items:flex-start; gap:.75rem; position:relative; overflow:hidden; }
.al-locked-card::after { content:"🔒"; position:absolute; top:.6rem; right:.75rem; font-size:.7rem; opacity:.35; }
.al-locked-icon { font-size:1.5rem; flex-shrink:0; opacity:.5; }
.al-locked-name { font-family:'Orbitron',sans-serif; font-size:.62rem; font-weight:700; color:rgba(255,255,255,.4); letter-spacing:.04em; margin-bottom:.25rem; }
.al-locked-desc { font-family:'Inter',sans-serif; font-size:.72rem; color:rgba(255,255,255,.22); line-height:1.4; }

/* logged-in hub link */
.al-hub-bar { display:flex; align-items:center; justify-content:space-between; background:rgba(0,200,255,.06); border:1px solid rgba(0,200,255,.2); border-radius:8px; padding:.75rem 1.1rem; margin-bottom:1.25rem; }
.al-hub-bar-txt { font-family:'Orbitron',sans-serif; font-size:.62rem; letter-spacing:.06em; color:rgba(255,255,255,.6); }
`;

/* ══════════════════════════════════════════════════════
   MINI QUIZ (embedded in the landing page)
═════════════════════════════════════════════════════ */
function MiniQuiz({ topic, onDone }) {
  const SECONDS = 30;
  const [questions, setQuestions] = useState([]);
  const [qIdx, setQIdx]         = useState(0);
  const [selected, setSelected] = useState(null);
  const [revealed, setRevealed] = useState(false);
  const [timeLeft, setTimeLeft] = useState(SECONDS);
  const [timerOn, setTimerOn]   = useState(false);
  const [score, setScore]       = useState(0);
  const [results, setResults]   = useState([]);
  const [loading, setLoading]   = useState(true);
  const [error, setError]       = useState("");
  const timerRef = useRef(null);

  useEffect(() => {
    api.get(`/api/arena/solo/questions?topic_id=${topic}&limit=5`)
      .then(data => {
        if (!data || data.length === 0) throw new Error("No questions found yet.");
        setQuestions(data);
        setLoading(false);
        setTimeout(() => setTimerOn(true), 400);
      })
      .catch(e => { setError(e.message || "Could not load questions."); setLoading(false); });
  }, [topic]);

  useEffect(() => {
    clearInterval(timerRef.current);
    if (!timerOn) return;
    timerRef.current = setInterval(() => {
      setTimeLeft(t => { if (t <= 1) { clearInterval(timerRef.current); return 0; } return t - 1; });
    }, 1000);
    return () => clearInterval(timerRef.current);
  }, [timerOn, qIdx]);

  useEffect(() => {
    if (timerOn && timeLeft === 0 && !revealed) processAnswer(null);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [timeLeft, timerOn, revealed]);

  const processAnswer = useCallback((optIdx) => {
    if (revealed || !questions[qIdx]) return;
    clearInterval(timerRef.current);
    setTimerOn(false);
    setSelected(optIdx);
    setRevealed(true);
    const q = questions[qIdx];
    const correct = optIdx !== null && optIdx === q.correct_option;
    const timeBonus = correct ? Math.max(0, Math.floor((timeLeft / SECONDS) * 30)) : 0;
    const pts = correct ? 100 + timeBonus : 0;
    setScore(s => s + pts);
    setResults(r => [...r, { correct, timeUsed: SECONDS - timeLeft, points: pts }]);
    setTimeout(() => {
      const next = qIdx + 1;
      if (next >= questions.length) {
        onDone({ score: score + pts, results: [...results, { correct, timeUsed: SECONDS - timeLeft, points: pts }], total: questions.length });
      } else {
        setQIdx(next);
        setSelected(null);
        setRevealed(false);
        setTimeLeft(SECONDS);
        setTimeout(() => setTimerOn(true), 150);
      }
    }, 1400);
  }, [revealed, questions, qIdx, timeLeft, score, results, onDone]);

  useEffect(() => {
    const handler = (e) => {
      if (revealed) return;
      const i = ["a","b","c","d"].indexOf(e.key.toLowerCase());
      if (i !== -1) processAnswer(i);
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, [revealed, processAnswer]);

  if (loading) return (
    <div style={{ textAlign:"center", padding:"2rem", color:"rgba(255,255,255,.35)", fontFamily:"'Orbitron',sans-serif", fontSize:".65rem", letterSpacing:".1em" }}>
      LOADING QUESTIONS…
    </div>
  );
  if (error) return (
    <div style={{ textAlign:"center", padding:"1.5rem", color:"#FF6655", fontFamily:"'Inter',sans-serif", fontSize:".85rem" }}>
      {error}
    </div>
  );

  const q = questions[qIdx];
  const timeColor = timeLeft <= 7 ? "#EF4444" : timeLeft / SECONDS <= 0.35 ? "#FACC15" : "#00C8FF";

  const optClass = (i) => {
    if (!revealed) return "al-opt";
    if (i === q.correct_option) return "al-opt opt-correct";
    if (i === selected && i !== q.correct_option) return "al-opt opt-wrong";
    return "al-opt opt-dim";
  };

  return (
    <>
      {/* HUD */}
      <div className="al-hud">
        <span className="al-hud-num">Q {qIdx + 1} / {questions.length}</span>
        <span className="al-hud-score">{score.toLocaleString()} pts</span>
        <span className="al-hud-time" style={{ color: timeColor }}>{timeLeft}s</span>
      </div>

      {/* Progress */}
      <div className="al-pbar"><div className="al-pfill" style={{ width:`${(qIdx / questions.length) * 100}%` }} /></div>

      {/* Question */}
      <div className="al-qcard">
        <div className="al-qnum">QUESTION {qIdx + 1} OF {questions.length}</div>
        <p className="al-qtext">{q.question}</p>
      </div>

      {/* Options */}
      <div className="al-opts">
        {(q.options || []).map((opt, i) => (
          <button key={i} className={optClass(i)} onClick={() => !revealed && processAnswer(i)} disabled={revealed}>
            <span className="al-opt-key">{OPT_KEYS[i]}</span>
            <span className="al-opt-txt">{opt}</span>
          </button>
        ))}
      </div>
      <div style={{ textAlign:"center", marginTop:".75rem", fontFamily:"'Orbitron',sans-serif", fontSize:".5rem", letterSpacing:".1em", color:"rgba(255,255,255,.18)" }}>
        PRESS A · B · C · D
      </div>
    </>
  );
}

/* ══════════════════════════════════════════════════════
   MAIN COMPONENT
═════════════════════════════════════════════════════ */
export default function ArenaLanding() {
  const navigate = useNavigate();
  const { session, profile } = useAuth();
  const user = session?.user;

  const [phase, setPhase] = useState("landing"); // landing | quiz | results
  const [topic, setTopic] = useState("sap-btp");
  const [quizResult, setQuizResult] = useState(null);

  function handleDone(result) {
    setQuizResult(result);
    setPhase("results");
  }

  /* ── Results screen ──────────────────────────────── */
  if (phase === "results" && quizResult) {
    const pct = Math.round((quizResult.results.filter(r => r.correct).length / quizResult.total) * 100);
    const grade = getGrade(pct);
    return (
      <div className="al-wrap">
        <style>{CSS}</style>
        <SEO title="Arena — Try It Free" description="Free solo quiz to test your SAP BTP knowledge — no login required on CodeGoLive." />

        {/* Grade */}
        <div className="al-result-box" style={{ borderTop:`3px solid ${grade.color}`, border:`1px solid ${grade.color}30` }}>
          <div className="al-grade" style={{ color:grade.color, border:`3px solid ${grade.color}`, background:`radial-gradient(circle,${grade.color}1A 0%,transparent 70%)`, boxShadow:`0 0 36px ${grade.color}55` }}>
            {grade.g}
          </div>
          <div style={{ fontFamily:"'Orbitron',sans-serif", fontSize:".6rem", letterSpacing:".18em", color:grade.color, marginBottom:".3rem" }}>{grade.label}</div>
          <h2 style={{ fontFamily:"'Orbitron',sans-serif", fontSize:"1.3rem", color:"#E8EEFF", margin:"0 0 .25rem" }}>{pct}% Correct</h2>
          <p style={{ fontFamily:"'Inter',sans-serif", color:"rgba(255,255,255,.4)", fontSize:".8rem", margin:"0 0 1.25rem" }}>
            {quizResult.results.filter(r => r.correct).length} of {quizResult.total} questions · {quizResult.score.toLocaleString()} points
          </p>

          {/* Stat tiles */}
          <div style={{ display:"grid", gridTemplateColumns:"repeat(3,1fr)", gap:".5rem", marginBottom:"1.25rem" }}>
            {[
              { v:`${quizResult.score.toLocaleString()}`, l:"Score", c:"#FFD700" },
              { v:`${quizResult.results.filter(r => r.correct).length}/${quizResult.total}`, l:"Correct", c:"#22C55E" },
              { v:`${pct}%`, l:"Accuracy", c:"#00C8FF" },
            ].map(({ v, l, c }) => (
              <div key={l} style={{ background:"rgba(14,22,42,.9)", border:"1px solid rgba(0,200,255,.1)", borderRadius:8, padding:".75rem .5rem" }}>
                <div style={{ fontFamily:"'Orbitron',sans-serif", fontSize:"1.2rem", fontWeight:700, color:c, marginBottom:".2rem" }}>{v}</div>
                <div style={{ fontFamily:"'Orbitron',sans-serif", fontSize:".48rem", letterSpacing:".1em", color:"rgba(255,255,255,.3)", textTransform:"uppercase" }}>{l}</div>
              </div>
            ))}
          </div>

          {/* Action buttons */}
          <div className="al-cta-btns" style={{ marginBottom:"1rem" }}>
            <button className="al-btn-outline" onClick={() => { setPhase("landing"); setQuizResult(null); }}>↺ TRY AGAIN</button>
          </div>
        </div>

        {/* Login CTA + locked features — guests only */}
        {!user && (
          <>
            <div className="al-cta-box">
              <div style={{ fontSize:"1.5rem", marginBottom:".6rem" }}>🏆</div>
              <div className="al-cta-title">Save your score &amp; unlock full Arena</div>
              <div className="al-cta-sub">Create a free account to track your progress, compete in 1v1 battles,<br />climb the leaderboard, and earn trophies.</div>
              <div className="al-cta-btns">
                <Link to="/login" className="al-btn-primary">CREATE FREE ACCOUNT</Link>
                <Link to="/login" className="al-btn-outline">SIGN IN</Link>
              </div>
            </div>
            <div style={{ fontFamily:"'Orbitron',sans-serif", fontSize:".58rem", letterSpacing:".14em", color:"rgba(0,200,255,.5)", marginBottom:".75rem" }}>UNLOCK WITH AN ACCOUNT</div>
            <div className="al-locked-grid">
              {LOCKED.map(f => (
                <div key={f.name} className="al-locked-card">
                  <span className="al-locked-icon">{f.icon}</span>
                  <div>
                    <div className="al-locked-name">{f.name}</div>
                    <div className="al-locked-desc">{f.desc}</div>
                  </div>
                </div>
              ))}
            </div>
          </>
        )}

        {/* Logged-in: go to Hub after completing quiz */}
        {user && (
          <div style={{ textAlign:"center", marginTop:"1rem" }}>
            <button onClick={() => { window.location.href = "/arena/hub"; }}
              style={{ fontFamily:"'Orbitron',sans-serif", fontSize:".72rem", fontWeight:700, letterSpacing:".08em", padding:".75rem 2rem", background:"#00C8FF", color:"#050B18", border:"none", borderRadius:8, cursor:"pointer", boxShadow:"0 0 20px rgba(0,200,255,.3)" }}>
              ⚔️ ENTER FULL ARENA HUB →
            </button>
          </div>
        )}
      </div>
    );
  }

  /* ── Landing / Quiz screen ───────────────────────── */
  return (
    <div className="al-wrap">
      <style>{CSS}</style>
      <SEO title="Arena — Try It Free" description="Free solo quiz to test your SAP BTP knowledge — no login required on CodeGoLive." />

      {/* Logged-in users: quick link to the full hub */}
      {user && (
        <div className="al-hub-bar">
          <span className="al-hub-bar-txt">⚔️ Welcome back, {user.user_metadata?.display_name || "Challenger"}!</span>
          <button
            onClick={() => navigate("/arena/hub")}
            style={{ fontFamily:"'Orbitron',sans-serif", fontSize:".6rem", fontWeight:700, letterSpacing:".08em", padding:".45rem 1.1rem", background:"#00C8FF", color:"#050B18", border:"none", borderRadius:5, cursor:"pointer" }}
          >
            ENTER HUB →
          </button>
        </div>
      )}

      {/* Hero */}
      {phase === "landing" && (
        <div className="al-hero">
          <div className="al-eyebrow">CODEGOLIVE · ARENA</div>
          <h1 className="al-title">⚔️ Test Your<br />Knowledge</h1>
          <p className="al-sub">Pick a topic, race against the clock, and see how you rank — no account needed.</p>
        </div>
      )}

      {/* Quiz box */}
      <div className="al-quiz-box">
        {phase === "landing" && (
          <>
            <div style={{ fontFamily:"'Orbitron',sans-serif", fontSize:".58rem", letterSpacing:".12em", color:"rgba(0,200,255,.65)", marginBottom:".65rem" }}>CHOOSE YOUR TOPIC</div>
            <div className="al-topic-row">
              {TOPICS.map(t => (
                <button key={t.value} className={"al-topic-btn" + (topic === t.value ? " active" : "")} onClick={() => setTopic(t.value)}>
                  <span>{t.icon}</span><span>{t.label}</span>
                </button>
              ))}
            </div>
            <div style={{ background:"rgba(0,200,255,.05)", border:"1px solid rgba(0,200,255,.12)", borderRadius:6, padding:".55rem 1rem", marginBottom:"1.1rem", fontFamily:"'Inter',sans-serif", fontSize:".72rem", color:"rgba(255,255,255,.4)", display:"flex", gap:"1rem", flexWrap:"wrap" }}>
              <span>📋 5 questions</span>
              <span>⏱ 30s per question</span>
              <span>🎯 No login required</span>
            </div>
            <button className="al-start-btn" onClick={() => setPhase("quiz")}>⚡ START CHALLENGE — IT'S FREE</button>
          </>
        )}

        {phase === "quiz" && (
          <MiniQuiz topic={topic} onDone={handleDone} />
        )}
      </div>

      {/* Guest CTA — only on landing, not during quiz */}
      {phase === "landing" && !user && (
        <>
          <div className="al-cta-box">
            <div style={{ fontSize:"1.4rem", marginBottom:".5rem" }}>🔓</div>
            <div className="al-cta-title">Want the full Arena experience?</div>
            <div className="al-cta-sub">Sign up free to save your scores, fight 1v1, earn trophies and climb the leaderboard.</div>
            <div className="al-cta-btns">
              <Link to="/login" className="al-btn-primary">CREATE FREE ACCOUNT</Link>
              <Link to="/login" className="al-btn-outline">SIGN IN</Link>
            </div>
          </div>

          <div style={{ fontFamily:"'Orbitron',sans-serif", fontSize:".58rem", letterSpacing:".14em", color:"rgba(0,200,255,.45)", marginBottom:".75rem" }}>MEMBERS GET ACCESS TO</div>
          <div className="al-locked-grid">
            {LOCKED.map(f => (
              <div key={f.name} className="al-locked-card">
                <span className="al-locked-icon">{f.icon}</span>
                <div>
                  <div className="al-locked-name">{f.name}</div>
                  <div className="al-locked-desc">{f.desc}</div>
                </div>
              </div>
            ))}
          </div>
        </>
      )}
    </div>
  );
}
