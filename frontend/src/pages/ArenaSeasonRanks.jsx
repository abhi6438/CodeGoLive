import { useState, useEffect } from 'react';
import { useAuth } from '../lib/AuthContext';
import { api } from '../lib/api';
import { Link } from 'react-router-dom';
import SEO from "../components/SEO";

const ORBITRON = `@import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@400;600;700;900&display=swap');`;

const BG       = "#070B16";
const CARD     = "#0C1220";
const CARD2    = "#141D2E";
const BORDER   = "rgba(0,200,255,.13)";
const TEXT     = "#E8EEFF";
const MUTED    = "#7B8DB0";
const CYAN     = "#00C8FF";

// Order tiers high → low for display
const TIER_ORDER = ["legend","diamond","platinum","gold","silver","bronze","unranked"];

function getInitials(name) {
  if (!name) return '?';
  return name.split(' ').map(w => w[0]).join('').toUpperCase().slice(0, 2);
}

function ProgressBar({ pct, color, height = 8 }) {
  return (
    <div style={{ width:"100%", height, background:"rgba(255,255,255,.07)", borderRadius:99, overflow:"hidden" }}>
      <div style={{
        height:"100%", width:`${pct}%`,
        background: `linear-gradient(90deg, ${color}99, ${color})`,
        borderRadius: 99,
        transition: "width .6s cubic-bezier(.4,0,.2,1)",
        boxShadow: `0 0 8px ${color}66`,
      }} />
    </div>
  );
}

function TierBadge({ icon, label, color, size = "lg" }) {
  const isLg = size === "lg";
  return (
    <div style={{
      display: "inline-flex", flexDirection: "column", alignItems: "center",
      gap: isLg ? 6 : 3,
    }}>
      <div style={{
        fontSize: isLg ? "3.5rem" : "1.6rem",
        lineHeight: 1,
        filter: `drop-shadow(0 0 12px ${color}88)`,
      }}>{icon}</div>
      <div style={{
        fontFamily: "'Orbitron',sans-serif",
        fontSize: isLg ? ".7rem" : ".55rem",
        fontWeight: 700,
        letterSpacing: ".15em",
        color,
        textShadow: `0 0 10px ${color}55`,
      }}>{label.toUpperCase()}</div>
    </div>
  );
}

