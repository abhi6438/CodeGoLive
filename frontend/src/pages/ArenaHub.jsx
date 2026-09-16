import { useState, useEffect, useRef } from "react";
import { createPortal } from "react-dom";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../lib/AuthContext";
import { api } from "../lib/api";
import SEO from "../components/SEO";

/* ── THEME CSS — semi-transparent so the battle scene bleeds through ──────── */
const ARENA_THEME_CSS = `
  .arena-page {
    --ah-bg:      rgba(12,18,32,0.68);
    --ah-surf:    rgba(20,29,46,0.76);
    --ah-surf2:   rgba(30,43,66,0.80);
    --ah-text:    #E8EEFF;
    --ah-text2:   #7B8DB0;
    --ah-text3:   #3A4A68;
    --ah-item-bg: rgba(255,255,255,.04);
    --ah-item-bd: rgba(0,200,255,.10);
    --ah-dot:     rgba(58,74,104,.4);
  }
  @media (prefers-color-scheme: light) {
    :root:not([data-theme="dark"]) .arena-page {
      --ah-bg:      rgba(30,45,75,0.72);
      --ah-surf:    rgba(40,58,95,0.78);
      --ah-surf2:   rgba(50,70,110,0.80);
      --ah-text:    #E8EEFF;
      --ah-text2:   #9BB0D0;
      --ah-text3:   #5A7090;
      --ah-item-bg: rgba(255,255,255,.06);
      --ah-item-bd: rgba(0,200,255,.15);
      --ah-dot:     rgba(0,200,255,.15);
    }
  }
  :root[data-theme="light"] .arena-page {
    --ah-bg:      rgba(30,45,75,0.72);
    --ah-surf:    rgba(40,58,95,0.78);
    --ah-surf2:   rgba(50,70,110,0.80);
    --ah-text:    #E8EEFF;
    --ah-text2:   #9BB0D0;
    --ah-text3:   #5A7090;
    --ah-item-bg: rgba(255,255,255,.06);
    --ah-item-bd: rgba(0,200,255,.15);
    --ah-dot:     rgba(0,200,255,.15);
  }
`;

const ORBITRON = `@import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@400;600;700;900&display=swap');`;

const MODES = [
  { to: "/arena/solo",       icon: "🎯",  type: "SOLO",       name: "Solo Practice", desc: "Test yourself against the clock. Pick a topic, answer timed questions, get graded S→D. No signup to test.", ap: "Check your own level", color: "#22C55E", variant: "green"  },
  { to: "/arena/lobby",      icon: "⚔️",  type: "VERSUS",     name: "1v1 Battle",   desc: "Challenge any learner to a real-time quiz duel. First to 10 correct wins.", ap: "Earn up to 200 XP per match", color: "#00C8FF", variant: "accent" },
  { to: "/arena/quests",     icon: "📋",  type: "DAILY",      name: "Quests",        desc: "Complete daily and weekly missions to stack XP and AP bonuses.",           ap: "Up to +500 XP per week",      color: "#FF5722", variant: "fire"   },
  { to: "/arena/trophies",   icon: "🏆",  type: "COLLECTION", name: "Trophies",      desc: "Unlock achievement badges from Common to Legendary rarity.",               ap: "Flex your milestones",         color: "#FFB300", variant: "gold"   },
  { to: "/arena/ranks",      icon: "📊",  type: "GLOBAL",     name: "Leaderboard",   desc: "Climb the global XP rankings. Top players earn special recognition.",      ap: "Top 3 get crowns 👑",          color: "#A855F7", variant: "purple" },
  { to: "/arena/history",    icon: "📜",  type: "STATS",      name: "Match History", desc: "Review your past battles. See win/loss record, scores, and per-match breakdowns.", ap: "Track your progress",  color: "#00C8FF", variant: "cyan"   },
  { to: "/arena/spin",       icon: "🎰",  type: "DAILY",      name: "Spin Wheel",    desc: "1 free spin every 24 hours. Win AP, XP, power-ups, or the jackpot.",      ap: "Jackpot: 1 000 AP",            color: "#FF5722", variant: "fire"   },
  { to: "/arena/season",     icon: "🏆",  type: "SEASON",     name: "Season Ranks",  desc: "Climb AP rank tiers — Bronze to Legend. Resets monthly. XP is permanent.", ap: "Reach Legend to flex 👑",     color: "#FFB300", variant: "gold"   },
  { to: "/arena/tournament", icon: "🏟️", type: "BRACKET",    name: "Tournament",    desc: "4 or 8 players. Single-elimination bracket. One champion crowned.",        ap: "Winner takes the glory",       color: "#A855F7", variant: "purple" },
];

/* ═══════════════════════════════════════════════════════════════════════════
   EPIC BATTLE BACKGROUND
   Inspired by the Godzilla vs Godzilla battle aesthetic:
   - Storm sky with glowing moon
   - Destroyed city ruins left & right
   - Two massive creature silhouettes facing each other up close
   - Blue energy spines (left) vs orange fire (right)
   - Center clash explosion + flying debris
   - Theme-aware: dramatic in both dark and light mode
   ═══════════════════════════════════════════════════════════════════════════ */
