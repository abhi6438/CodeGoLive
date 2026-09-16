import { useState, useEffect, useRef } from "react";
import { createPortal } from "react-dom";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../lib/AuthContext";
import { api } from "../lib/api";
import SEO from "../components/SEO";

const ARENA_THEME_CSS = `
  .arena-page {
    --ah-bg:      #0C1220;
    --ah-surf:    #141D2E;
    --ah-surf2:   #1E2B42;
    --ah-text:    #E8EEFF;
    --ah-text2:   #7B8DB0;
    --ah-text3:   #3A4A68;
    --ah-item-bg: rgba(255,255,255,.02);
    --ah-item-bd: rgba(0,200,255,.07);
    --ah-dot:     rgba(58,74,104,.4);
  }
  @media (prefers-color-scheme: light) {
    :root:not([data-theme="dark"]) .arena-page {
      --ah-bg:      #F8FAFF;
      --ah-surf:    #EEF2FF;
      --ah-surf2:   #E0E7FF;
      --ah-text:    #0F172A;
      --ah-text2:   #475569;
      --ah-text3:   #94A3B8;
      --ah-item-bg: rgba(79,70,229,.04);
      --ah-item-bd: rgba(79,70,229,.10);
      --ah-dot:     rgba(79,70,229,.12);
    }
  }
  :root[data-theme="light"] .arena-page {
    --ah-bg:      #F8FAFF;
    --ah-surf:    #EEF2FF;
    --ah-surf2:   #E0E7FF;
    --ah-text:    #0F172A;
    --ah-text2:   #475569;
    --ah-text3:   #94A3B8;
    --ah-item-bg: rgba(79,70,229,.04);
    --ah-item-bd: rgba(79,70,229,.10);
    --ah-dot:     rgba(79,70,229,.12);
  }
`;


const ORBITRON = `@import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@400;600;700;900&display=swap');`;

const MODES = [
  {
    to: "/arena/lobby",
    icon: "⚔️",
    type: "VERSUS",
    name: "1v1 Battle",
    desc: "Challenge any learner to a real-time quiz duel. First to 10 correct wins.",
    ap: "Earn up to 200 XP per match",
    color: "#00C8FF",
    variant: "accent",
  },
  {
    to: "/arena/quests",
    icon: "📋",
    type: "DAILY",
    name: "Quests",
    desc: "Complete daily and weekly missions to stack XP and AP bonuses.",
    ap: "Up to +500 XP per week",
    color: "#FF5722",
    variant: "fire",
  },
  {
    to: "/arena/trophies",
    icon: "🏆",
    type: "COLLECTION",
    name: "Trophies",
    desc: "Unlock achievement badges from Common to Legendary rarity.",
    ap: "Flex your milestones",
    color: "#FFB300",
    variant: "gold",
  },
  {
    to: "/arena/ranks",
    icon: "📊",
    type: "GLOBAL",
    name: "Leaderboard",
    desc: "Climb the global XP rankings. Top players earn special recognition.",
    ap: "Top 3 get crowns 👑",
    color: "#A855F7",
    variant: "purple",
  },
  {
    to: "/arena/history",
    icon: "📜",
    type: "STATS",
    name: "Match History",
    desc: "Review your past battles. See win/loss record, scores, and per-match breakdowns.",
    ap: "Track your progress",
    color: "#00C8FF",
    variant: "cyan",
  },
  {
    to: "/arena/spin",
    icon: "🎰",
    type: "DAILY",
    name: "Spin Wheel",
    desc: "1 free spin every 24 hours. Win AP, XP, power-ups, or the jackpot.",
    ap: "Jackpot: 1 000 AP",
    color: "#FF5722",
    variant: "fire",
  },
  {
    to: "/arena/season",
    icon: "🏆",
    type: "SEASON",
    name: "Season Ranks",
    desc: "Climb AP rank tiers — Bronze to Legend. Resets monthly. XP is permanent.",
    ap: "Reach Legend to flex 👑",
    color: "#FFB300",
    variant: "gold",
  },
  {
    to: "/arena/tournament",
    icon: "🏟️",
    type: "BRACKET",
    name: "Tournament",
    desc: "4 or 8 players. Single-elimination bracket. One champion crowned.",
    ap: "Winner takes the glory",
    color: "#A855F7",
    variant: "purple",
  },
];

