import { useEffect } from "react";
import { useNavigate } from "react-router-dom";

/* ── Particle canvas background ─────────────────────────────── */
function HomeParticles() {
  useEffect(() => {
    const canvas = document.createElement("canvas");
    canvas.id = "home-particles-canvas";
    canvas.style.cssText =
      "position:fixed;inset:0;width:100%;height:100%;z-index:0;pointer-events:none;";
    document.body.appendChild(canvas);
    const ctx = canvas.getContext("2d");

    let W, H, raf;

    function resize() {
      W = canvas.width = window.innerWidth;
      H = canvas.height = window.innerHeight;
    }

    // 120 particles — blue sparks on left, orange embers on right
    const pts = Array.from({ length: 120 }, (_, i) => ({
      x: Math.random(),
      y: Math.random(),
      vx: (Math.random() - 0.5) * 0.002,
      vy: -(Math.random() * 0.003 + 0.001),
      r: Math.random() * 2 + 0.5,
      life: Math.random(),
      side: i < 60 ? "left" : "right", // blue | orange
    }));

    function reset(p) {
      p.x = Math.random();
      p.y = 1.05 + Math.random() * 0.1;
      p.vx = (Math.random() - 0.5) * 0.002;
      p.vy = -(Math.random() * 0.003 + 0.001);
      p.r = Math.random() * 2 + 0.5;
      p.life = 0.8 + Math.random() * 0.2;
    }

    // Pre-generate lightning bolts
    const bolts = [];
    function genBolt(side) {
      const x0 = side === "left" ? Math.random() * 0.45 : 0.55 + Math.random() * 0.45;
      const segs = [];
      let cx = x0, cy = 0;
      while (cy < 0.7) {
        cx += (Math.random() - 0.5) * 0.06;
        cy += 0.06 + Math.random() * 0.08;
        segs.push([cx, cy]);
      }
      bolts.push({ segs, x0, side, age: 0, maxAge: 8 + Math.random() * 6 });
    }

    let t = 0;
    function frame() {
      t++;
      ctx.clearRect(0, 0, W, H);

      // ── Sky gradient ───────────────────────────────────────────
      const sky = ctx.createLinearGradient(0, 0, W, H);
      sky.addColorStop(0, "#020510");
      sky.addColorStop(0.45, "#050A18");
      sky.addColorStop(0.55, "#0A0505");
      sky.addColorStop(1, "#050200");
      ctx.fillStyle = sky;
      ctx.fillRect(0, 0, W, H);

      // ── Center clash glow ─────────────────────────────────────
      const mid = W / 2;
      const clashPulse = 0.22 + 0.06 * Math.sin(t * 0.05);
      const leftGlow = ctx.createRadialGradient(mid, H * 0.5, 0, mid, H * 0.5, W * 0.32);
      leftGlow.addColorStop(0, `rgba(0,180,255,${clashPulse})`);
      leftGlow.addColorStop(1, "rgba(0,0,0,0)");
      ctx.fillStyle = leftGlow;
      ctx.fillRect(0, 0, W, H);

      const rightGlow = ctx.createRadialGradient(mid, H * 0.5, 0, mid, H * 0.5, W * 0.32);
      rightGlow.addColorStop(0, `rgba(255,90,0,${clashPulse})`);
      rightGlow.addColorStop(1, "rgba(0,0,0,0)");
      ctx.fillStyle = rightGlow;
      ctx.fillRect(0, 0, W, H);

      // ── Divider line ─────────────────────────────────────────
      const lineGrad = ctx.createLinearGradient(mid, 0, mid, H);
      lineGrad.addColorStop(0, "rgba(0,200,255,0)");
      lineGrad.addColorStop(0.25, `rgba(0,200,255,${0.45 + 0.15 * Math.sin(t * 0.07)})`);
      lineGrad.addColorStop(0.5, `rgba(255,255,255,${0.6 + 0.2 * Math.sin(t * 0.07)})`);
      lineGrad.addColorStop(0.75, `rgba(255,100,0,${0.45 + 0.15 * Math.sin(t * 0.07)})`);
      lineGrad.addColorStop(1, "rgba(255,100,0,0)");
      ctx.strokeStyle = lineGrad;
      ctx.lineWidth = 1.5;
      ctx.beginPath();
      ctx.moveTo(mid, 0);
      ctx.lineTo(mid, H);
      ctx.stroke();

      // ── Particles ─────────────────────────────────────────────
      pts.forEach((p) => {
        p.x += p.vx;
        p.y += p.vy;
        p.life -= 0.004;
        if (p.life <= 0 || p.y < -0.05) reset(p);

        const px = p.x * W, py = p.y * H;
        // Constrain to correct side
        if (p.side === "left" && px > mid + 40) return;
        if (p.side === "right" && px < mid - 40) return;

        ctx.globalAlpha = p.life * 0.7;
        ctx.shadowBlur = 10;
        if (p.side === "left") {
          ctx.shadowColor = "#00C8FF";
          ctx.fillStyle = `rgba(0,${180 + Math.floor(Math.random() * 75)},255,1)`;
        } else {
          ctx.shadowColor = "#FF6B00";
          ctx.fillStyle = `rgba(255,${70 + Math.floor(Math.random() * 80)},0,1)`;
        }
        ctx.beginPath();
        ctx.arc(px, py, p.r, 0, Math.PI * 2);
        ctx.fill();
        ctx.shadowBlur = 0;
      });
      ctx.globalAlpha = 1;

      // ── Lightning bolts ──────────────────────────────────────
      if (t % 90 === 0) genBolt("left");
      if (t % 120 === 0) genBolt("right");

      for (let i = bolts.length - 1; i >= 0; i--) {
        const b = bolts[i];
        b.age++;
        if (b.age > b.maxAge) { bolts.splice(i, 1); continue; }
        const alpha = (1 - b.age / b.maxAge) * 0.5;
        ctx.strokeStyle = b.side === "left"
          ? `rgba(0,200,255,${alpha})`
          : `rgba(255,150,0,${alpha})`;
        ctx.lineWidth = 1;
        ctx.shadowColor = b.side === "left" ? "#00C8FF" : "#FF8800";
        ctx.shadowBlur = 8;
        ctx.beginPath();
        ctx.moveTo(b.x0 * W, 0);
        b.segs.forEach(([sx, sy]) => ctx.lineTo(sx * W, sy * H));
        ctx.stroke();
        ctx.shadowBlur = 0;
      }

      // ── Vignette ─────────────────────────────────────────────
      const vig = ctx.createRadialGradient(W / 2, H / 2, H * 0.25, W / 2, H / 2, H * 0.85);
      vig.addColorStop(0, "rgba(0,0,0,0)");
      vig.addColorStop(1, "rgba(0,0,0,0.55)");
      ctx.fillStyle = vig;
      ctx.fillRect(0, 0, W, H);

      raf = requestAnimationFrame(frame);
    }

    resize();
    window.addEventListener("resize", resize);
    frame();

    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener("resize", resize);
      canvas.remove();
    };
  }, []);

  return null;
}

