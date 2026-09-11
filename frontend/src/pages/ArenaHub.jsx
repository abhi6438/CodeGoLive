import { useState, useEffect } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../lib/AuthContext";
import { api } from "../lib/api";
import SEO from "../components/SEO";

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
          <SEO title="Developer Arena" description="The CodeGoLive Arena hub — battles, quests, tournaments and ranks." robots="noindex, nofollow" />
      <div style={{ maxWidth: 1400, margin: "0 auto", padding: "1.75rem 2.5rem 3rem", position: "relative", width: "100%", boxSizing: "border-box" }}>
      <style>{ORBITRON}{`
        .arena-hub-bg::before {
          content: '';
          position: fixed; inset: 0; pointer-events: none; z-index: 0;
          background-image: radial-gradient(circle, rgba(58,74,104,.4) 1px, transparent 1px);
          background-size: 32px 32px;
        }
        .arena-mode-card { transition: transform .15s, box-shadow .15s !important; }
        .arena-mode-card:hover { transform: translateY(-3px) !important; }
      `}</style>

      {/* ── HERO STATS HEADER ── */}
      <div style={{
        background: "linear-gradient(135deg, #0C1220 0%, #141D2E 100%)",
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
            <h1 style={{ fontFamily: "'Orbitron', sans-serif", fontSize: "clamp(1.2rem,3vw,1.7rem)", fontWeight: 700, letterSpacing: ".04em", color: "#E8EEFF", margin: 0 }}>Developer Arena</h1>
            <p style={{ margin: ".2rem 0 0", fontSize: ".82rem", color: "#7B8DB0" }}>Challenge learners · Climb ranks · Earn rewards</p>
          </div>
          {/* Level badge */}
          <div style={{ marginLeft: "auto", display: "flex", alignItems: "center", gap: ".5rem", background: "rgba(0,200,255,.08)", border: "1px solid rgba(0,200,255,.3)", borderRadius: 6, padding: ".4rem .9rem" }}>
            <span style={{ fontFamily: "'Orbitron', sans-serif", fontSize: ".6rem", color: "#7B8DB0", letterSpacing: ".1em" }}>LVL</span>
            <span style={{ fontFamily: "'Orbitron', sans-serif", fontSize: "1.05rem", fontWeight: 900, color: "#00C8FF" }}>{level}</span>
            {multInfo && (
              <span style={{ fontFamily: "'Orbitron', sans-serif", fontSize: ".6rem", fontWeight: 700, color: multInfo.color, marginLeft: ".2rem", background: "rgba(255,255,255,.06)", borderRadius: 3, padding: ".15rem .4rem" }}>{multInfo.label}</span>
            )}
          </div>
        </div>

        {/* Level XP progress bar */}
        <div style={{ marginBottom: "1rem" }}>
          <div style={{ display: "flex", justifyContent: "space-between", fontSize: ".68rem", color: "#7B8DB0", marginBottom: 4, fontFamily: "'Orbitron', sans-serif", letterSpacing: ".06em" }}>
            <span>LEVEL {level} → {level + 1}</span>
            <span style={{ color: "#00C8FF" }}>{xpInLvl.toLocaleString()} / {xpForNext.toLocaleString()} XP</span>
          </div>
          <div style={{ height: 6, background: "#1E2B42", borderRadius: 3, overflow: "hidden" }}>
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
              <span style={{ fontSize: ".68rem", color: "#7B8DB0" }}>{s.label}</span>
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
          background: "linear-gradient(135deg, #141D2E, #1E2B42)",
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
          <div style={{ fontFamily: "'Orbitron', sans-serif", fontSize: ".72rem", fontWeight: 700, color: "#E8EEFF", marginBottom: 2 }}>DAILY BATTLE</div>
          <div style={{ fontSize: ".75rem", color: "#7B8DB0" }}>Jump into a live 1v1 match — new opponents every day</div>
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
                background: isHover ? "#141D2E" : "#0C1220",
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
                <span style={{ fontFamily: "'Orbitron', monospace", fontSize: ".52rem", letterSpacing: ".12em", color: "#3A4A68", textTransform: "uppercase" }}>{m.type}</span>
              </div>
              <div>
                <div style={{ fontFamily: "'Orbitron', sans-serif", fontSize: ".85rem", fontWeight: 700, color: "#E8EEFF", marginBottom: ".25rem" }}>{m.name}</div>
                <div style={{ fontSize: ".74rem", color: "#7B8DB0", lineHeight: 1.5 }}>{m.desc}</div>
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
      <div style={{ background: "#0C1220", border: "1px solid rgba(0,200,255,.1)", borderRadius: 6, padding: "1.25rem 1.4rem" }}>
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
            <div key={title} style={{ display: "flex", gap: ".5rem", alignItems: "flex-start", padding: ".5rem .6rem", background: "rgba(255,255,255,.02)", borderRadius: 4, border: "1px solid rgba(0,200,255,.07)" }}>
              <span style={{ fontSize: ".95rem", flexShrink: 0, marginTop: ".05rem" }}>{icon}</span>
              <div>
                <div style={{ fontSize: ".76rem", fontWeight: 600, color: "#E8EEFF" }}>{title}</div>
                <div style={{ fontSize: ".69rem", color: "#7B8DB0", marginTop: ".1rem", lineHeight: 1.4 }}>{desc}</div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
