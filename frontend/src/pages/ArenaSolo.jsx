import { useState, useEffect, useRef, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "../lib/api";
import SEO from "../components/SEO";

/* ── Google Font ────────────────────────────────────────────── */
const ORBITRON = `@import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@400;600;700;900&display=swap');`;

/* ── Constants ──────────────────────────────────────────────── */
const TOPICS = [
  { value: "sap-btp",        label: "SAP BTP",       icon: "☁️" },
  { value: "sap-cap",        label: "SAP CAP",       icon: "🛠️" },
  { value: "sap-ai",         label: "SAP AI Core",   icon: "🤖" },
  { value: "dev-quickstart", label: "Dev Quickstart", icon: "🚀" },
];

const DIFFICULTIES = [
  { key: "easy",   label: "Easy",   icon: "🟢", questions: 5,  seconds: 45, desc: "5 Qs · 45 sec each  · Warm up" },
  { key: "normal", label: "Normal", icon: "🔵", questions: 10, seconds: 30, desc: "10 Qs · 30 sec each · Standard" },
  { key: "hard",   label: "Hard",   icon: "🟠", questions: 15, seconds: 20, desc: "15 Qs · 20 sec each · Intense" },
  { key: "expert", label: "Expert", icon: "🔴", questions: 20, seconds: 15, desc: "20 Qs · 15 sec each · Pros only" },
];

const GRADES = [
  { min: 90, grade: "S", color: "#FFD700", shadow: "rgba(255,215,0,0.5)",  label: "LEGENDARY",  emoji: "👑" },
  { min: 75, grade: "A", color: "#00C8FF", shadow: "rgba(0,200,255,0.4)", label: "EXCELLENT",   emoji: "⚡" },
  { min: 60, grade: "B", color: "#22C55E", shadow: "rgba(34,197,94,0.4)", label: "SKILLED",     emoji: "🎯" },
  { min: 45, grade: "C", color: "#FACC15", shadow: "rgba(250,204,21,0.4)",label: "LEARNING",    emoji: "📚" },
  { min: 0,  grade: "D", color: "#EF4444", shadow: "rgba(239,68,68,0.4)", label: "KEEP GOING",  emoji: "💪" },
];

const OPT_KEYS = ["A", "B", "C", "D"];

function getGradeInfo(pct) {
  return GRADES.find(g => pct >= g.min) || GRADES[GRADES.length - 1];
}

function getMultiplier(streak) {
  if (streak >= 7) return 3.0;
  if (streak >= 5) return 2.5;
  if (streak >= 3) return 2.0;
  if (streak >= 2) return 1.5;
  return 1.0;
}

/* ── Circular countdown ring ────────────────────────────────── */
function TimerRing({ timeLeft, maxSeconds }) {
  const R = 40;
  const C = 2 * Math.PI * R;
  const pct = timeLeft / maxSeconds;
  const color = timeLeft <= 5 ? "#EF4444" : timeLeft / maxSeconds <= 0.35 ? "#FACC15" : "#00C8FF";

  return (
    <svg width={100} height={100} viewBox="0 0 100 100" style={{ display: "block" }}>
      <circle cx={50} cy={50} r={R} fill="none" stroke="rgba(255,255,255,0.06)" strokeWidth={7} />
      <circle
        cx={50} cy={50} r={R}
        fill="none"
        stroke={color}
        strokeWidth={7}
        strokeLinecap="round"
        strokeDasharray={C}
        strokeDashoffset={C * (1 - pct)}
        style={{
          transformOrigin: "50px 50px",
          transform: "rotate(-90deg)",
          transition: "stroke-dashoffset 1s linear, stroke 0.4s ease",
          filter: `drop-shadow(0 0 6px ${color})`,
        }}
      />
      <text
        x={50} y={50}
        textAnchor="middle"
        dominantBaseline="central"
        fill={color}
        style={{
          fontFamily: "'Orbitron', monospace",
          fontSize: timeLeft >= 10 ? "1.4rem" : "1.6rem",
          fontWeight: 700,
          filter: timeLeft <= 5 ? `drop-shadow(0 0 8px ${color})` : "none",
        }}
      >
        {timeLeft}
      </text>
    </svg>
  );
}

/* ── Global CSS ──────────────────────────────────────────────── */
const CSS = `
${ORBITRON}

.solo-wrap {
  max-width: 780px;
  margin: 0 auto;
  padding: 1.75rem 1.5rem 3rem;
  box-sizing: border-box;
  font-family: 'Orbitron', sans-serif;
}

/* ── Setup ─── */
.solo-setup-card {
  background: rgba(8,14,28,0.92);
  border: 1px solid rgba(0,200,255,0.2);
  border-radius: 12px;
  padding: 2rem;
}

.solo-topic-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(160px,1fr));
  gap: .6rem;
  margin-bottom: 1.5rem;
}

.solo-diff-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: .6rem;
  margin-bottom: 1.75rem;
}

.solo-select-btn {
  padding: .75rem;
  border-radius: 8px;
  border: 1px solid rgba(0,200,255,.15);
  background: rgba(20,30,50,.8);
  cursor: pointer;
  text-align: left;
  transition: all .18s;
  color: #E8EEFF;
}
.solo-select-btn:hover { border-color: rgba(0,200,255,.45); background: rgba(0,200,255,.06); }
.solo-select-btn.active { border-color: #00C8FF; background: rgba(0,200,255,.1); box-shadow: 0 0 16px rgba(0,200,255,.2); }

.solo-play-btn {
  width: 100%;
  padding: 1rem;
  border: none;
  border-radius: 8px;
  background: linear-gradient(135deg, #00C8FF 0%, #0088CC 100%);
  color: #050B18;
  font-family: 'Orbitron', sans-serif;
  font-weight: 700;
  font-size: .88rem;
  letter-spacing: .1em;
  cursor: pointer;
  box-shadow: 0 0 28px rgba(0,200,255,.35);
  transition: all .2s;
}
.solo-play-btn:hover { transform: translateY(-2px); box-shadow: 0 6px 32px rgba(0,200,255,.45); }
.solo-play-btn:disabled { opacity: .6; cursor: not-allowed; transform: none; }

/* ── Game HUD ─── */
.solo-hud {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: .75rem;
  margin-bottom: 1.5rem;
  background: rgba(8,14,28,0.88);
  border: 1px solid rgba(0,200,255,.12);
  border-radius: 10px;
  padding: .75rem 1.25rem;
}

.solo-hud-stat {
  display: flex;
  flex-direction: column;
  align-items: center;
}
.solo-hud-val {
  font-size: 1.2rem;
  font-weight: 700;
  color: #00C8FF;
  line-height: 1;
}
.solo-hud-label {
  font-size: .5rem;
  letter-spacing: .1em;
  color: rgba(255,255,255,.35);
  margin-top: .25rem;
  text-transform: uppercase;
}

.solo-progress-bar {
  height: 4px;
  background: rgba(0,200,255,.1);
  border-radius: 2px;
  margin-bottom: 1.25rem;
  overflow: hidden;
}
.solo-progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #00C8FF, #0066AA);
  border-radius: 2px;
  transition: width .4s ease;
  box-shadow: 0 0 8px rgba(0,200,255,.5);
}

/* ── Question card ─── */
.solo-q-card {
  background: rgba(8,14,28,0.92);
  border: 1px solid rgba(0,200,255,.18);
  border-radius: 12px;
  padding: 2rem;
  margin-bottom: 1.25rem;
}

.solo-q-num {
  font-size: .58rem;
  letter-spacing: .14em;
  color: rgba(0,200,255,.7);
  margin-bottom: .6rem;
}
.solo-q-text {
  font-family: 'Inter', sans-serif;
  font-size: 1.05rem;
  font-weight: 600;
  color: #E8EEFF;
  line-height: 1.55;
  margin: 0;
  letter-spacing: 0;
}

/* ── Options ─── */
.solo-options {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: .65rem;
}

@media (max-width: 560px) {
  .solo-options { grid-template-columns: 1fr; }
  .solo-diff-grid { grid-template-columns: 1fr; }
}

.solo-opt-btn {
  padding: .85rem 1rem;
  border-radius: 8px;
  border: 1px solid rgba(0,200,255,.15);
  background: rgba(14,22,42,.9);
  cursor: pointer;
  text-align: left;
  display: flex;
  align-items: flex-start;
  gap: .65rem;
  transition: all .18s;
  position: relative;
  overflow: hidden;
}
.solo-opt-btn:not(:disabled):hover {
  border-color: rgba(0,200,255,.45);
  background: rgba(0,200,255,.06);
  transform: translateY(-1px);
}
.solo-opt-btn:disabled { cursor: default; }

.solo-opt-key {
  flex-shrink: 0;
  width: 26px;
  height: 26px;
  border-radius: 6px;
  border: 1px solid rgba(0,200,255,.3);
  background: rgba(0,200,255,.08);
  display: flex; align-items: center; justify-content: center;
  font-size: .65rem;
  font-weight: 700;
  color: #00C8FF;
  letter-spacing: .04em;
}
.solo-opt-text {
  font-family: 'Inter', sans-serif;
  font-size: .85rem;
  color: #C8D8F0;
  line-height: 1.4;
}

/* ── Reveal states ─── */
.solo-opt-btn.opt-correct {
  border-color: #22C55E;
  background: rgba(34,197,94,.14);
  box-shadow: 0 0 20px rgba(34,197,94,.25);
}
.solo-opt-btn.opt-correct .solo-opt-key { border-color: #22C55E; background: rgba(34,197,94,.2); color: #22C55E; }
.solo-opt-btn.opt-correct .solo-opt-text { color: #86EFAC; }

.solo-opt-btn.opt-wrong {
  border-color: #EF4444;
  background: rgba(239,68,68,.12);
  box-shadow: 0 0 16px rgba(239,68,68,.2);
}
.solo-opt-btn.opt-wrong .solo-opt-key { border-color: #EF4444; background: rgba(239,68,68,.18); color: #EF4444; }
.solo-opt-btn.opt-wrong .solo-opt-text { color: #FCA5A5; }

.solo-opt-btn.opt-dim {
  opacity: .38;
}

/* ── Streak flash ─── */
@keyframes solo-streak-pop {
  0%   { transform: scale(1.4); opacity: 1; }
  100% { transform: scale(1);   opacity: 1; }
}
.solo-streak-pop { animation: solo-streak-pop .35s ease; }

/* ── Points flash ─── */
@keyframes solo-pts-in {
  0%   { opacity: 0; transform: translateY(8px) scale(.8); }
  30%  { opacity: 1; transform: translateY(0)   scale(1.1); }
  80%  { opacity: 1; }
  100% { opacity: 0; transform: translateY(-12px); }
}
.solo-pts-toast {
  position: fixed;
  pointer-events: none;
  font-family: 'Orbitron', sans-serif;
  font-weight: 700;
  font-size: 1.2rem;
  color: #FFD700;
  text-shadow: 0 0 12px rgba(255,215,0,.7);
  animation: solo-pts-in 1.4s ease forwards;
  z-index: 100;
}

/* ── Results ─── */
.solo-grade-circle {
  width: 120px;
  height: 120px;
  border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  margin: 0 auto 1.25rem;
  font-size: 3.5rem;
  font-weight: 900;
  letter-spacing: -.02em;
}

@keyframes solo-grade-in {
  0%   { transform: scale(0.4) rotate(-15deg); opacity: 0; }
  60%  { transform: scale(1.15) rotate(3deg); opacity: 1; }
  100% { transform: scale(1) rotate(0deg); opacity: 1; }
}
.solo-grade-anim { animation: solo-grade-in .6s cubic-bezier(.22,1,.36,1) forwards; }

.solo-stat-row {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(130px,1fr));
  gap: .6rem;
  margin: 1.25rem 0;
}
.solo-stat-tile {
  background: rgba(14,22,42,.9);
  border: 1px solid rgba(0,200,255,.12);
  border-radius: 8px;
  padding: .85rem;
  text-align: center;
}
.solo-stat-tile-val {
  font-size: 1.5rem;
  font-weight: 700;
  color: #00C8FF;
  line-height: 1;
  margin-bottom: .3rem;
}
.solo-stat-tile-lbl {
  font-size: .55rem;
  letter-spacing: .1em;
  color: rgba(255,255,255,.35);
  text-transform: uppercase;
}

.solo-answer-review {
  display: flex;
  flex-direction: column;
  gap: .35rem;
  margin: .75rem 0 1.25rem;
  max-height: 200px;
  overflow-y: auto;
}
.solo-review-row {
  display: flex;
  align-items: center;
  gap: .6rem;
  padding: .4rem .75rem;
  border-radius: 6px;
  font-size: .72rem;
  font-family: 'Inter', sans-serif;
}
.solo-review-row.r-correct { background: rgba(34,197,94,.08); border: 1px solid rgba(34,197,94,.2); }
.solo-review-row.r-wrong { background: rgba(239,68,68,.07); border: 1px solid rgba(239,68,68,.18); }

.solo-action-row {
  display: flex;
  gap: .75rem;
  flex-wrap: wrap;
}
.solo-btn-outline {
  flex: 1;
  padding: .75rem;
  border: 1px solid rgba(0,200,255,.3);
  border-radius: 8px;
  background: transparent;
  color: #00C8FF;
  font-family: 'Orbitron', sans-serif;
  font-size: .68rem;
  letter-spacing: .08em;
  font-weight: 700;
  cursor: pointer;
  transition: all .18s;
}
.solo-btn-outline:hover { background: rgba(0,200,255,.08); border-color: rgba(0,200,255,.5); }
`;

/* ═══════════════════════════════════════════════════════════════
   SETUP SCREEN
══════════════════════════════════════════════════════════════ */
function SetupScreen({ topic, setTopic, difficulty, setDifficulty, onStart, loading, error, onBack }) {
  const diff = DIFFICULTIES.find(d => d.key === difficulty);
  return (
    <div className="solo-wrap">
      <SEO title="Solo Practice" description="Test your SAP BTP knowledge solo — timed quiz against yourself." robots="noindex" />
      <style>{CSS}</style>

      {/* Back */}
      <button onClick={onBack} style={{
        display: "flex", alignItems: "center", gap: ".4rem",
        background: "transparent", border: "1px solid rgba(0,200,255,.2)",
        borderRadius: 4, padding: ".35rem .85rem", color: "rgba(0,200,255,.7)",
        fontFamily: "'Orbitron', sans-serif", fontSize: ".56rem", letterSpacing: ".08em",
        cursor: "pointer", marginBottom: "1.5rem",
      }}>← ARENA HUB</button>

      {/* Header */}
      <div style={{ marginBottom: "1.75rem" }}>
        <div style={{ fontSize: ".58rem", letterSpacing: ".16em", color: "#00C8FF", marginBottom: 4 }}>ARENA · SOLO MODE</div>
        <h1 style={{ fontSize: "clamp(1.4rem,4vw,2rem)", fontWeight: 900, margin: "0 0 .3rem", color: "#E8EEFF" }}>
          🎯 Solo Practice
        </h1>
        <p style={{ color: "rgba(255,255,255,.45)", fontSize: ".8rem", margin: 0, fontFamily: "Inter, sans-serif" }}>
          Test yourself against the clock. No opponent — just you and the questions.
        </p>
      </div>

      <div className="solo-setup-card">
        {/* Topic */}
        <div style={{ fontSize: ".6rem", letterSpacing: ".12em", color: "rgba(0,200,255,.7)", marginBottom: ".6rem" }}>SELECT TOPIC</div>
        <div className="solo-topic-grid" style={{ marginBottom: "1.5rem" }}>
          {TOPICS.map(t => (
            <button
              key={t.value}
              className={"solo-select-btn" + (topic === t.value ? " active" : "")}
              onClick={() => setTopic(t.value)}
            >
              <div style={{ fontSize: "1.3rem", marginBottom: ".25rem" }}>{t.icon}</div>
              <div style={{ fontSize: ".65rem", fontWeight: 700, letterSpacing: ".04em" }}>{t.label}</div>
            </button>
          ))}
        </div>

        {/* Difficulty */}
        <div style={{ fontSize: ".6rem", letterSpacing: ".12em", color: "rgba(0,200,255,.7)", marginBottom: ".6rem" }}>SELECT DIFFICULTY</div>
        <div className="solo-diff-grid">
          {DIFFICULTIES.map(d => (
            <button
              key={d.key}
              className={"solo-select-btn" + (difficulty === d.key ? " active" : "")}
              onClick={() => setDifficulty(d.key)}
            >
              <div style={{ display: "flex", alignItems: "center", gap: ".4rem", marginBottom: ".25rem" }}>
                <span>{d.icon}</span>
                <span style={{ fontSize: ".7rem", fontWeight: 700, letterSpacing: ".06em" }}>{d.label.toUpperCase()}</span>
              </div>
              <div style={{ fontSize: ".65rem", color: "rgba(255,255,255,.4)", fontFamily: "Inter, sans-serif", fontWeight: 400 }}>{d.desc}</div>
            </button>
          ))}
        </div>

        {/* Summary line */}
        <div style={{
          background: "rgba(0,200,255,.06)", border: "1px solid rgba(0,200,255,.15)",
          borderRadius: 6, padding: ".6rem 1rem", marginBottom: "1.25rem",
          display: "flex", alignItems: "center", gap: ".75rem",
          fontSize: ".68rem", color: "rgba(255,255,255,.55)", fontFamily: "Inter, sans-serif",
        }}>
          <span>📋 {diff.questions} questions</span>
          <span>⏱ {diff.seconds}s per question</span>
          <span>🏆 Up to {diff.questions * 150} pts</span>
        </div>

        {error && (
          <div style={{
            background: "rgba(255,68,51,.1)", border: "1px solid rgba(255,68,51,.35)",
            color: "#FF6655", padding: ".65rem .9rem", borderRadius: 6,
            fontSize: ".8rem", fontFamily: "Inter, sans-serif", marginBottom: "1rem",
          }}>{error}</div>
        )}

        <button className="solo-play-btn" onClick={onStart} disabled={loading}>
          {loading ? "LOADING…" : "⚡ START CHALLENGE"}
        </button>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════════
   GAME SCREEN
══════════════════════════════════════════════════════════════ */
function GameScreen({ question, qIdx, totalQ, timeLeft, maxSeconds, selected, revealed, streak, score, onAnswer }) {
  const optionClass = (i) => {
    if (!revealed) return "solo-opt-btn";
    if (i === question.correct_option) return "solo-opt-btn opt-correct";
    if (i === selected && i !== question.correct_option) return "solo-opt-btn opt-wrong";
    return "solo-opt-btn opt-dim";
  };

  // Keyboard A/B/C/D support
  useEffect(() => {
    const handler = (e) => {
      if (revealed) return;
      const idx = ["a","b","c","d"].indexOf(e.key.toLowerCase());
      if (idx !== -1 && idx < (question.options || []).length) onAnswer(idx);
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, [revealed, question, onAnswer]);

  const streakMultiplier = getMultiplier(streak);
  const progressPct = ((qIdx) / totalQ) * 100;

  return (
    <div className="solo-wrap">
      <style>{CSS}</style>

      {/* HUD */}
      <div className="solo-hud">
        <div className="solo-hud-stat">
          <span className="solo-hud-val" style={{ color: "#E8EEFF" }}>{qIdx + 1}<span style={{ color: "rgba(255,255,255,.25)", fontSize: ".8rem" }}>/{totalQ}</span></span>
          <span className="solo-hud-label">QUESTION</span>
        </div>
        <div className="solo-hud-stat">
          <span className="solo-hud-val" style={{ color: "#FFD700", fontSize: "1.4rem" }}>{score.toLocaleString()}</span>
          <span className="solo-hud-label">SCORE</span>
        </div>
        <div className="solo-hud-stat">
          <span className="solo-hud-val" style={{ color: streak >= 3 ? "#FF6B35" : "#00C8FF" }}>
            {streak >= 2 ? "🔥" : ""} {streak}
            {streak >= 2 && <span style={{ fontSize: ".65rem", color: "#FF6B35", marginLeft: ".2rem" }}>×{streakMultiplier.toFixed(1)}</span>}
          </span>
          <span className="solo-hud-label">STREAK</span>
        </div>
        <TimerRing timeLeft={timeLeft} maxSeconds={maxSeconds} />
      </div>

      {/* Progress bar */}
      <div className="solo-progress-bar">
        <div className="solo-progress-fill" style={{ width: `${progressPct}%` }} />
      </div>

      {/* Question */}
      <div className="solo-q-card">
        <div className="solo-q-num">QUESTION {qIdx + 1} OF {totalQ}</div>
        <p className="solo-q-text">{question.question}</p>
      </div>

      {/* Options */}
      <div className="solo-options">
        {(question.options || []).map((opt, i) => (
          <button
            key={i}
            className={optionClass(i)}
            onClick={() => !revealed && onAnswer(i)}
            disabled={revealed}
          >
            <span className="solo-opt-key">{OPT_KEYS[i]}</span>
            <span className="solo-opt-text">{opt}</span>
          </button>
        ))}
      </div>

      {/* Keyboard hint */}
      <div style={{ textAlign: "center", marginTop: "1rem", fontSize: ".55rem", letterSpacing: ".08em", color: "rgba(255,255,255,.2)" }}>
        PRESS A · B · C · D TO ANSWER
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════════
   RESULTS SCREEN
══════════════════════════════════════════════════════════════ */
function ResultsScreen({ results, questions, score, bestStreak, difficulty, onPlayAgain, onBack }) {
  const correct = results.filter(r => r.correct).length;
  const total = results.length;
  const pct = total > 0 ? Math.round((correct / total) * 100) : 0;
  const gradeInfo = getGradeInfo(pct);
  const avgTime = total > 0
    ? (results.reduce((s, r) => s + r.timeUsed, 0) / total).toFixed(1)
    : 0;
  const diff = DIFFICULTIES.find(d => d.key === difficulty) || DIFFICULTIES[1];

  return (
    <div className="solo-wrap">
      <style>{CSS}</style>
      <SEO title="Solo Results" robots="noindex" />

      <div style={{
        background: "rgba(8,14,28,0.92)",
        border: `1px solid ${gradeInfo.color}30`,
        borderTop: `3px solid ${gradeInfo.color}`,
        borderRadius: 12,
        padding: "2rem",
        textAlign: "center",
      }}>
        {/* Grade */}
        <div className="solo-grade-anim">
          <div
            className="solo-grade-circle"
            style={{
              background: `radial-gradient(circle, ${gradeInfo.color}22 0%, transparent 70%)`,
              border: `3px solid ${gradeInfo.color}`,
              boxShadow: `0 0 40px ${gradeInfo.shadow}, inset 0 0 20px ${gradeInfo.color}11`,
              color: gradeInfo.color,
            }}
          >
            {gradeInfo.grade}
          </div>
        </div>

        <div style={{ fontSize: ".6rem", letterSpacing: ".2em", color: gradeInfo.color, marginBottom: ".3rem" }}>
          {gradeInfo.emoji} {gradeInfo.label}
        </div>
        <h2 style={{ fontSize: "1.4rem", fontWeight: 700, color: "#E8EEFF", margin: "0 0 .25rem" }}>
          {pct}% Correct
        </h2>
        <p style={{ color: "rgba(255,255,255,.4)", fontSize: ".75rem", margin: "0 0 1rem", fontFamily: "Inter, sans-serif" }}>
          {correct} of {total} questions answered correctly
        </p>

        {/* Stat tiles */}
        <div className="solo-stat-row">
          <div className="solo-stat-tile">
            <div className="solo-stat-tile-val" style={{ color: "#FFD700" }}>{score.toLocaleString()}</div>
            <div className="solo-stat-tile-lbl">Total Score</div>
          </div>
          <div className="solo-stat-tile">
            <div className="solo-stat-tile-val" style={{ color: "#22C55E" }}>{correct}/{total}</div>
            <div className="solo-stat-tile-lbl">Correct</div>
          </div>
          <div className="solo-stat-tile">
            <div className="solo-stat-tile-val" style={{ color: "#FF6B35" }}>🔥 {bestStreak}</div>
            <div className="solo-stat-tile-lbl">Best Streak</div>
          </div>
          <div className="solo-stat-tile">
            <div className="solo-stat-tile-val" style={{ color: "#A855F7" }}>{avgTime}s</div>
            <div className="solo-stat-tile-lbl">Avg. Response</div>
          </div>
        </div>

        {/* Answer review */}
        <div style={{ textAlign: "left", marginTop: ".5rem" }}>
          <div style={{ fontSize: ".55rem", letterSpacing: ".12em", color: "rgba(0,200,255,.5)", marginBottom: ".5rem" }}>ANSWER REVIEW</div>
          <div className="solo-answer-review">
            {results.map((r, i) => (
              <div key={i} className={"solo-review-row " + (r.correct ? "r-correct" : "r-wrong")}>
                <span style={{ flexShrink: 0 }}>{r.correct ? "✅" : "❌"}</span>
                <span style={{ flex: 1, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", color: "rgba(255,255,255,.65)" }}>
                  Q{i + 1}: {(questions[i]?.question || "").slice(0, 60)}{questions[i]?.question?.length > 60 ? "…" : ""}
                </span>
                {r.correct && (
                  <span style={{ flexShrink: 0, color: "#FFD700", fontSize: ".65rem" }}>+{r.points}</span>
                )}
                <span style={{ flexShrink: 0, color: "rgba(255,255,255,.3)", fontSize: ".65rem" }}>{r.timeUsed}s</span>
              </div>
            ))}
          </div>
        </div>

        {/* Actions */}
        <div className="solo-action-row" style={{ marginTop: "1.25rem" }}>
          <button className="solo-btn-outline" onClick={onBack}>← ARENA HUB</button>
          <button
            className="solo-play-btn"
            style={{ flex: 2 }}
            onClick={onPlayAgain}
          >
            ↺ PLAY AGAIN
          </button>
        </div>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════════
   MAIN COMPONENT — orchestrates phases
══════════════════════════════════════════════════════════════ */
export default function ArenaSolo() {
  const navigate = useNavigate();

  /* ── Phase ─────────────────────────────────────────── */
  const [phase, setPhase] = useState("setup"); // "setup" | "game" | "results"

  /* ── Setup state ────────────────────────────────────── */
  const [topic, setTopic] = useState("sap-btp");
  const [difficulty, setDifficulty] = useState("normal");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  /* ── Game state ─────────────────────────────────────── */
  const [questions, setQuestions] = useState([]);
  const [qIdx, setQIdx]           = useState(0);
  const [selected, setSelected]   = useState(null);
  const [revealed, setRevealed]   = useState(false);
  const [timeLeft, setTimeLeft]   = useState(30);
  const [timerOn, setTimerOn]     = useState(false);

  /* ── Score state ────────────────────────────────────── */
  const [score, setScore]           = useState(0);
  const [streak, setStreak]         = useState(0);
  const [bestStreak, setBestStreak] = useState(0);
  const [results, setResults]       = useState([]);

  const timerRef = useRef(null);
  const diff = DIFFICULTIES.find(d => d.key === difficulty) || DIFFICULTIES[1];

  /* ── Timer loop ─────────────────────────────────────── */
  useEffect(() => {
    clearInterval(timerRef.current);
    if (!timerOn) return;
    timerRef.current = setInterval(() => {
      setTimeLeft(t => {
        if (t <= 1) {
          clearInterval(timerRef.current);
          // timeout handled via state — see below
          return 0;
        }
        return t - 1;
      });
    }, 1000);
    return () => clearInterval(timerRef.current);
  }, [timerOn, qIdx]);

  /* ── Timeout watcher ────────────────────────────────── */
  useEffect(() => {
    if (timerOn && timeLeft === 0 && !revealed) {
      processAnswer(null);
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [timeLeft, timerOn, revealed]);

  /* ── Answer handler ─────────────────────────────────── */
  const processAnswer = useCallback((optionIndex) => {
    if (revealed) return;
    clearInterval(timerRef.current);
    setTimerOn(false);
    setSelected(optionIndex);
    setRevealed(true);

    const q = questions[qIdx];
    const correct = optionIndex !== null && optionIndex === q.correct_option;
    const timeUsed = diff.seconds - timeLeft;
    const timeBonus = correct ? Math.max(0, Math.floor((timeLeft / diff.seconds) * 50)) : 0;

    setStreak(prev => {
      const newStreak = correct ? prev + 1 : 0;
      setBestStreak(bs => Math.max(bs, newStreak));
      const mult = getMultiplier(newStreak - (correct ? 1 : 0)); // multiplier of the streak BEFORE this answer
      const pts = correct ? Math.floor((100 + timeBonus) * getMultiplier(prev)) : 0;
      setScore(s => s + pts);
      setResults(r => [...r, { correct, timeUsed, points: pts, optionChosen: optionIndex }]);
      return newStreak;
    });

    // Advance after 1.5s
    setTimeout(() => {
      const nextIdx = qIdx + 1;
      if (nextIdx >= questions.length) {
        setPhase("results");
      } else {
        setQIdx(nextIdx);
        setSelected(null);
        setRevealed(false);
        setTimeLeft(diff.seconds);
        setTimeout(() => setTimerOn(true), 150);
      }
    }, 1500);
  }, [revealed, questions, qIdx, diff, timeLeft]);

  /* ── Start game ─────────────────────────────────────── */
  async function startGame() {
    setLoading(true); setError("");
    try {
      const data = await api.get(`/api/arena/solo/questions?topic_id=${topic}&limit=${diff.questions}`);
      if (!data || data.length === 0) throw new Error("No questions found for this topic yet.");
      setQuestions(data);
      setQIdx(0);
      setScore(0);
      setStreak(0);
      setBestStreak(0);
      setResults([]);
      setSelected(null);
      setRevealed(false);
      setTimeLeft(diff.seconds);
      setPhase("game");
      setTimeout(() => setTimerOn(true), 400);
    } catch (e) {
      setError(e.message || "Could not load questions.");
    } finally {
      setLoading(false);
    }
  }

  function resetToSetup() {
    clearInterval(timerRef.current);
    setTimerOn(false);
    setPhase("setup");
    setQIdx(0);
    setSelected(null);
    setRevealed(false);
    setResults([]);
    setScore(0);
    setStreak(0);
  }

  /* ── Render ─────────────────────────────────────────── */
  if (phase === "setup") {
    return (
      <SetupScreen
        topic={topic} setTopic={setTopic}
        difficulty={difficulty} setDifficulty={setDifficulty}
        onStart={startGame} loading={loading} error={error}
        onBack={() => navigate("/arena")}
      />
    );
  }

  if (phase === "game" && questions.length > 0) {
    return (
      <GameScreen
        question={questions[qIdx]}
        qIdx={qIdx}
        totalQ={questions.length}
        timeLeft={timeLeft}
        maxSeconds={diff.seconds}
        selected={selected}
        revealed={revealed}
        streak={streak}
        score={score}
        onAnswer={processAnswer}
      />
    );
  }

  if (phase === "results") {
    return (
      <ResultsScreen
        results={results}
        questions={questions}
        score={score}
        bestStreak={bestStreak}
        difficulty={difficulty}
        onPlayAgain={startGame}
        onBack={() => navigate("/arena")}
      />
    );
  }

  return null;
}