/* ── Styles ──────────────────────────────────────────────────── */
const CSS = `
@import url('https://fonts.googleapis.com/css2?family=Rajdhani:wght@600;700&family=Inter:wght@400;500;600&display=swap');

.hp-wrap {
  position: relative;
  z-index: 1;
  min-height: calc(100vh - 56px);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 2rem 1.5rem 3rem;
  box-sizing: border-box;
  background: transparent;
}

/* ── Header ────────── */
.hp-header {
  text-align: center;
  margin-bottom: 2.5rem;
  position: relative;
}

.hp-eyebrow {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  font-family: 'Rajdhani', sans-serif;
  font-size: 0.75rem;
  font-weight: 700;
  letter-spacing: 0.18em;
  text-transform: uppercase;
  color: rgba(255,255,255,0.45);
  margin-bottom: 0.85rem;
}

.hp-title {
  font-family: 'Rajdhani', sans-serif;
  font-size: clamp(2rem, 5vw, 3.4rem);
  font-weight: 700;
  color: #E8EEFF;
  line-height: 1.1;
  margin: 0 0 0.75rem;
  text-shadow: 0 0 40px rgba(0,150,255,0.3);
}

.hp-title span.fire {
  color: #FF8C42;
  text-shadow: 0 0 30px rgba(255,100,0,0.5);
}
.hp-title span.electric {
  color: #00C8FF;
  text-shadow: 0 0 30px rgba(0,200,255,0.5);
}

.hp-subtitle {
  font-family: 'Inter', sans-serif;
  font-size: 1rem;
  color: rgba(255,255,255,0.4);
  margin: 0;
  letter-spacing: 0.02em;
}

/* ── Paths ────────── */
.hp-paths {
  display: flex;
  align-items: stretch;
  gap: 0;
  width: 100%;
  max-width: 1100px;
  min-height: 500px;
}

/* ── Divider ────────── */
.hp-divider {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  width: 60px;
  flex-shrink: 0;
  position: relative;
  z-index: 2;
}

.hp-divider::before {
  content: '';
  position: absolute;
  top: 0; bottom: 0;
  left: 50%;
  width: 1px;
  background: linear-gradient(
    to bottom,
    transparent,
    rgba(255,255,255,0.12) 30%,
    rgba(255,255,255,0.12) 70%,
    transparent
  );
}

.hp-or {
  position: relative;
  width: 36px;
  height: 36px;
  background: rgba(10,12,20,0.9);
  border: 1px solid rgba(255,255,255,0.12);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: 'Rajdhani', sans-serif;
  font-size: 0.7rem;
  font-weight: 700;
  letter-spacing: 0.06em;
  color: rgba(255,255,255,0.35);
  text-transform: uppercase;
}

/* ── Card base ────────── */
.hp-card {
  flex: 1;
  position: relative;
  border-radius: 16px;
  padding: 2.5rem 2rem;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  transition: transform 0.35s cubic-bezier(.22,1,.36,1),
              box-shadow 0.35s ease;
  box-sizing: border-box;
}

.hp-card:hover {
  transform: scale(1.02) translateY(-4px);
}

.hp-card::before {
  content: '';
  position: absolute;
  inset: 0;
  border-radius: 16px;
  pointer-events: none;
  transition: opacity 0.35s ease;
  opacity: 0;
}
.hp-card:hover::before { opacity: 1; }

/* ── Arena card ────────── */
.hp-arena {
  background: rgba(0, 10, 28, 0.82);
  border: 1px solid rgba(0, 200, 255, 0.18);
  box-shadow: 0 0 40px rgba(0,150,255,0.12), inset 0 1px 0 rgba(0,200,255,0.08);
}

.hp-arena::before {
  background: linear-gradient(135deg, rgba(0,200,255,0.06) 0%, transparent 60%);
}

.hp-arena:hover {
  box-shadow: 0 20px 80px rgba(0,150,255,0.25), 0 0 0 1px rgba(0,200,255,0.35),
              inset 0 1px 0 rgba(0,200,255,0.15);
  border-color: rgba(0,200,255,0.4);
}

/* ── Courses card ────────── */
.hp-courses {
  background: rgba(0, 15, 8, 0.82);
  border: 1px solid rgba(34, 197, 94, 0.18);
  box-shadow: 0 0 40px rgba(34,197,94,0.08), inset 0 1px 0 rgba(34,197,94,0.06);
}

.hp-courses::before {
  background: linear-gradient(135deg, rgba(34,197,94,0.05) 0%, transparent 60%);
}

.hp-courses:hover {
  box-shadow: 0 20px 80px rgba(34,197,94,0.18), 0 0 0 1px rgba(34,197,94,0.35),
              inset 0 1px 0 rgba(34,197,94,0.12);
  border-color: rgba(34,197,94,0.4);
}

/* ── Icon area ────────── */
.hp-icon-wrap {
  width: 64px;
  height: 64px;
  border-radius: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 2rem;
  margin-bottom: 1.5rem;
  position: relative;
}

.hp-arena .hp-icon-wrap {
  background: rgba(0,200,255,0.08);
  border: 1px solid rgba(0,200,255,0.2);
  box-shadow: 0 0 24px rgba(0,200,255,0.15);
}

.hp-courses .hp-icon-wrap {
  background: rgba(34,197,94,0.08);
  border: 1px solid rgba(34,197,94,0.2);
  box-shadow: 0 0 24px rgba(34,197,94,0.12);
}

/* Pulse ring on icon */
.hp-icon-wrap::after {
  content: '';
  position: absolute;
  inset: -4px;
  border-radius: 20px;
  opacity: 0;
  transition: opacity 0.3s;
}
.hp-card:hover .hp-icon-wrap::after { opacity: 1; }

.hp-arena .hp-icon-wrap::after {
  border: 1px solid rgba(0,200,255,0.4);
  box-shadow: 0 0 16px rgba(0,200,255,0.2);
}
.hp-courses .hp-icon-wrap::after {
  border: 1px solid rgba(34,197,94,0.4);
  box-shadow: 0 0 16px rgba(34,197,94,0.15);
}

/* ── Badge ────────── */
.hp-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  font-family: 'Rajdhani', sans-serif;
  font-size: 0.65rem;
  font-weight: 700;
  letter-spacing: 0.15em;
  text-transform: uppercase;
  padding: 0.3rem 0.75rem;
  border-radius: 99px;
  margin-bottom: 0.85rem;
  width: fit-content;
}

.hp-arena .hp-badge {
  background: rgba(0,200,255,0.1);
  border: 1px solid rgba(0,200,255,0.25);
  color: #00C8FF;
}

.hp-courses .hp-badge {
  background: rgba(34,197,94,0.1);
  border: 1px solid rgba(34,197,94,0.25);
  color: #22C55E;
}

/* ── Card title ────────── */
.hp-card-title {
  font-family: 'Rajdhani', sans-serif;
  font-size: clamp(1.6rem, 3vw, 2.2rem);
  font-weight: 700;
  line-height: 1;
  letter-spacing: 0.04em;
  margin: 0 0 0.6rem;
  color: #E8EEFF;
}

.hp-arena .hp-card-title { text-shadow: 0 0 30px rgba(0,200,255,0.3); }
.hp-courses .hp-card-title { text-shadow: 0 0 30px rgba(34,197,94,0.2); }

/* ── Challenge line ────────── */
.hp-challenge {
  font-family: 'Inter', sans-serif;
  font-size: 0.9rem;
  font-weight: 600;
  margin: 0 0 0.75rem;
}
.hp-arena .hp-challenge { color: rgba(0,200,255,0.85); }
.hp-courses .hp-challenge { color: rgba(34,197,94,0.85); }

/* ── Body ────────── */
.hp-card-body {
  font-family: 'Inter', sans-serif;
  font-size: 0.88rem;
  line-height: 1.65;
  color: rgba(255,255,255,0.5);
  margin: 0 0 1.5rem;
  flex: 1;
}

/* ── Feature chips ────────── */
.hp-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 0.4rem;
  margin-bottom: 1.75rem;
}

.hp-chip {
  font-family: 'Inter', sans-serif;
  font-size: 0.72rem;
  font-weight: 500;
  padding: 0.28rem 0.7rem;
  border-radius: 6px;
  letter-spacing: 0.02em;
}

.hp-arena .hp-chip {
  background: rgba(0,200,255,0.07);
  border: 1px solid rgba(0,200,255,0.18);
  color: rgba(0,200,255,0.75);
}

.hp-courses .hp-chip {
  background: rgba(34,197,94,0.07);
  border: 1px solid rgba(34,197,94,0.18);
  color: rgba(34,197,94,0.75);
}

/* ── Stats row ────────── */
.hp-stats {
  display: flex;
  gap: 1.25rem;
  margin-bottom: 1.75rem;
}

.hp-stat {
  display: flex;
  flex-direction: column;
}

.hp-stat-num {
  font-family: 'Rajdhani', sans-serif;
  font-size: 1.4rem;
  font-weight: 700;
  line-height: 1;
  color: #E8EEFF;
}

.hp-arena .hp-stat-num { color: #00C8FF; }
.hp-courses .hp-stat-num { color: #22C55E; }

.hp-stat-label {
  font-family: 'Inter', sans-serif;
  font-size: 0.68rem;
  color: rgba(255,255,255,0.35);
  letter-spacing: 0.04em;
  text-transform: uppercase;
  margin-top: 0.15rem;
}

/* ── CTA button ────────── */
.hp-cta {
  width: 100%;
  padding: 0.9rem 1.5rem;
  border: none;
  border-radius: 10px;
  font-family: 'Rajdhani', sans-serif;
  font-size: 1rem;
  font-weight: 700;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  cursor: pointer;
  transition: all 0.25s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  margin-top: auto;
}

.hp-arena .hp-cta {
  background: linear-gradient(135deg, rgba(0,180,255,0.2) 0%, rgba(0,120,220,0.2) 100%);
  border: 1px solid rgba(0,200,255,0.45);
  color: #00C8FF;
  box-shadow: 0 0 20px rgba(0,180,255,0.1), inset 0 1px 0 rgba(0,200,255,0.15);
}

.hp-arena .hp-cta:hover {
  background: linear-gradient(135deg, rgba(0,200,255,0.28) 0%, rgba(0,140,255,0.28) 100%);
  border-color: rgba(0,200,255,0.7);
  box-shadow: 0 0 35px rgba(0,200,255,0.3), inset 0 1px 0 rgba(0,200,255,0.25);
  color: #fff;
  transform: none;
}

.hp-courses .hp-cta {
  background: linear-gradient(135deg, rgba(34,197,94,0.18) 0%, rgba(20,160,70,0.18) 100%);
  border: 1px solid rgba(34,197,94,0.4);
  color: #22C55E;
  box-shadow: 0 0 20px rgba(34,197,94,0.08), inset 0 1px 0 rgba(34,197,94,0.12);
}

.hp-courses .hp-cta:hover {
  background: linear-gradient(135deg, rgba(34,197,94,0.26) 0%, rgba(20,160,70,0.26) 100%);
  border-color: rgba(34,197,94,0.65);
  box-shadow: 0 0 35px rgba(34,197,94,0.22), inset 0 1px 0 rgba(34,197,94,0.2);
  color: #fff;
  transform: none;
}

/* ── Arena FIRST badge ────────── */
.hp-first-badge {
  position: absolute;
  top: -1px;
  right: 1.5rem;
  background: linear-gradient(135deg, #FF6B35 0%, #FF4500 100%);
  color: #fff;
  font-family: 'Rajdhani', sans-serif;
  font-size: 0.62rem;
  font-weight: 700;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  padding: 0.3rem 0.75rem 0.25rem;
  border-radius: 0 0 8px 8px;
  box-shadow: 0 4px 16px rgba(255,100,0,0.4);
}

/* ── Animated electricity indicator ────────── */
.hp-live-dot {
  width: 8px; height: 8px;
  border-radius: 50%;
  display: inline-block;
  margin-right: 0.35rem;
  animation: hp-pulse 1.8s ease-in-out infinite;
}
.hp-arena .hp-live-dot { background: #00C8FF; box-shadow: 0 0 6px #00C8FF; }
.hp-courses .hp-live-dot { background: #22C55E; box-shadow: 0 0 6px #22C55E; }

@keyframes hp-pulse {
  0%, 100% { opacity: 1; transform: scale(1); }
  50% { opacity: 0.4; transform: scale(0.7); }
}

/* ── Mobile ────────── */
@media (max-width: 768px) {
  .hp-paths {
    flex-direction: column;
    gap: 1rem;
    min-height: auto;
  }
  .hp-divider { flex-direction: row; height: 48px; width: 100%; }
  .hp-divider::before {
    top: 50%; bottom: auto;
    left: 0; right: 0;
    width: 100%; height: 1px;
  }
  .hp-or { position: relative; }
  .hp-wrap { padding: 1.5rem 1rem 2rem; justify-content: flex-start; }
  .hp-card { padding: 1.75rem 1.5rem; }
  .hp-header { margin-bottom: 1.5rem; }
  .hp-stats { gap: 1rem; }
}

/* ── Light mode — keep dark glass since canvas is always dark ── */
[data-theme="light"] .hp-arena,
[data-theme="light"] .hp-courses {
  background: rgba(0, 10, 22, 0.86);
}
[data-theme="light"] .hp-wrap {
  background: transparent;
}
`;