/* ── FULL-SCREEN GORILLA BATTLE CANVAS ── */
function GorillaBattleBg() {
  const canvasRef = useRef(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    let raf;
    let t = 0;

    const NUM_SPARKS = 60;
    const sparks = [];

    function makeSpark() {
      const cx = canvas.width / 2, cy = canvas.height * 0.42;
      return {
        x: cx + (Math.random() - 0.5) * 140,
        y: cy + (Math.random() - 0.5) * 70,
        vx: (Math.random() - 0.5) * 16,
        vy: -(Math.random() * 11 + 2),
        life: Math.random() * 50,
        maxLife: 30 + Math.random() * 50,
        r: 1.5 + Math.random() * 4,
      };
    }

    function updateOpacity() {
      const dt = document.documentElement.getAttribute('data-theme');
      const isDark = dt === 'dark' || (!dt && window.matchMedia('(prefers-color-scheme: dark)').matches);
      canvas.style.opacity = isDark ? '1.0' : '0.65';
    }

    function resize() {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
      sparks.length = 0;
      for (let i = 0; i < NUM_SPARKS; i++) sparks.push(makeSpark());
      updateOpacity();
    }

    resize();
    window.addEventListener('resize', resize);
    const mo = new MutationObserver(updateOpacity);
    mo.observe(document.documentElement, { attributes: true, attributeFilter: ['data-theme'] });
    const mq = window.matchMedia('(prefers-color-scheme: dark)');
    mq.addEventListener('change', updateOpacity);

    /* Draw one gorilla silhouette.
       x,y = bottom-center on screen, scale = size factor,
       flip = mirror (right gorilla), punchT = 0..1 punch extension, swayY = bob offset */
    function drawGorilla(x, y, scale, flip, punchT, swayY) {
      ctx.save();
      ctx.translate(x, y + swayY);
      if (flip) ctx.scale(-1, 1);
      ctx.scale(scale, scale);
      // Rim-light glow: left gorilla gets cyan glow, right gorilla gets orange glow
      ctx.shadowBlur = 38;
      ctx.shadowColor = flip ? 'rgba(255,100,0,0.85)' : 'rgba(0,200,255,0.75)';
      ctx.fillStyle = 'rgba(6,10,22,0.94)';

      // Feet
      ctx.beginPath(); ctx.ellipse(-32, 0, 46, 15, 0, 0, Math.PI * 2); ctx.fill();
      ctx.beginPath(); ctx.ellipse(44, -4, 46, 15, 0, 0, Math.PI * 2); ctx.fill();

      // Legs
      ctx.beginPath(); ctx.ellipse(-28, -68, 36, 72, 0.05, 0, Math.PI * 2); ctx.fill();
      ctx.beginPath(); ctx.ellipse(36, -62, 36, 72, -0.05, 0, Math.PI * 2); ctx.fill();

      // Torso
      ctx.beginPath(); ctx.ellipse(0, -175, 100, 118, 0, 0, Math.PI * 2); ctx.fill();

      // Shoulder pads (wide)
      ctx.beginPath(); ctx.ellipse(-110, -248, 60, 44, -0.25, 0, Math.PI * 2); ctx.fill();
      ctx.beginPath(); ctx.ellipse(110, -248, 60, 44, 0.25, 0, Math.PI * 2); ctx.fill();

      // Left arm (resting / knuckle drag)
      ctx.beginPath();
      ctx.moveTo(-78, -215);
      ctx.bezierCurveTo(-168, -155, -180, -70, -128, 28);
      ctx.bezierCurveTo(-112, 56, -70, 52, -55, 4);
      ctx.bezierCurveTo(-88, -54, -108, -125, -68, -205);
      ctx.closePath(); ctx.fill();
      // Left knuckle fist
      ctx.beginPath(); ctx.ellipse(-128, 36, 40, 26, 0.2, 0, Math.PI * 2); ctx.fill();

      // Right arm — punching toward center
      const aX = 95 + punchT * 170;
      const aY = -220 + punchT * 90;
      ctx.beginPath();
      ctx.moveTo(74, -225);
      ctx.bezierCurveTo(92, -200, aX - 90, aY + 50, aX, aY);
      ctx.bezierCurveTo(aX + 35, aY - 28, aX + 12, aY - 70, aX - 55, aY - 52);
      ctx.bezierCurveTo(aX - 95, aY - 20, 93, -198, 74, -248);
      ctx.closePath(); ctx.fill();
      // Punching fist
      ctx.beginPath(); ctx.ellipse(aX, aY, 44, 36, 0.15, 0, Math.PI * 2); ctx.fill();

      // Neck
      ctx.beginPath(); ctx.ellipse(0, -288, 54, 40, 0, 0, Math.PI * 2); ctx.fill();

      // Head
      ctx.beginPath(); ctx.ellipse(6, -360, 70, 64, 0, 0, Math.PI * 2); ctx.fill();

      // Sagittal crest
      ctx.beginPath(); ctx.ellipse(2, -412, 22, 30, 0, 0, Math.PI * 2); ctx.fill();
      ctx.beginPath(); ctx.ellipse(2, -430, 13, 18, 0, 0, Math.PI * 2); ctx.fill();

      // Brow ridge
      ctx.beginPath(); ctx.ellipse(5, -344, 70, 21, 0.05, 0, Math.PI * 2); ctx.fill();

      // Muzzle / snout
      ctx.beginPath(); ctx.ellipse(48, -336, 40, 30, 0, 0, Math.PI * 2); ctx.fill();
      ctx.beginPath(); ctx.ellipse(64, -318, 24, 17, 0.1, 0, Math.PI * 2); ctx.fill();

      // ── GLOWING EYES ──
      ctx.restore();
      ctx.save();
      ctx.translate(x, y + swayY);
      if (flip) ctx.scale(-1, 1);
      ctx.scale(scale, scale);
      ctx.shadowBlur = 0; // reset shadow so eye glow renders cleanly

      // Outer eye glow
      const eg = ctx.createRadialGradient(-18, -364, 0, -18, -364, 28);
      eg.addColorStop(0, 'rgba(255,70,0,1)');
      eg.addColorStop(0.45, 'rgba(255,30,0,0.65)');
      eg.addColorStop(1, 'rgba(180,0,0,0)');
      ctx.fillStyle = eg;
      ctx.beginPath(); ctx.ellipse(-18, -364, 28, 28, 0, 0, Math.PI * 2); ctx.fill();

      // Iris
      ctx.fillStyle = 'rgba(255,220,0,0.88)';
      ctx.beginPath(); ctx.ellipse(-18, -364, 12, 14, 0, 0, Math.PI * 2); ctx.fill();

      // Pupil
      ctx.fillStyle = 'rgba(90,0,0,0.85)';
      ctx.beginPath(); ctx.ellipse(-18, -364, 5, 7, 0, 0, Math.PI * 2); ctx.fill();

      ctx.restore();
    }

    function frame() {
      t += 0.014;
      const W = canvas.width, H = canvas.height;
      ctx.clearRect(0, 0, W, H);

      // ── EDGE ATMOSPHERE (no full-bg fill — keeps UI text readable) ──
      // Left edge darkness
      const leftEdge = ctx.createLinearGradient(0, 0, W * 0.28, 0);
      leftEdge.addColorStop(0, 'rgba(4,6,18,0.55)');
      leftEdge.addColorStop(1, 'rgba(0,0,0,0)');
      ctx.fillStyle = leftEdge; ctx.fillRect(0, 0, W * 0.28, H);
      // Right edge darkness
      const rightEdge = ctx.createLinearGradient(W * 0.72, 0, W, 0);
      rightEdge.addColorStop(0, 'rgba(0,0,0,0)');
      rightEdge.addColorStop(1, 'rgba(4,6,18,0.55)');
      ctx.fillStyle = rightEdge; ctx.fillRect(W * 0.72, 0, W * 0.28, H);
      // Bottom ground haze
      const fog = ctx.createLinearGradient(0, H * 0.82, 0, H);
      fog.addColorStop(0, 'rgba(6,3,2,0)');
      fog.addColorStop(1, 'rgba(6,3,2,0.45)');
      ctx.fillStyle = fog; ctx.fillRect(0, H * 0.82, W, H * 0.18);

      const cx = W / 2, cy = H * 0.42;
      const p1 = 0.5 + 0.5 * Math.sin(t * 3.8);
      const p2 = 0.5 + 0.5 * Math.cos(t * 2.5);

      // Outer battle glow
      const bg1 = ctx.createRadialGradient(cx, cy, 0, cx, cy, W * 0.38 + p1 * 60);
      bg1.addColorStop(0,   `rgba(255,160,0,${0.42 + p1 * 0.16})`);
      bg1.addColorStop(0.35,`rgba(220,60,0,${0.22 + p1 * 0.08})`);
      bg1.addColorStop(0.7, `rgba(180,20,0,0.06)`);
      bg1.addColorStop(1,   'rgba(0,0,0,0)');
      ctx.fillStyle = bg1; ctx.fillRect(0, 0, W, H);

      // Inner hot core
      const bg2 = ctx.createRadialGradient(cx, cy, 0, cx, cy, 120 + p2 * 45);
      bg2.addColorStop(0,   `rgba(255,250,200,${0.88 + p1 * 0.12})`);
      bg2.addColorStop(0.3, `rgba(255,180,0,${0.65 + p1 * 0.15})`);
      bg2.addColorStop(0.7, `rgba(255,60,0,0.18)`);
      bg2.addColorStop(1,   'rgba(255,20,0,0)');
      ctx.fillStyle = bg2;
      ctx.beginPath(); ctx.arc(cx, cy, 120 + p2 * 45, 0, Math.PI * 2); ctx.fill();

      // ── GORILLAS ──
      const gScale = Math.min(H / 310, W / 440, 3.2);
      const gY = H * 0.99;
      const leftPunch  = Math.max(0, Math.sin(t * 1.6)) * 0.92;
      const rightPunch = Math.max(0, Math.sin(t * 1.6 + Math.PI)) * 0.92;
      const leftBob  = Math.sin(t * 1.6) * 13;
      const rightBob = Math.sin(t * 1.6 + Math.PI) * 13;

      drawGorilla(W * 0.18, gY, gScale, false, leftPunch, leftBob);
      drawGorilla(W * 0.82, gY, gScale, true, rightPunch, rightBob);

      // ── SPARKS ──
      sparks.forEach(sp => {
        sp.life++;
        sp.x += sp.vx;
        sp.y += sp.vy;
        sp.vy += 0.28;
        if (sp.life >= sp.maxLife) Object.assign(sp, makeSpark());
        const a = Math.pow(Math.max(0, 1 - sp.life / sp.maxLife), 0.6);
        const sg = ctx.createRadialGradient(sp.x, sp.y, 0, sp.x, sp.y, sp.r * 2.5);
        sg.addColorStop(0,   `rgba(255,235,110,${a})`);
        sg.addColorStop(0.5, `rgba(255,100,0,${a * 0.5})`);
        sg.addColorStop(1,   'rgba(255,40,0,0)');
        ctx.fillStyle = sg;
        ctx.beginPath(); ctx.arc(sp.x, sp.y, sp.r * 2.5, 0, Math.PI * 2); ctx.fill();
      });

      // ── VIGNETTE ──
      const vig = ctx.createRadialGradient(W/2, H/2, H * 0.18, W/2, H/2, H * 0.88);
      vig.addColorStop(0, 'rgba(0,0,0,0)');
      vig.addColorStop(1, 'rgba(0,0,0,0.62)');
      ctx.fillStyle = vig; ctx.fillRect(0, 0, W, H);

      raf = requestAnimationFrame(frame);
    }

    frame();

    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener('resize', resize);
      mo.disconnect();
      mq.removeEventListener('change', updateOpacity);
    };
  }, []);

  return createPortal(
    <canvas
      ref={canvasRef}
      style={{ position: 'fixed', inset: 0, width: '100%', height: '100%', zIndex: 9999, pointerEvents: 'none' }}
      aria-hidden="true"
    />,
    document.body
  );
}