function EpicBattleBg() {
  const canvasRef = useRef(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    let raf, t = 0;

    /* ── theme detection ── */
    function isDarkMode() {
      const dt = document.documentElement.getAttribute("data-theme");
      if (dt === "dark")  return true;
      if (dt === "light") return false;
      return window.matchMedia("(prefers-color-scheme: dark)").matches;
    }

    /* ── debris particles ── */
    const NUM_DEBRIS = 160;
    const debris = [];
    function makeDebris() {
      const cx = canvas.width / 2, cy = canvas.height * 0.52;
      const angle = Math.random() * Math.PI * 2;
      const speed = 1.5 + Math.random() * 9;
      return {
        x:  cx + (Math.random() - 0.5) * 200,
        y:  cy + (Math.random() - 0.5) * 120,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed - 3,
        rot: Math.random() * Math.PI * 2,
        rotV: (Math.random() - 0.5) * 0.12,
        w: 3 + Math.random() * 14,
        h: 2 + Math.random() * 8,
        life: Math.random() * 80,
        maxLife: 60 + Math.random() * 80,
        isRock: Math.random() > 0.5,
      };
    }

    /* ── fire sparks ── */
    const NUM_SPARKS = 100;
    const sparks = [];
    function makeSpark() {
      const cx = canvas.width / 2, cy = canvas.height * 0.52;
      const angle = Math.random() * Math.PI * 2;
      const speed = 4 + Math.random() * 13;
      return {
        x: cx + (Math.random() - 0.5) * 120,
        y: cy + (Math.random() - 0.5) * 80,
        vx: Math.cos(angle) * speed * 0.65,
        vy: Math.sin(angle) * speed - 5,
        life: Math.random() * 40,
        maxLife: 30 + Math.random() * 50,
        r: 1 + Math.random() * 4.5,
      };
    }

    function resize() {
      canvas.width  = window.innerWidth;
      canvas.height = window.innerHeight;
      debris.length = 0; sparks.length = 0;
      for (let i = 0; i < NUM_DEBRIS; i++) debris.push(makeDebris());
      for (let i = 0; i < NUM_SPARKS; i++) sparks.push(makeSpark());
    }
    resize();
    window.addEventListener("resize", resize);

    const mo = new MutationObserver(() => {});
    mo.observe(document.documentElement, { attributes: true, attributeFilter: ["data-theme"] });

    /* ── CITY BUILDINGS ────────────────────────────────────────────────── */
    function drawBuildings(W, H, dark) {
      /* Building specs: [x_fraction, width_fraction, height_fraction] */
      const leftBuildings = [
        [0.00, 0.045, 0.52], [0.03, 0.060, 0.68], [0.07, 0.040, 0.38],
        [0.10, 0.055, 0.58], [0.14, 0.035, 0.44], [0.17, 0.050, 0.62],
        [0.20, 0.038, 0.34],
      ];
      const rightBuildings = [
        [0.76, 0.038, 0.36], [0.79, 0.052, 0.60], [0.83, 0.036, 0.40],
        [0.86, 0.058, 0.56], [0.90, 0.042, 0.66], [0.94, 0.055, 0.44],
        [0.97, 0.030, 0.50],
      ];

      [...leftBuildings, ...rightBuildings].forEach(([xf, wf, hf]) => {
        const bX = xf * W;
        const bW = wf * W;
        const bH = hf * H;
        const bY = H - bH;

        /* Building silhouette */
        ctx.fillStyle = dark ? "rgba(6,8,18,0.95)" : "rgba(20,30,50,0.90)";
        ctx.fillRect(bX, bY, bW, bH);

        /* Broken top edge — jagged destruction */
        ctx.fillStyle = dark ? "rgba(6,8,18,0.95)" : "rgba(20,30,50,0.90)";
        const jagW = Math.max(4, bW / 5);
        for (let jx = bX; jx < bX + bW; jx += jagW) {
          const jh = Math.random() * bH * 0.12;
          ctx.clearRect(jx, bY, jagW * 0.4, jh);
        }

        /* Windows — small dots of warm amber/white light */
        ctx.fillStyle = dark ? "rgba(255,200,80,0.45)" : "rgba(255,220,120,0.55)";
        const cols = Math.floor(bW / 7);
        const rows = Math.floor(bH / 12);
        for (let r = 1; r < rows - 1; r++) {
          for (let c = 0; c < cols; c++) {
            if (Math.random() > 0.55) continue;
            /* Some windows glow orange-red (on fire) */
            const onFire = Math.random() > 0.82;
            ctx.fillStyle = onFire
              ? `rgba(255,${80 + Math.floor(Math.random()*80)},0,0.55)`
              : (dark ? "rgba(255,200,80,0.40)" : "rgba(255,220,120,0.50)");
            ctx.fillRect(bX + c * 7 + 1, bY + r * 12 + 2, 3, 4);
          }
        }

        /* Fire glow in lower windows */
        const fg = ctx.createLinearGradient(bX, bY + bH * 0.7, bX, bY + bH);
        fg.addColorStop(0, "rgba(255,80,0,0)");
        fg.addColorStop(1, "rgba(255,60,0,0.22)");
        ctx.fillStyle = fg;
        ctx.fillRect(bX, bY + bH * 0.7, bW, bH * 0.3);
      });
    }

    /* ── GROUND RUBBLE ─────────────────────────────────────────────────── */
    function drawRubble(W, H, dark) {
      ctx.fillStyle = dark ? "rgba(8,10,18,0.92)" : "rgba(20,28,45,0.88)";
      ctx.beginPath();
      ctx.moveTo(0, H);
      /* Jagged rubble line */
      const steps = 24;
      for (let i = 0; i <= steps; i++) {
        const x = (i / steps) * W;
        const baseY = H - H * 0.06;
        const jag = (Math.sin(i * 2.3) * H * 0.025) + (Math.cos(i * 3.7) * H * 0.018);
        ctx.lineTo(x, baseY + jag);
      }
      ctx.lineTo(W, H); ctx.closePath(); ctx.fill();

      /* Rubble chunks scattered on ground */
      for (let i = 0; i < 30; i++) {
        const rx = Math.random() * W;
        const ry = H - Math.random() * H * 0.08;
        const rw = 4 + Math.random() * 22;
        const rh = 3 + Math.random() * 12;
        ctx.fillStyle = dark ? "rgba(10,12,22,0.88)" : "rgba(25,35,55,0.85)";
        ctx.beginPath();
        ctx.ellipse(rx, ry, rw, rh, Math.random() * Math.PI, 0, Math.PI * 2);
        ctx.fill();
      }
    }

    /* ── MOON ──────────────────────────────────────────────────────────── */
    function drawMoon(W, H, dark, pulse) {
      const mx = W * 0.76, my = H * 0.12;
      const mr = H * 0.048;

      /* Outer atmospheric halo */
      const halo = ctx.createRadialGradient(mx, my, mr * 0.5, mx, my, mr * 4.5);
      halo.addColorStop(0,   `rgba(200,225,255,${dark ? 0.18 : 0.22})`);
      halo.addColorStop(0.4, `rgba(150,185,240,${dark ? 0.07 : 0.09})`);
      halo.addColorStop(1,   "rgba(100,140,200,0)");
      ctx.fillStyle = halo;
      ctx.beginPath(); ctx.arc(mx, my, mr * 4.5, 0, Math.PI * 2); ctx.fill();

      /* Moon disc */
      const moonG = ctx.createRadialGradient(mx - mr*0.2, my - mr*0.2, 0, mx, my, mr);
      moonG.addColorStop(0,   `rgba(240,248,255,${dark ? 0.96 : 0.98})`);
      moonG.addColorStop(0.6, `rgba(200,220,250,${dark ? 0.88 : 0.92})`);
      moonG.addColorStop(1,   `rgba(150,180,220,${dark ? 0.80 : 0.85})`);
      ctx.fillStyle = moonG;
      ctx.beginPath(); ctx.arc(mx, my, mr, 0, Math.PI * 2); ctx.fill();

      /* Cloud shadow over moon */
      ctx.fillStyle = dark ? "rgba(8,12,25,0.28)" : "rgba(35,50,80,0.20)";
      ctx.beginPath();
      ctx.ellipse(mx + mr*0.6, my - mr*0.1, mr*0.8, mr*0.4, -0.3, 0, Math.PI*2);
      ctx.fill();
    }

    /* ── STORM CLOUDS ──────────────────────────────────────────────────── */
    function drawClouds(W, H, dark, t) {
      const cloudColor = dark ? "rgba(14,18,32,0.88)" : "rgba(35,50,80,0.82)";
      const cloudColor2 = dark ? "rgba(20,25,42,0.70)" : "rgba(45,62,95,0.68)";

      /* Main cloud masses */
      const clouds = [
        { x: 0.08, y: 0.05, rx: 0.18, ry: 0.08 },
        { x: 0.28, y: 0.02, rx: 0.14, ry: 0.06 },
        { x: 0.45, y: 0.04, rx: 0.16, ry: 0.07 },
        { x: 0.62, y: 0.01, rx: 0.12, ry: 0.05 },
        { x: 0.88, y: 0.03, rx: 0.15, ry: 0.07 },
        { x: 0.05, y: 0.10, rx: 0.12, ry: 0.06 },
        { x: 0.55, y: 0.08, rx: 0.20, ry: 0.09 },
        { x: 0.78, y: 0.09, rx: 0.16, ry: 0.07 },
      ];

      clouds.forEach((c, i) => {
        const drift = Math.sin(t * 0.08 + i) * W * 0.004;
        ctx.fillStyle = i % 2 === 0 ? cloudColor : cloudColor2;
        ctx.beginPath();
        ctx.ellipse(c.x * W + drift, c.y * H, c.rx * W, c.ry * H, 0, 0, Math.PI * 2);
        ctx.fill();
      });

      /* Lightning flash occasionally */
      if (Math.sin(t * 7.3) > 0.96) {
        ctx.fillStyle = "rgba(180,210,255,0.06)";
        ctx.fillRect(0, 0, W, H * 0.3);
      }
    }

    /* ── GORILLA SILHOUETTE ────────────────────────────────────────────── */
    function drawGorilla(x, y, scale, flip, punchT, swayY, dark) {
      /* Lean toward center */
      const leanAngle = flip ? -0.07 : 0.07;

      ctx.save();
      ctx.translate(x, y + swayY);
      if (flip) ctx.scale(-1, 1);
      ctx.rotate(leanAngle);
      ctx.scale(scale, scale);

      /* Shadow on ground */
      ctx.save();
      ctx.scale(1, 0.18);
      const sh = ctx.createRadialGradient(0, 0, 0, 0, 0, 180);
      sh.addColorStop(0,   "rgba(0,0,0,0.55)");
      sh.addColorStop(1,   "rgba(0,0,0,0)");
      ctx.fillStyle = sh;
      ctx.beginPath(); ctx.ellipse(10, 0, 180, 180, 0, 0, Math.PI * 2); ctx.fill();
      ctx.restore();

      /* ── BODY with rim-light ── */
      ctx.shadowBlur  = 70;
      ctx.shadowColor = flip
        ? "rgba(255,85,0,0.92)"      /* right creature — fire orange */
        : "rgba(0,210,255,0.92)";    /* left creature — energy blue  */
      ctx.fillStyle = dark ? "rgba(4,6,14,0.97)" : "rgba(10,15,28,0.95)";

      /* Feet */
      ctx.beginPath(); ctx.ellipse(-32,   0,  50, 17, 0,     0, Math.PI*2); ctx.fill();
      ctx.beginPath(); ctx.ellipse( 46,  -4,  50, 17, 0,     0, Math.PI*2); ctx.fill();
      /* Legs */
      ctx.beginPath(); ctx.ellipse(-28, -72,  40, 78,  0.05, 0, Math.PI*2); ctx.fill();
      ctx.beginPath(); ctx.ellipse( 38, -66,  40, 78, -0.05, 0, Math.PI*2); ctx.fill();
      /* Torso */
      ctx.beginPath(); ctx.ellipse(  0,-188, 112,128, 0,     0, Math.PI*2); ctx.fill();
      /* Shoulders */
      ctx.beginPath(); ctx.ellipse(-122,-260,  66, 49, -0.28, 0, Math.PI*2); ctx.fill();
      ctx.beginPath(); ctx.ellipse( 122,-260,  66, 49,  0.28, 0, Math.PI*2); ctx.fill();
      /* Left arm */
      ctx.beginPath();
      ctx.moveTo(-84,-224);
      ctx.bezierCurveTo(-178,-164,-193,-75,-137, 32);
      ctx.bezierCurveTo(-120,  60,  -74, 56,  -60,  8);
      ctx.bezierCurveTo( -94, -54, -115,-130,  -74,-213);
      ctx.closePath(); ctx.fill();
      ctx.beginPath(); ctx.ellipse(-137, 40, 46, 30, 0.2, 0, Math.PI*2); ctx.fill();
      /* Right arm — punching */
      const aX = 102 + punchT * 192, aY = -228 + punchT * 98;
      ctx.beginPath();
      ctx.moveTo(80,-234);
      ctx.bezierCurveTo(98,-208, aX-97, aY+54, aX, aY);
      ctx.bezierCurveTo(aX+40, aY-32, aX+15, aY-76, aX-60, aY-56);
      ctx.bezierCurveTo(aX-100, aY-24, 99,-204, 80,-255);
      ctx.closePath(); ctx.fill();
      ctx.beginPath(); ctx.ellipse(aX, aY, 50, 40, 0.15, 0, Math.PI*2); ctx.fill();
      /* Neck */
      ctx.beginPath(); ctx.ellipse(  0,-302, 59, 44, 0,     0, Math.PI*2); ctx.fill();
      /* Head */
      ctx.beginPath(); ctx.ellipse(  6,-376, 76, 70, 0,     0, Math.PI*2); ctx.fill();
      /* Crest */
      ctx.beginPath(); ctx.ellipse(  2,-432, 25, 34, 0,     0, Math.PI*2); ctx.fill();
      ctx.beginPath(); ctx.ellipse(  2,-452, 15, 21, 0,     0, Math.PI*2); ctx.fill();
      /* Brow */
      ctx.beginPath(); ctx.ellipse(  5,-358, 76, 24, 0.05,  0, Math.PI*2); ctx.fill();
      /* Muzzle */
      ctx.beginPath(); ctx.ellipse( 51,-350, 44, 34, 0,     0, Math.PI*2); ctx.fill();
      ctx.beginPath(); ctx.ellipse( 68,-332, 27, 19, 0.1,   0, Math.PI*2); ctx.fill();

      /* ── DORSAL SPINES (Godzilla-style, along back) ── */
      /* Back is on the LEFT side (negative x) for the un-flipped gorilla */
      ctx.shadowBlur = 0;
      const spineColor = flip
        ? "rgba(255,90,10,0.88)"   /* orange fire spines */
        : "rgba(0,220,255,0.88)";  /* blue energy spines */
      const spineGlow = flip
        ? "rgba(255,120,0,0.45)"
        : "rgba(0,200,255,0.45)";

      const spinePositions = [
        [-92, -148, 38, 72],   /* lower back */
        [-108,-210, 30, 60],
        [-118,-270, 26, 52],
        [-112,-325, 22, 44],
        [-100,-372, 18, 36],   /* upper back near shoulder */
        [-80, -418, 14, 28],   /* near crest */
      ];

      spinePositions.forEach(([sx, sy, sw, sh2]) => {
        /* Spike triangle */
        ctx.beginPath();
        ctx.moveTo(sx, sy);
        ctx.lineTo(sx - sw, sy + sh2 * 0.5);
        ctx.lineTo(sx - sw * 0.3, sy + sh2);
        ctx.closePath();
        ctx.fillStyle = spineColor;
        ctx.shadowBlur = 22;
        ctx.shadowColor = spineGlow;
        ctx.fill();
        ctx.shadowBlur = 0;
      });

      /* ── OPEN JAW (mouth slightly open, aggressive) ── */
      ctx.fillStyle = dark ? "rgba(80,8,0,0.92)" : "rgba(100,12,0,0.92)";
      ctx.beginPath();
      ctx.ellipse(72, -334, 26, 16, 0.4, 0, Math.PI * 2);
      ctx.fill();
      /* Teeth glint */
      ctx.fillStyle = "rgba(255,245,235,0.80)";
      for (let ti = 0; ti < 5; ti++) {
        ctx.beginPath();
        ctx.moveTo(58 + ti * 7, -326);
        ctx.lineTo(61 + ti * 7, -338);
        ctx.lineTo(64 + ti * 7, -326);
        ctx.closePath();
        ctx.fill();
      }

      /* ── GLOWING EYES ── */
      ctx.restore();
      ctx.save();
      ctx.translate(x, y + swayY);
      if (flip) ctx.scale(-1, 1);
      ctx.rotate(leanAngle);
      ctx.scale(scale, scale);
      ctx.shadowBlur = 0;

      /* Eye halo */
      const eyeColor = flip ? "rgba(255,80,0,1)" : "rgba(0,220,255,1)";
      const eg = ctx.createRadialGradient(-21,-380,0,-21,-380,36);
      eg.addColorStop(0,    eyeColor);
      eg.addColorStop(0.4,  flip ? "rgba(255,50,0,0.55)" : "rgba(0,180,255,0.55)");
      eg.addColorStop(1,    "rgba(0,0,0,0)");
      ctx.fillStyle = eg;
      ctx.beginPath(); ctx.ellipse(-21,-380,36,36,0,0,Math.PI*2); ctx.fill();

      ctx.fillStyle = flip ? "rgba(255,180,0,0.95)" : "rgba(120,240,255,0.95)";
      ctx.beginPath(); ctx.ellipse(-21,-380,14,16,0,0,Math.PI*2); ctx.fill();
      ctx.fillStyle = "rgba(10,0,0,0.95)";
      ctx.beginPath(); ctx.ellipse(-21,-380,5.5,7.5,0,0,Math.PI*2); ctx.fill();

      /* Second eye (slightly offset for creature depth) */
      const eg2 = ctx.createRadialGradient(18,-368,0,18,-368,26);
      eg2.addColorStop(0,   eyeColor);
      eg2.addColorStop(0.4, flip ? "rgba(255,50,0,0.40)" : "rgba(0,180,255,0.40)");
      eg2.addColorStop(1,   "rgba(0,0,0,0)");
      ctx.fillStyle = eg2;
      ctx.beginPath(); ctx.ellipse(18,-368,26,26,0,0,Math.PI*2); ctx.fill();
      ctx.fillStyle = flip ? "rgba(255,180,0,0.85)" : "rgba(120,240,255,0.85)";
      ctx.beginPath(); ctx.ellipse(18,-368,11,13,0,0,Math.PI*2); ctx.fill();
      ctx.fillStyle = "rgba(10,0,0,0.95)";
      ctx.beginPath(); ctx.ellipse(18,-368,4.5,6,0,0,Math.PI*2); ctx.fill();

      /* Energy breath from mouth — blue beam / fire stream */
      if (!flip) {
        /* Left creature: blue energy beam pointing right */
        const beam = ctx.createLinearGradient(80*scale, -340*scale, 260*scale, -330*scale);
        beam.addColorStop(0,   "rgba(0,220,255,0.55)");
        beam.addColorStop(0.5, "rgba(0,180,255,0.25)");
        beam.addColorStop(1,   "rgba(0,150,255,0)");
        ctx.fillStyle = beam;
        ctx.beginPath();
        ctx.ellipse(80, -338, 90, 18, -0.05, 0, Math.PI * 2);
        ctx.fill();
      } else {
        /* Right creature (flipped): fire breath pointing left */
        const fire = ctx.createLinearGradient(80*scale, -340*scale, 260*scale, -330*scale);
        fire.addColorStop(0,   "rgba(255,120,0,0.55)");
        fire.addColorStop(0.5, "rgba(255,80,0,0.25)");
        fire.addColorStop(1,   "rgba(255,40,0,0)");
        ctx.fillStyle = fire;
        ctx.beginPath();
        ctx.ellipse(80, -338, 90, 18, -0.05, 0, Math.PI * 2);
        ctx.fill();
      }

      ctx.restore();
    }

    /* ── WATER / SEA in background ─────────────────────────────────────── */
    function drawWater(W, H, dark) {
      const wy = H * 0.62;
      const wg = ctx.createLinearGradient(0, wy, 0, wy + H * 0.08);
      wg.addColorStop(0, dark ? "rgba(5,15,40,0.72)" : "rgba(20,40,80,0.65)");
      wg.addColorStop(1, dark ? "rgba(3,10,28,0.45)" : "rgba(15,30,60,0.45)");
      ctx.fillStyle = wg;
      ctx.fillRect(0, wy, W, H * 0.08);

      /* Wave ripples */
      ctx.strokeStyle = dark ? "rgba(30,80,160,0.25)" : "rgba(50,100,200,0.22)";
      ctx.lineWidth = 1.5;
      for (let i = 0; i < 6; i++) {
        ctx.beginPath();
        ctx.moveTo(0, wy + i * 10);
        ctx.bezierCurveTo(W*0.25, wy + i*10 - 4, W*0.75, wy + i*10 + 4, W, wy + i*10);
        ctx.stroke();
      }
    }

    /* ── MAIN RENDER LOOP ──────────────────────────────────────────────── */
    function frame() {
      t += 0.012;
      const W = canvas.width, H = canvas.height;
      const dark = isDarkMode();
      ctx.clearRect(0, 0, W, H);

      /* ── SKY ── */
      if (dark) {
        const sky = ctx.createLinearGradient(0, 0, 0, H);
        sky.addColorStop(0,    "rgba(2,3,14,1)");
        sky.addColorStop(0.22, "rgba(5,6,20,1)");
        sky.addColorStop(0.45, "rgba(10,5,3,1)");
        sky.addColorStop(0.7,  "rgba(18,8,2,1)");
        sky.addColorStop(1,    "rgba(8,3,1,1)");
        ctx.fillStyle = sky; ctx.fillRect(0, 0, W, H);
      } else {
        /* Light mode: stormy afternoon sky — still dramatic */
        const sky = ctx.createLinearGradient(0, 0, 0, H);
        sky.addColorStop(0,    "rgba(18,28,55,1)");
        sky.addColorStop(0.25, "rgba(28,42,78,1)");
        sky.addColorStop(0.5,  "rgba(38,35,40,1)");
        sky.addColorStop(0.75, "rgba(55,30,12,1)");
        sky.addColorStop(1,    "rgba(20,10,4,1)");
        ctx.fillStyle = sky; ctx.fillRect(0, 0, W, H);
      }

      /* ── MOON ── */
      drawMoon(W, H, dark, Math.sin(t * 0.5));

      /* ── STORM CLOUDS ── */
      drawClouds(W, H, dark, t);

      /* ── CITY RUINS (behind creatures) ── */
      drawBuildings(W, H, dark);

      /* ── WATER ── */
      drawWater(W, H, dark);

      /* ── CENTRAL BATTLE GLOW ── */
      const cx = W / 2, cy = H * 0.5;
      const p1 = 0.5 + 0.5 * Math.sin(t * 3.8);
      const p2 = 0.5 + 0.5 * Math.cos(t * 2.6);

      /* Outer battle aura */
      const aura = ctx.createRadialGradient(cx, cy, 0, cx, cy, W * 0.46 + p1 * 70);
      aura.addColorStop(0,    `rgba(255,145,0,${0.32 + p1 * 0.16})`);
      aura.addColorStop(0.28, `rgba(200,45,0,${0.16 + p1 * 0.08})`);
      aura.addColorStop(0.6,  "rgba(130,12,0,0.04)");
      aura.addColorStop(1,    "rgba(0,0,0,0)");
      ctx.fillStyle = aura; ctx.fillRect(0, 0, W, H);

      /* Blue-vs-orange split energy at clash point */
      const blueG = ctx.createRadialGradient(cx - W*0.05, cy, 0, cx - W*0.05, cy, W * 0.22);
      blueG.addColorStop(0,   `rgba(0,200,255,${0.20 + p2 * 0.10})`);
      blueG.addColorStop(0.5, "rgba(0,150,255,0.05)");
      blueG.addColorStop(1,   "rgba(0,100,200,0)");
      ctx.fillStyle = blueG; ctx.fillRect(0, 0, W, H);

      const fireG = ctx.createRadialGradient(cx + W*0.05, cy, 0, cx + W*0.05, cy, W * 0.22);
      fireG.addColorStop(0,   `rgba(255,100,0,${0.20 + p1 * 0.10})`);
      fireG.addColorStop(0.5, "rgba(255,60,0,0.05)");
      fireG.addColorStop(1,   "rgba(200,20,0,0)");
      ctx.fillStyle = fireG; ctx.fillRect(0, 0, W, H);

      /* Center clash flash — white hot impact */
      const flash = ctx.createRadialGradient(cx, cy, 0, cx, cy, 100 + p2 * 45);
      flash.addColorStop(0,    `rgba(255,255,230,${0.78 + p1 * 0.20})`);
      flash.addColorStop(0.22, `rgba(255,180,0,${0.55 + p1 * 0.15})`);
      flash.addColorStop(0.55, "rgba(255,60,0,0.18)");
      flash.addColorStop(1,    "rgba(255,0,0,0)");
      ctx.fillStyle = flash;
      ctx.beginPath(); ctx.arc(cx, cy, 100 + p2 * 45, 0, Math.PI * 2); ctx.fill();

      /* ── GORILLAS — closer together, leaning in ── */
      /* scale = H/452 fills full screen height exactly */
      const gScale = H / 452;
      const gY = H;
      /* Closer to center vs before: 28% and 72% */
      const lPunch = Math.max(0, Math.sin(t * 1.55)) * 0.95;
      const rPunch = Math.max(0, Math.sin(t * 1.55 + Math.PI)) * 0.95;
      const lBob   = Math.sin(t * 1.55) * 12;
      const rBob   = Math.sin(t * 1.55 + Math.PI) * 12;

      drawGorilla(W * 0.28, gY, gScale, false, lPunch, lBob, dark);
      drawGorilla(W * 0.72, gY, gScale, true,  rPunch, rBob, dark);

      /* ── DEBRIS ── */
      debris.forEach(d => {
        d.life++; d.x += d.vx; d.y += d.vy; d.vy += 0.18; d.rot += d.rotV;
        if (d.life >= d.maxLife) Object.assign(d, makeDebris());
        const a = Math.pow(Math.max(0, 1 - d.life / d.maxLife), 0.6);
        ctx.save();
        ctx.translate(d.x, d.y); ctx.rotate(d.rot);
        ctx.fillStyle = d.isRock
          ? `rgba(45,50,65,${a * 0.85})`
          : `rgba(80,60,30,${a * 0.75})`;
        ctx.fillRect(-d.w/2, -d.h/2, d.w, d.h);
        ctx.restore();
      });

      /* ── FIRE SPARKS ── */
      sparks.forEach(sp => {
        sp.life++; sp.x += sp.vx; sp.y += sp.vy; sp.vy += 0.28; sp.vx *= 0.994;
        if (sp.life >= sp.maxLife) Object.assign(sp, makeSpark());
        const a = Math.pow(Math.max(0, 1 - sp.life / sp.maxLife), 0.52);
        const sg = ctx.createRadialGradient(sp.x, sp.y, 0, sp.x, sp.y, sp.r * 3.2);
        sg.addColorStop(0,    `rgba(255,242,130,${a})`);
        sg.addColorStop(0.45, `rgba(255,100,0,${a * 0.55})`);
        sg.addColorStop(1,    "rgba(255,25,0,0)");
        ctx.fillStyle = sg;
        ctx.beginPath(); ctx.arc(sp.x, sp.y, sp.r * 3.2, 0, Math.PI * 2); ctx.fill();
      });

      /* ── GROUND RUBBLE (drawn after creatures so it layers correctly) ── */
      drawRubble(W, H, dark);

      /* ── EDGE DARKNESS ── */
      const lf = ctx.createLinearGradient(0, 0, W * 0.08, 0);
      lf.addColorStop(0, "rgba(2,3,14,0.82)"); lf.addColorStop(1, "rgba(0,0,0,0)");
      ctx.fillStyle = lf; ctx.fillRect(0, 0, W * 0.08, H);
      const rf = ctx.createLinearGradient(W * 0.92, 0, W, 0);
      rf.addColorStop(0, "rgba(0,0,0,0)"); rf.addColorStop(1, "rgba(2,3,14,0.82)");
      ctx.fillStyle = rf; ctx.fillRect(W * 0.92, 0, W * 0.08, H);

      /* ── VIGNETTE ── */
      const vig = ctx.createRadialGradient(W/2, H/2, H * 0.10, W/2, H/2, H * 0.88);
      vig.addColorStop(0, "rgba(0,0,0,0)"); vig.addColorStop(1, "rgba(0,0,0,0.48)");
      ctx.fillStyle = vig; ctx.fillRect(0, 0, W, H);

      raf = requestAnimationFrame(frame);
    }

    frame();

    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener("resize", resize);
      mo.disconnect();
    };
  }, []);

  return createPortal(
    <canvas
      ref={canvasRef}
      style={{ position: "fixed", inset: 0, width: "100%", height: "100%", zIndex: 0, pointerEvents: "none" }}
      aria-hidden="true"
    />,
    document.body
  );
}