/* ── Component ───────────────────────────────────────────────── */
export default function HomePage() {
  const navigate = useNavigate();

  return (
    <>
      <HomeParticles />
      <style>{CSS}</style>

      <div className="hp-wrap">

        {/* ── Header ────────────────────────── */}
        <div className="hp-header">
          <div className="hp-eyebrow">
            <span>⚔️</span>
            CodeGoLive
            <span>⚔️</span>
          </div>
          <h1 className="hp-title">
            <span className="electric">Challenge</span> Yourself.
            <br />
            <span className="fire">Master</span> SAP BTP.
          </h1>
          <p className="hp-subtitle">
            Test your knowledge in the Arena, or build your skills from scratch
          </p>
        </div>

        {/* ── Two paths ─────────────────────── */}
        <div className="hp-paths">

          {/* ARENA ─────────────────────────── */}
          <div
            className="hp-card hp-arena"
            role="button"
            tabIndex={0}
            onClick={() => navigate("/arena")}
            onKeyDown={(e) => e.key === "Enter" && navigate("/arena")}
            aria-label="Enter the Arena"
          >
            <span className="hp-first-badge">🔥 Try First</span>

            <div className="hp-icon-wrap">⚔️</div>

            <div className="hp-badge">
              <span className="hp-live-dot" />
              Challenge Mode
            </div>

            <h2 className="hp-card-title">Enter the Arena</h2>
            <p className="hp-challenge">
              Think you already know SAP BTP? Prove it.
            </p>

            <p className="hp-card-body">
              Jump straight in. Face real developer questions under time pressure.
              No tutorials, no hand-holding — just you versus the clock.
              Discover exactly what you know, and what you don't.
            </p>

            <div className="hp-stats">
              <div className="hp-stat">
                <span className="hp-stat-num">2.8K+</span>
                <span className="hp-stat-label">Battles Fought</span>
              </div>
              <div className="hp-stat">
                <span className="hp-stat-num">12</span>
                <span className="hp-stat-label">Active Now</span>
              </div>
              <div className="hp-stat">
                <span className="hp-stat-num">5</span>
                <span className="hp-stat-label">Rank Tiers</span>
              </div>
            </div>

            <div className="hp-chips">
              {["Live Battles", "Leaderboard", "Daily Quests", "Tournaments", "Trophies"].map((c) => (
                <span className="hp-chip" key={c}>{c}</span>
              ))}
            </div>

            <button className="hp-cta">
              ⚡ Accept the Challenge
              <span>→</span>
            </button>
          </div>

          {/* DIVIDER ───────────────────────── */}
          <div className="hp-divider">
            <span className="hp-or">or</span>
          </div>

          {/* COURSES ────────────────────────── */}
          <div
            className="hp-card hp-courses"
            role="button"
            tabIndex={0}
            onClick={() => navigate("/dashboard")}
            onKeyDown={(e) => e.key === "Enter" && navigate("/dashboard")}
            aria-label="Start learning courses"
          >
            <div className="hp-icon-wrap">📚</div>

            <div className="hp-badge">
              <span className="hp-live-dot" />
              Learning Path
            </div>

            <h2 className="hp-card-title">Master the Skills</h2>
            <p className="hp-challenge">
              Start from zero. Build real expertise.
            </p>

            <p className="hp-card-body">
              Structured courses from absolute beginner to deployed expert.
              SAP BTP architecture, CAP framework, SAPUI5 — every concept
              explained with real code examples you can run immediately.
            </p>

            <div className="hp-stats">
              <div className="hp-stat">
                <span className="hp-stat-num">4</span>
                <span className="hp-stat-label">Courses</span>
              </div>
              <div className="hp-stat">
                <span className="hp-stat-num">120+</span>
                <span className="hp-stat-label">Lessons</span>
              </div>
              <div className="hp-stat">
                <span className="hp-stat-num">∞</span>
                <span className="hp-stat-label">Practice</span>
              </div>
            </div>

            <div className="hp-chips">
              {["SAP BTP", "CAP Framework", "SAPUI5", "Fiori", "Certificates"].map((c) => (
                <span className="hp-chip" key={c}>{c}</span>
              ))}
            </div>

            <button className="hp-cta">
              📖 Begin Your Journey
              <span>→</span>
            </button>
          </div>

        </div>
      </div>
    </>
  );
}