function streakMultLabel(mult) {
  if (mult >= 2.0) return { label: "×2.0 🔥", color: "#FF5722" };
  if (mult >= 1.5) return { label: "×1.5 🔥", color: "#FF8C00" };
  if (mult >= 1.2) return { label: "×1.2 🔥", color: "#FFB300" };
  return null;
}

export default function ArenaHub() {
  const { session } = useAuth();
  const navigate = useNavigate();
  const [stats, setStats] = useState(null);
  const [hover, setHover] = useState(null);

  useEffect(() => {
    if (!session) return;
    api.get("/api/arena/stats").then(setStats).catch(() => {});
  }, [session]);

  const level     = stats?.level || 1;
  const lvlPct    = stats?.level_progress_pct || 0;
  const xpInLvl   = stats?.xp_in_level || 0;
  const xpForNext = stats?.xp_for_next_level || 100;
  const actStreak = stats?.activity_streak_days || 0;
  const multInfo  = streakMultLabel(stats?.streak_multiplier || 1.0);

  const variantColors = {
    accent: { border: "rgba(0,200,255,.25)", bg: "rgba(0,200,255,.07)", glow: "rgba(0,200,255,.18)", btnBg: "rgba(0,200,255,.1)", btnColor: "#00C8FF", btnBorder: "rgba(0,200,255,.3)" },
    fire:   { border: "rgba(255,87,34,.25)",  bg: "rgba(255,87,34,.07)",  glow: "rgba(255,87,34,.18)",  btnBg: "rgba(255,87,34,.1)",  btnColor: "#FF5722", btnBorder: "rgba(255,87,34,.3)" },
    gold:   { border: "rgba(255,179,0,.25)",  bg: "rgba(255,179,0,.07)",  glow: "rgba(255,179,0,.18)",  btnBg: "rgba(255,179,0,.1)",  btnColor: "#FFB300", btnBorder: "rgba(255,179,0,.3)" },
    purple: { border: "rgba(168,85,247,.25)", bg: "rgba(168,85,247,.07)", glow: "rgba(168,85,247,.18)", btnBg: "rgba(168,85,247,.1)", btnColor: "#A855F7", btnBorder: "rgba(168,85,247,.3)" },
    cyan:   { border: "rgba(0,200,255,.25)",  bg: "rgba(0,200,255,.07)",  glow: "rgba(0,200,255,.18)",  btnBg: "rgba(0,200,255,.1)",  btnColor: "#00C8FF", btnBorder: "rgba(0,200,255,.3)" },
  };

  return (
    <>
      <SEO title="Developer Arena" description="The CodeGoLive Arena hub — battles, quests, tournaments and ranks." robots="noindex, nofollow" />
      <GorillaBattleBg />
      <div className="arena-page" style={{ maxWidth: 1400, margin: "0 auto", padding: "1.75rem 2.5rem 3rem", position: "relative", zIndex: 1, width: "100%", boxSizing: "border-box" }}>
      <style>{ARENA_THEME_CSS}{ORBITRON}{`
        .arena-hub-bg::before {
          content: '';
          position: fixed; inset: 0; pointer-events: none; z-index: 0;
          background-image: radial-gradient(circle, var(--ah-dot) 1px, transparent 1px);
          background-size: 32px 32px;
        }
        .arena-mode-card { transition: transform .15s, box-shadow .15s !important; }
        .arena-mode-card:hover { transform: translateY(-3px) !important; }
      `}</style>

      {/* ── HERO STATS HEADER ── */}
      <div style={{
        background: "linear-gradient(135deg, var(--ah-bg) 0%, var(--ah-surf) 100%)",
        border: "1px solid rgba(0,200,255,.18)",
        borderRadius: 8,
        padding: "1.5rem 1.75rem",
        marginBottom: "1.5rem",
        position: "relative",
        overflow: "hidden",
      }}>
        {/* glow burst */}
        <div style={{ position: "absolute", inset: 0, pointerEvents: "none", background: "radial-gradient(ellipse 60% 40% at 50% 0%, rgba(0,200,255,.06) 0%, transparent 70%)" }} />

        <div style={{ display: "flex", alignItems: "center", gap: "1rem", flexWrap: "wrap", marginBottom: "1.25rem" }}>
          <div style={{ width: 48, height: 48, borderRadius: 6, background: "rgba(0,200,255,.12)", border: "1px solid rgba(0,200,255,.3)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: "1.5rem", flexShrink: 0 }}>⚔️</div>
          <div>
            <h1 style={{ fontFamily: "'Orbitron', sans-serif", fontSize: "clamp(1.2rem,3vw,1.7rem)", fontWeight: 700, letterSpacing: ".04em", color: "var(--ah-text)", margin: 0 }}>Developer Arena</h1>
            <p style={{ margin: ".2rem 0 0", fontSize: ".82rem", color: "var(--ah-text2)" }}>Challenge learners · Climb ranks · Earn rewards</p>
          </div>
          {/* Level badge */}
          <div style={{ marginLeft: "auto", display: "flex", alignItems: "center", gap: ".5rem", background: "rgba(0,200,255,.08)", border: "1px solid rgba(0,200,255,.3)", borderRadius: 6, padding: ".4rem .9rem" }}>
            <span style={{ fontFamily: "'Orbitron', sans-serif", fontSize: ".6rem", color: "var(--ah-text2)", letterSpacing: ".1em" }}>LVL</span>
            <span style={{ fontFamily: "'Orbitron', sans-serif", fontSize: "1.05rem", fontWeight: 900, color: "#00C8FF" }}>{level}</span>
            {multInfo && (
              <span style={{ fontFamily: "'Orbitron', sans-serif", fontSize: ".6rem", fontWeight: 700, color: multInfo.color, marginLeft: ".2rem", background: "rgba(255,255,255,.06)", borderRadius: 3, padding: ".15rem .4rem" }}>{multInfo.label}</span>
            )}
          </div>
        </div>

        {/* Level XP progress bar */}
        <div style={{ marginBottom: "1rem" }}>
          <div style={{ display: "flex", justifyContent: "space-between", fontSize: ".68rem", color: "var(--ah-text2)", marginBottom: 4, fontFamily: "'Orbitron', sans-serif", letterSpacing: ".06em" }}>
            <span>LEVEL {level} → {level + 1}</span>
            <span style={{ color: "#00C8FF" }}>{xpInLvl.toLocaleString()} / {xpForNext.toLocaleString()} XP</span>
          </div>
          <div style={{ height: 6, background: "var(--ah-surf2)", borderRadius: 3, overflow: "hidden" }}>
            <div style={{ height: "100%", width: `${lvlPct}%`, background: "linear-gradient(90deg, #00C8FF, #006FFF)", borderRadius: 3, boxShadow: "0 0 8px rgba(0,200,255,.4)", transition: "width .6s" }} />
          </div>
          {actStreak >= 3 && (
            <div style={{ marginTop: 4, fontSize: ".62rem", color: "#FFB300", fontFamily: "'Orbitron', sans-serif", letterSpacing: ".06em" }}>
              🔥 {actStreak}-DAY STREAK — {multInfo ? multInfo.label + " XP bonus active" : "keep it up!"}
            </div>
          )}
        </div>

        {/* Stat chips */}
        <div style={{ display: "flex", gap: ".6rem", flexWrap: "wrap" }}>
          {[
            { icon: "⚡", label: "Arena XP",  val: stats?.xp?.toLocaleString()           || "—", color: "#00C8FF", bg: "rgba(0,200,255,.07)",  bd: "rgba(0,200,255,.2)" },
            { icon: "💎", label: "AP",         val: stats?.ap?.toLocaleString()           || "—", color: "#FFB300", bg: "rgba(255,179,0,.07)",  bd: "rgba(255,179,0,.2)" },
            { icon: "🏆", label: "Wins",       val: stats?.wins                           || "—", color: "#00E676", bg: "rgba(0,230,118,.07)",  bd: "rgba(0,230,118,.2)" },
            { icon: "🔥", label: "Day Streak", val: actStreak ? `${actStreak}d`           : "—", color: "#FF5722", bg: "rgba(255,87,34,.07)",  bd: "rgba(255,87,34,.2)" },
            { icon: "⚔️", label: "Matches",    val: stats?.matches_played                 || "—", color: "#A855F7", bg: "rgba(168,85,247,.07)", bd: "rgba(168,85,247,.2)" },
          ].map(s => (
            <div key={s.label} style={{ background: s.bg, border: `1px solid ${s.bd}`, borderRadius: 4, padding: ".35rem .8rem", display: "flex", alignItems: "center", gap: ".4rem" }}>
              <span style={{ fontSize: ".8rem" }}>{s.icon}</span>
              <span style={{ fontSize: ".68rem", color: "var(--ah-text2)" }}>{s.label}</span>
              <span style={{ fontFamily: "'Orbitron', monospace", fontSize: ".75rem", fontWeight: 700, color: s.color }}>{s.val}</span>
            </div>
          ))}
          {!session && <Link to="/login" style={{ marginLeft: "auto", fontSize: ".78rem", fontWeight: 600, color: "#00C8FF", textDecoration: "none", alignSelf: "center" }}>Sign in to track stats →</Link>}
        </div>
      </div>

      {/* ── DAILY CHALLENGE BANNER ── */}
      <div
        onClick={() => navigate("/arena/lobby")}
        style={{
          background: "linear-gradient(135deg, var(--ah-surf), var(--ah-surf2))",
          border: "1px solid rgba(0,200,255,.3)",
          borderRadius: 6,
          padding: "1rem 1.25rem",
          display: "flex", alignItems: "center", gap: "1rem",
          marginBottom: "1.25rem",
          cursor: "pointer",
          boxShadow: "0 0 0 rgba(0,200,255,0)",
          transition: "box-shadow .2s",
        }}
        onMouseEnter={e => e.currentTarget.style.boxShadow = "0 0 20px rgba(0,200,255,.18)"}
        onMouseLeave={e => e.currentTarget.style.boxShadow = "0 0 0 rgba(0,200,255,0)"}
      >
        <div style={{ fontSize: "1.6rem", flexShrink: 0 }}>⚡</div>
        <div style={{ flex: 1 }}>
          <div style={{ fontFamily: "'Orbitron', sans-serif", fontSize: ".72rem", fontWeight: 700, color: "var(--ah-text)", marginBottom: 2 }}>DAILY BATTLE</div>
          <div style={{ fontSize: ".75rem", color: "var(--ah-text2)" }}>Jump into a live 1v1 match — new opponents every day</div>
        </div>
        <button style={{ fontFamily: "'Orbitron', sans-serif", fontSize: ".62rem", fontWeight: 700, letterSpacing: ".08em", padding: "8px 16px", background: "#00C8FF", color: "#070B16", border: "none", borderRadius: 4, cursor: "pointer", whiteSpace: "nowrap" }}>
          BATTLE NOW
        </button>
      </div>

      {/* ── MODE CARDS ── */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(230px, 1fr))", gap: ".9rem", marginBottom: "1.75rem" }}>
        {MODES.map((m, i) => {
          const v = variantColors[m.variant];
          const isHover = hover === i;
          return (
            <Link
              key={m.to}
              to={m.to}
              className="arena-mode-card"
              onMouseEnter={() => setHover(i)}
              onMouseLeave={() => setHover(null)}
              style={{
                textDecoration: "none",
                background: isHover ? "var(--ah-surf)" : "var(--ah-bg)",
                border: `1px solid ${v.border}`,
                borderLeft: `3px solid ${m.color}`,
                borderRadius: 4,
                padding: "1.2rem",
                display: "flex", flexDirection: "column", gap: ".6rem",
                boxShadow: isHover ? `0 8px 28px rgba(0,0,0,.4), 0 0 0 1px ${v.glow}` : "none",
                position: "relative", overflow: "hidden",
              }}
            >
              {isHover && <div style={{ position: "absolute", inset: 0, background: `radial-gradient(ellipse at top left, ${v.bg} 0%, transparent 65%)`, pointerEvents: "none" }} />}
              <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                <span style={{ fontSize: "1.4rem" }}>{m.icon}</span>
                <span style={{ fontFamily: "'Orbitron', monospace", fontSize: ".52rem", letterSpacing: ".12em", color: "var(--ah-text3)", textTransform: "uppercase" }}>{m.type}</span>
              </div>
              <div>
                <div style={{ fontFamily: "'Orbitron', sans-serif", fontSize: ".85rem", fontWeight: 700, color: "var(--ah-text)", marginBottom: ".25rem" }}>{m.name}</div>
                <div style={{ fontSize: ".74rem", color: "var(--ah-text2)", lineHeight: 1.5 }}>{m.desc}</div>
              </div>
              <div style={{ fontSize: ".68rem", color: m.color, marginTop: "auto" }}>{m.ap}</div>
              <div style={{ fontFamily: "'Orbitron', sans-serif", fontSize: ".6rem", fontWeight: 700, letterSpacing: ".08em", padding: "7px", background: v.btnBg, border: `1px solid ${v.btnBorder}`, color: v.btnColor, borderRadius: 3, textAlign: "center" }}>
                ENTER →
              </div>
            </Link>
          );
        })}
      </div>

      {/* ── HOW IT WORKS ── */}
      <div style={{ background: "var(--ah-bg)", border: "1px solid rgba(0,200,255,.1)", borderRadius: 6, padding: "1.25rem 1.4rem" }}>
        <div style={{ fontFamily: "'Orbitron', sans-serif", fontSize: ".6rem", fontWeight: 700, letterSpacing: ".16em", textTransform: "uppercase", color: "#00C8FF", marginBottom: "1rem" }}>HOW ARENA WORKS</div>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(175px, 1fr))", gap: ".5rem" }}>
          {[
            ["⚡","Time scoring","Answer faster for up to 5× multiplier"],
            ["🔥","Combo chains","3+ correct in a row = bonus XP burst"],
            ["💬","Live chat","Trash talk your opponent mid-match"],
            ["😤","Provoke","Send taunts that shake their screen"],
            ["📋","Daily quests","Missions that refresh every 24 h"],
            ["🎰","Spin wheel","Free daily spin for AP & power-ups"],
            ["🏆","Trophies","Common → Legendary achievement badges"],
            ["👑","Leaderboard","Top players earn special rank crowns"],
          ].map(([icon, title, desc]) => (
            <div key={title} style={{ display: "flex", gap: ".5rem", alignItems: "flex-start", padding: ".5rem .6rem", background: "var(--ah-item-bg)", borderRadius: 4, border: "1px solid rgba(0,200,255,.07)" }}>
              <span style={{ fontSize: ".95rem", flexShrink: 0, marginTop: ".05rem" }}>{icon}</span>
              <div>
                <div style={{ fontSize: ".76rem", fontWeight: 600, color: "var(--ah-text)" }}>{title}</div>
                <div style={{ fontSize: ".69rem", color: "var(--ah-text2)", marginTop: ".1rem", lineHeight: 1.4 }}>{desc}</div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </>
  );
}