export default function ArenaSeasonRanks() {
  const { session } = useAuth();
  const user = session?.user;
  const [data, setData]     = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError]   = useState(null);

  useEffect(() => {
    api.get('/api/arena/season')
      .then(d => { setData(d); setLoading(false); })
      .catch(() => { setError('Failed to load season data.'); setLoading(false); });
  }, []);

  if (loading) return (
    <div style={{ display:"flex",alignItems:"center",justifyContent:"center",minHeight:"60vh",background:BG }}>
      <div style={{ fontFamily:"'Orbitron',sans-serif",color:CYAN,fontSize:".8rem",letterSpacing:".1em" }}>LOADING SEASON…</div>
    </div>
  );
  if (error) return (
    <div style={{ maxWidth:800,margin:"2rem auto",padding:"1rem",color:"#FF5722" }}>{error}</div>
  );

  const { season, my_rank: my, tier_distribution: dist, top_players, all_tiers } = data;
  const orderedTiers = [...all_tiers].sort((a,b) => b.min_ap - a.min_ap);

  return (
    <>
      <SEO title="Season Ranks" description="Your AP rank tier and season progress on CodeGoLive Arena." robots="noindex, nofollow" />
      <div style={{ maxWidth:1100,margin:"0 auto",padding:"1.75rem 1.5rem 4rem",width:"100%",boxSizing:"border-box",background:BG,minHeight:"100vh" }}>
      <style>{ORBITRON}</style>

      {/* Header */}
      <div style={{ marginBottom:"1.5rem" }}>
        <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".58rem",letterSpacing:".2em",color:CYAN,marginBottom:4 }}>ARENA · RANKED</div>
        <h1 style={{ fontFamily:"'Orbitron',sans-serif",fontSize:"clamp(1.2rem,3vw,1.8rem)",fontWeight:900,margin:0,color:TEXT }}>
          🏆 {season.name}
        </h1>
        <p style={{ color:MUTED,margin:".3rem 0 0",fontSize:".82rem" }}>
          Season ends in <span style={{ color:"#FFB300",fontWeight:600 }}>{season.days_remaining} days</span>
        </p>
      </div>

      {/* My rank hero */}
      <div style={{
        background: `linear-gradient(135deg, ${CARD} 0%, rgba(${my.tier_color === '#00C8FF' ? '0,200,255' : my.tier_color === '#FFB300' ? '255,179,0' : my.tier_color === '#FF6B35' ? '255,107,53' : my.tier_color === '#A8CFFF' ? '168,207,255' : my.tier_color === '#C0C0C0' ? '192,192,192' : my.tier_color === '#CD7F32' ? '205,127,50' : '90,106,138'},.08) 100%)`,
        border: `1px solid ${my.tier_color}33`,
        borderRadius: 12,
        padding: "1.75rem",
        marginBottom: "1.25rem",
        boxShadow: `0 0 30px ${my.tier_color}18`,
        display: "grid",
        gridTemplateColumns: "auto 1fr auto",
        gap: "1.5rem",
        alignItems: "center",
      }}>
        {/* Tier badge */}
        <TierBadge icon={my.tier_icon} label={my.tier_label} color={my.tier_color} size="lg" />

        {/* Progress */}
        <div>
          <div style={{ display:"flex",justifyContent:"space-between",alignItems:"baseline",marginBottom:6 }}>
            <span style={{ fontWeight:600,color:TEXT,fontSize:".95rem" }}>
              {my.display_name || "You"}
            </span>
            {my.position && (
              <span style={{ fontFamily:"'Orbitron',monospace",fontSize:".68rem",color:MUTED }}>
                Rank #{my.position}
              </span>
            )}
          </div>
          <div style={{ display:"flex",alignItems:"baseline",gap:6,marginBottom:10 }}>
            <span style={{ fontFamily:"'Orbitron',monospace",fontSize:"1.3rem",fontWeight:800,color:my.tier_color }}>
              {(my.ap || 0).toLocaleString()}
            </span>
            <span style={{ fontSize:".72rem",color:MUTED,fontFamily:"'Orbitron',sans-serif",letterSpacing:".1em" }}>AP</span>
          </div>
          <ProgressBar pct={my.progress_pct} color={my.tier_color} height={10} />
          <div style={{ display:"flex",justifyContent:"space-between",marginTop:5,fontSize:".68rem",color:MUTED }}>
            <span>{my.ap_in_tier} AP in tier</span>
            {my.ap_for_next > 0
              ? <span>{my.ap_for_next} AP to next tier</span>
              : <span style={{ color:"#FF6B35" }}>MAX RANK 👑</span>
            }
          </div>
        </div>

        {/* Pct circle */}
        <div style={{ textAlign:"center",display:"flex",flexDirection:"column",alignItems:"center",gap:4 }}>
          <div style={{ fontFamily:"'Orbitron',monospace",fontSize:"1.6rem",fontWeight:900,color:my.tier_color }}>
            {my.progress_pct}%
          </div>
          <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".54rem",color:MUTED,letterSpacing:".1em" }}>PROGRESS</div>
        </div>
      </div>

      {/* Tier progression overview */}
      <div style={{ background:CARD,border:`1px solid ${BORDER}`,borderRadius:10,padding:"1.25rem",marginBottom:"1.25rem" }}>
        <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".6rem",letterSpacing:".14em",color:MUTED,marginBottom:"1rem" }}>RANK TIERS</div>
        <div style={{ display:"flex",flexDirection:"column",gap:6 }}>
          {orderedTiers.map(tier => {
            const isMe = tier.key === my.tier_key;
            const count = dist[tier.key] || 0;
            return (
              <div key={tier.key} style={{
                display:"flex",alignItems:"center",gap:".75rem",
                padding:".5rem .75rem",
                borderRadius:6,
                background: isMe ? `${tier.color}12` : "transparent",
                border: isMe ? `1px solid ${tier.color}44` : "1px solid transparent",
              }}>
                <span style={{ fontSize:"1.1rem",flexShrink:0 }}>{tier.icon}</span>
                <div style={{ flex:1,minWidth:0 }}>
                  <div style={{ display:"flex",justifyContent:"space-between",marginBottom:3 }}>
                    <span style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".6rem",fontWeight:700,color: isMe ? tier.color : TEXT,letterSpacing:".08em" }}>
                      {tier.label.toUpperCase()} {isMe && <span style={{ color:CYAN }}>← YOU</span>}
                    </span>
                    <span style={{ fontSize:".65rem",color:MUTED }}>{tier.min_ap.toLocaleString()}{tier.max_ap ? `–${tier.max_ap.toLocaleString()}` : "+"} AP · {count} player{count !== 1 ? "s" : ""}</span>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Top AP leaderboard */}
      <div style={{ background:CARD,border:`1px solid ${BORDER}`,borderRadius:10,overflow:"hidden",marginBottom:"1.25rem" }}>
        <div style={{ padding:".9rem 1.1rem .6rem",borderBottom:`1px solid ${BORDER}` }}>
          <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".6rem",letterSpacing:".14em",color:MUTED }}>TOP AP THIS SEASON</div>
        </div>
        {top_players.length === 0 ? (
          <div style={{ padding:"2rem",textAlign:"center",color:MUTED,fontSize:".82rem" }}>No ranked players yet this season.</div>
        ) : top_players.map((p, i) => {
          const isMe = p.id === user?.id;
          return (
            <div key={p.id} style={{
              display:"flex",alignItems:"center",gap:".75rem",
              padding:".65rem 1rem",
              borderBottom: i < top_players.length-1 ? `1px solid ${BORDER}` : "none",
              background: isMe ? "rgba(0,200,255,.04)" : "transparent",
            }}>
              {/* rank number */}
              <div style={{ width:28,textAlign:"center",fontFamily:"'Orbitron',monospace",fontWeight:800,fontSize:i<3?"1rem":".78rem",color:i<3?["#FFB300","#94A3B8","#CD7F32"][i]:MUTED }}>
                {i < 3 ? ["🥇","🥈","🥉"][i] : `${i+1}`}
              </div>
              {/* avatar */}
              <div style={{ width:32,height:32,borderRadius:"50%",background:`${p.tier_color}22`,border:`1px solid ${p.tier_color}55`,display:"flex",alignItems:"center",justifyContent:"center",fontSize:".7rem",fontWeight:700,color:p.tier_color,flexShrink:0,fontFamily:"'Orbitron',sans-serif" }}>
                {getInitials(p.name)}
              </div>
              {/* name + tier */}
              <div style={{ flex:1,minWidth:0 }}>
                <div style={{ fontWeight:isMe?700:500,fontSize:".88rem",color:TEXT,overflow:"hidden",textOverflow:"ellipsis",whiteSpace:"nowrap" }}>
                  {p.name} {isMe && <span style={{ fontSize:".68rem",color:CYAN }}>(you)</span>}
                </div>
                <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".56rem",color:p.tier_color,marginTop:1,letterSpacing:".08em" }}>
                  {p.tier_icon} {p.tier_label.toUpperCase()}
                </div>
              </div>
              {/* AP */}
              <div style={{ textAlign:"right",flexShrink:0 }}>
                <div style={{ fontFamily:"'Orbitron',monospace",fontWeight:700,fontSize:".88rem",color:p.tier_color }}>
                  {(p.ap||0).toLocaleString()} <span style={{ fontSize:".6rem",color:MUTED }}>AP</span>
                </div>
                <div style={{ fontSize:".65rem",color:MUTED }}>{p.wins||0} wins</div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Footer note */}
      <div style={{ padding:".75rem",background:"rgba(255,179,0,.06)",border:"1px solid rgba(255,179,0,.18)",borderRadius:6,marginBottom:"1.25rem" }}>
        <p style={{ margin:0,fontSize:".75rem",color:"#FFB300",fontFamily:"'Orbitron',sans-serif",letterSpacing:".06em" }}>
          ⚠ AP resets at the end of each season. XP is permanent.
        </p>
      </div>

      {/* Nav */}
      <div style={{ display:"flex",gap:".75rem",flexWrap:"wrap" }}>
        <Link to="/arena" style={{ padding:".5rem 1rem",background:CARD,border:`1px solid rgba(0,200,255,.18)`,borderRadius:4,color:TEXT,textDecoration:"none",fontFamily:"'Orbitron',sans-serif",fontSize:".62rem",letterSpacing:".08em" }}>← ARENA HUB</Link>
        <Link to="/arena/lobby" style={{ padding:".5rem 1rem",background:CYAN,color:"#070B16",border:"none",borderRadius:4,textDecoration:"none",fontFamily:"'Orbitron',sans-serif",fontSize:".62rem",fontWeight:700,letterSpacing:".08em" }}>⚔️ BATTLE NOW</Link>
        <Link to="/arena/ranks" style={{ padding:".5rem 1rem",background:CARD,border:`1px solid rgba(168,85,247,.25)`,borderRadius:4,color:"#A855F7",textDecoration:"none",fontFamily:"'Orbitron',sans-serif",fontSize:".62rem",letterSpacing:".08em" }}>📊 XP LEADERBOARD</Link>
      </div>
    </div>
    </>
  );
}