/* ── HELPERS ─────────────────────────────────────────────────────────────── */
function streakMultLabel(mult) {
  if (mult >= 2.0) return { label: "×2.0 🔥", color: "#FF5722" };
  if (mult >= 1.5) return { label: "×1.5 🔥", color: "#FF8C00" };
  if (mult >= 1.2) return { label: "×1.2 🔥", color: "#FFB300" };
  return null;
}

/* ── MAIN COMPONENT ──────────────────────────────────────────────────────── */
export default function ArenaHub() {
  const { session } = useAuth();
  const navigate    = useNavigate();
  const [stats, setStats] = useState(null);
  const [hover, setHover]  = useState(null);

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
    accent: { border:"rgba(0,200,255,.25)",  bg:"rgba(0,200,255,.07)",  glow:"rgba(0,200,255,.18)",  btnBg:"rgba(0,200,255,.1)",  btnColor:"#00C8FF", btnBorder:"rgba(0,200,255,.3)"  },
    fire:   { border:"rgba(255,87,34,.25)",  bg:"rgba(255,87,34,.07)",  glow:"rgba(255,87,34,.18)",  btnBg:"rgba(255,87,34,.1)",  btnColor:"#FF5722", btnBorder:"rgba(255,87,34,.3)"  },
    gold:   { border:"rgba(255,179,0,.25)",  bg:"rgba(255,179,0,.07)",  glow:"rgba(255,179,0,.18)",  btnBg:"rgba(255,179,0,.1)",  btnColor:"#FFB300", btnBorder:"rgba(255,179,0,.3)"  },
    purple: { border:"rgba(168,85,247,.25)", bg:"rgba(168,85,247,.07)", glow:"rgba(168,85,247,.18)", btnBg:"rgba(168,85,247,.1)", btnColor:"#A855F7", btnBorder:"rgba(168,85,247,.3)" },
    cyan:   { border:"rgba(0,200,255,.25)",  bg:"rgba(0,200,255,.07)",  glow:"rgba(0,200,255,.18)",  btnBg:"rgba(0,200,255,.1)",  btnColor:"#00C8FF", btnBorder:"rgba(0,200,255,.3)"  },
    green:  { border:"rgba(34,197,94,.25)",  bg:"rgba(34,197,94,.07)",  glow:"rgba(34,197,94,.18)",  btnBg:"rgba(34,197,94,.1)",  btnColor:"#22C55E", btnBorder:"rgba(34,197,94,.3)"  },
  };

  return (
    <>
      <SEO title="Developer Arena" description="The CodeGoLive Arena hub — battles, quests, tournaments and ranks." robots="noindex, nofollow" />

      {/* Full-screen epic battle — z-index 0, behind everything */}
      <EpicBattleBg />

      {/* Content floats above at z-index 1; glass panels let battle scene bleed through */}
      <div
        className="arena-page"
        style={{ maxWidth: 1400, margin: "0 auto", padding: "1.75rem 2.5rem 3rem", position: "relative", zIndex: 1, width: "100%", boxSizing: "border-box" }}
      >
        <style>{ARENA_THEME_CSS}{ORBITRON}{`
          .arena-mode-card { transition: transform .15s, box-shadow .15s !important; }
          .arena-mode-card:hover { transform: translateY(-3px) !important; }
        `}</style>

        {/* ── HERO STATS HEADER ── */}
        <div style={{ background:"linear-gradient(135deg, var(--ah-bg) 0%, var(--ah-surf) 100%)", border:"1px solid rgba(0,200,255,.22)", borderRadius:8, padding:"1.5rem 1.75rem", marginBottom:"1.5rem", position:"relative", overflow:"hidden", backdropFilter:"blur(8px)", WebkitBackdropFilter:"blur(8px)" }}>
          <div style={{ position:"absolute", inset:0, pointerEvents:"none", background:"radial-gradient(ellipse 60% 40% at 50% 0%, rgba(0,200,255,.07) 0%, transparent 70%)" }} />
          <div style={{ display:"flex", alignItems:"center", gap:"1rem", flexWrap:"wrap", marginBottom:"1.25rem" }}>
            <div style={{ width:48, height:48, borderRadius:6, background:"rgba(0,200,255,.14)", border:"1px solid rgba(0,200,255,.35)", display:"flex", alignItems:"center", justifyContent:"center", fontSize:"1.5rem", flexShrink:0 }}>⚔️</div>
            <div>
              <h1 style={{ fontFamily:"'Orbitron', sans-serif", fontSize:"clamp(1.2rem,3vw,1.7rem)", fontWeight:700, letterSpacing:".04em", color:"var(--ah-text)", margin:0 }}>Developer Arena</h1>
              <p style={{ margin:".2rem 0 0", fontSize:".82rem", color:"var(--ah-text2)" }}>Challenge learners · Climb ranks · Earn rewards</p>
            </div>
            <div style={{ marginLeft:"auto", display:"flex", alignItems:"center", gap:".5rem", background:"rgba(0,200,255,.09)", border:"1px solid rgba(0,200,255,.32)", borderRadius:6, padding:".4rem .9rem" }}>
              <span style={{ fontFamily:"'Orbitron', sans-serif", fontSize:".6rem", color:"var(--ah-text2)", letterSpacing:".1em" }}>LVL</span>
              <span style={{ fontFamily:"'Orbitron', sans-serif", fontSize:"1.05rem", fontWeight:900, color:"#00C8FF" }}>{level}</span>
              {multInfo && <span style={{ fontFamily:"'Orbitron', sans-serif", fontSize:".6rem", fontWeight:700, color:multInfo.color, marginLeft:".2rem", background:"rgba(255,255,255,.07)", borderRadius:3, padding:".15rem .4rem" }}>{multInfo.label}</span>}
            </div>
          </div>
          <div style={{ marginBottom:"1rem" }}>
            <div style={{ display:"flex", justifyContent:"space-between", fontSize:".68rem", color:"var(--ah-text2)", marginBottom:4, fontFamily:"'Orbitron', sans-serif", letterSpacing:".06em" }}>
              <span>LEVEL {level} → {level + 1}</span>
              <span style={{ color:"#00C8FF" }}>{xpInLvl.toLocaleString()} / {xpForNext.toLocaleString()} XP</span>
            </div>
            <div style={{ height:6, background:"var(--ah-surf2)", borderRadius:3, overflow:"hidden" }}>
              <div style={{ height:"100%", width:`${lvlPct}%`, background:"linear-gradient(90deg, #00C8FF, #006FFF)", borderRadius:3, boxShadow:"0 0 8px rgba(0,200,255,.4)", transition:"width .6s" }} />
            </div>
            {actStreak >= 3 && <div style={{ marginTop:4, fontSize:".62rem", color:"#FFB300", fontFamily:"'Orbitron', sans-serif", letterSpacing:".06em" }}>🔥 {actStreak}-DAY STREAK — {multInfo ? multInfo.label + " XP bonus active" : "keep it up!"}</div>}
          </div>
          <div style={{ display:"flex", gap:".6rem", flexWrap:"wrap" }}>
            {[
              { icon:"⚡", label:"Arena XP",  val: stats?.xp?.toLocaleString()  || "—", color:"#00C8FF", bg:"rgba(0,200,255,.07)",  bd:"rgba(0,200,255,.2)"  },
              { icon:"💎", label:"AP",         val: stats?.ap?.toLocaleString()  || "—", color:"#FFB300", bg:"rgba(255,179,0,.07)",  bd:"rgba(255,179,0,.2)"  },
              { icon:"🏆", label:"Wins",       val: stats?.wins                  || "—", color:"#00E676", bg:"rgba(0,230,118,.07)",  bd:"rgba(0,230,118,.2)"  },
              { icon:"🔥", label:"Day Streak", val: actStreak ? `${actStreak}d` : "—",  color:"#FF5722", bg:"rgba(255,87,34,.07)",  bd:"rgba(255,87,34,.2)"  },
              { icon:"⚔️", label:"Matches",    val: stats?.matches_played        || "—", color:"#A855F7", bg:"rgba(168,85,247,.07)", bd:"rgba(168,85,247,.2)" },
            ].map(s => (
              <div key={s.label} style={{ background:s.bg, border:`1px solid ${s.bd}`, borderRadius:4, padding:".35rem .8rem", display:"flex", alignItems:"center", gap:".4rem" }}>
                <span style={{ fontSize:".8rem" }}>{s.icon}</span>
                <span style={{ fontSize:".68rem", color:"var(--ah-text2)" }}>{s.label}</span>
                <span style={{ fontFamily:"'Orbitron', monospace", fontSize:".75rem", fontWeight:700, color:s.color }}>{s.val}</span>
              </div>
            ))}
            {!session && <Link to="/login" style={{ marginLeft:"auto", fontSize:".78rem", fontWeight:600, color:"#00C8FF", textDecoration:"none", alignSelf:"center" }}>Sign in to track stats →</Link>}
          </div>
        </div>

        {/* ── DAILY CHALLENGE BANNER ── */}
        <div onClick={() => navigate("/arena/lobby")} style={{ background:"linear-gradient(135deg, var(--ah-surf), var(--ah-surf2))", border:"1px solid rgba(0,200,255,.3)", borderRadius:6, padding:"1rem 1.25rem", display:"flex", alignItems:"center", gap:"1rem", marginBottom:"1.25rem", cursor:"pointer", transition:"box-shadow .2s", backdropFilter:"blur(5px)", WebkitBackdropFilter:"blur(5px)" }} onMouseEnter={e=>e.currentTarget.style.boxShadow="0 0 24px rgba(0,200,255,.22)"} onMouseLeave={e=>e.currentTarget.style.boxShadow="none"}>
          <div style={{ fontSize:"1.6rem", flexShrink:0 }}>⚡</div>
          <div style={{ flex:1 }}>
            <div style={{ fontFamily:"'Orbitron', sans-serif", fontSize:".72rem", fontWeight:700, color:"var(--ah-text)", marginBottom:2 }}>DAILY BATTLE</div>
            <div style={{ fontSize:".75rem", color:"var(--ah-text2)" }}>Jump into a live 1v1 match — new opponents every day</div>
          </div>
          <button style={{ fontFamily:"'Orbitron', sans-serif", fontSize:".62rem", fontWeight:700, letterSpacing:".08em", padding:"8px 16px", background:"#00C8FF", color:"#070B16", border:"none", borderRadius:4, cursor:"pointer", whiteSpace:"nowrap" }}>BATTLE NOW</button>
        </div>

        {/* ── MODE CARDS ── */}
        <div style={{ display:"grid", gridTemplateColumns:"repeat(auto-fill, minmax(230px, 1fr))", gap:".9rem", marginBottom:"1.75rem" }}>
          {MODES.map((m, i) => {
            const v = variantColors[m.variant];
            const isHover = hover === i;
            return (
              <Link key={m.to} to={m.to} className="arena-mode-card" onMouseEnter={() => setHover(i)} onMouseLeave={() => setHover(null)} style={{ textDecoration:"none", background:isHover?"var(--ah-surf)":"var(--ah-bg)", border:`1px solid ${v.border}`, borderLeft:`3px solid ${m.color}`, borderRadius:4, padding:"1.2rem", display:"flex", flexDirection:"column", gap:".6rem", boxShadow:isHover?`0 8px 28px rgba(0,0,0,.4), 0 0 0 1px ${v.glow}`:"none", position:"relative", overflow:"hidden", backdropFilter:"blur(5px)", WebkitBackdropFilter:"blur(5px)" }}>
                {isHover && <div style={{ position:"absolute", inset:0, background:`radial-gradient(ellipse at top left, ${v.bg} 0%, transparent 65%)`, pointerEvents:"none" }} />}
                <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between" }}>
                  <span style={{ fontSize:"1.4rem" }}>{m.icon}</span>
                  <span style={{ fontFamily:"'Orbitron', monospace", fontSize:".52rem", letterSpacing:".12em", color:"var(--ah-text3)", textTransform:"uppercase" }}>{m.type}</span>
                </div>
                <div>
                  <div style={{ fontFamily:"'Orbitron', sans-serif", fontSize:".85rem", fontWeight:700, color:"var(--ah-text)", marginBottom:".25rem" }}>{m.name}</div>
                  <div style={{ fontSize:".74rem", color:"var(--ah-text2)", lineHeight:1.5 }}>{m.desc}</div>
                </div>
                <div style={{ fontSize:".68rem", color:m.color, marginTop:"auto" }}>{m.ap}</div>
                <div style={{ fontFamily:"'Orbitron', sans-serif", fontSize:".6rem", fontWeight:700, letterSpacing:".08em", padding:"7px", background:v.btnBg, border:`1px solid ${v.btnBorder}`, color:v.btnColor, borderRadius:3, textAlign:"center" }}>ENTER →</div>
              </Link>
            );
          })}
        </div>

        {/* ── HOW IT WORKS ── */}
        <div style={{ background:"var(--ah-bg)", border:"1px solid rgba(0,200,255,.12)", borderRadius:6, padding:"1.25rem 1.4rem", backdropFilter:"blur(5px)", WebkitBackdropFilter:"blur(5px)" }}>
          <div style={{ fontFamily:"'Orbitron', sans-serif", fontSize:".6rem", fontWeight:700, letterSpacing:".16em", textTransform:"uppercase", color:"#00C8FF", marginBottom:"1rem" }}>HOW ARENA WORKS</div>
          <div style={{ display:"grid", gridTemplateColumns:"repeat(auto-fill, minmax(175px, 1fr))", gap:".5rem" }}>
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
              <div key={title} style={{ display:"flex", gap:".5rem", alignItems:"flex-start", padding:".5rem .6rem", background:"var(--ah-item-bg)", borderRadius:4, border:"1px solid var(--ah-item-bd)" }}>
                <span style={{ fontSize:".95rem", flexShrink:0, marginTop:".05rem" }}>{icon}</span>
                <div>
                  <div style={{ fontSize:".76rem", fontWeight:600, color:"var(--ah-text)" }}>{title}</div>
                  <div style={{ fontSize:".69rem", color:"var(--ah-text2)", marginTop:".1rem", lineHeight:1.4 }}>{desc}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </>
  );
}
