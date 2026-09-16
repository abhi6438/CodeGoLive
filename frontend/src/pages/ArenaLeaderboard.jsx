import { useState, useEffect } from 'react';
import { useAuth } from '../lib/AuthContext';
import { api } from '../lib/api';
import { Link } from 'react-router-dom';
import SEO from "../components/SEO";

const ARENA_THEME_CSS = `
  .arena-page {
    --ah-bg:      var(--ah-bg);
    --ah-surf:    var(--ah-surf);
    --ah-surf2:   var(--ah-surf2);
    --ah-text:    var(--ah-text);
    --ah-text2:   var(--ah-text2);
    --ah-text3:   var(--ah-text3);
    --ah-item-bg: var(--ah-item-bg);
    --ah-item-bd: rgba(0,200,255,.07);
    --ah-dot:     var(--ah-dot);
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

const RANK_TIERS = [
  { min: 10000, label: "Legendary", color: "#FF6B35", emoji: "🔱" },
  { min: 5000,  label: "Master",    color: "#A855F7", emoji: "💠" },
  { min: 2000,  label: "Diamond",   color: "#00C8FF", emoji: "💎" },
  { min: 1000,  label: "Platinum",  color: "#E2E8F0", emoji: "🌟" },
  { min: 500,   label: "Gold",      color: "#FFB300", emoji: "🏅" },
  { min: 200,   label: "Silver",    color: "#94A3B8", emoji: "🥈" },
  { min: 0,     label: "Bronze",    color: "#CD7F32", emoji: "🥉" },
];

function getTier(xp) { return RANK_TIERS.find(t => xp >= t.min) || RANK_TIERS[RANK_TIERS.length - 1]; }
function getInitials(name) { if (!name) return '?'; return name.split(' ').map(w => w[0]).join('').toUpperCase().slice(0, 2); }

export default function ArenaLeaderboard() {
  const { session } = useAuth();
  const user = session?.user;
  const [entries, setEntries] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    api.get('/api/arena/leaderboard')
      .then(data => { setEntries(data || []); setLoading(false); })
      .catch(() => { setError('Failed to load leaderboard.'); setLoading(false); });
  }, []);

  const myRank = entries.findIndex(e => e.id === user?.id) + 1;
  const myEntry = entries.find(e => e.id === user?.id);

  if (loading) return <div style={{ display:"flex",alignItems:"center",justifyContent:"center",minHeight:"60vh" }}><div style={{ fontFamily:"'Orbitron',sans-serif",color:"#00C8FF" }}>Loading ranks…</div></div>;
  if (error) return <div className="arena-page" style={{ maxWidth:1000,margin:"2rem auto",padding:"1rem",color:"#FF5722" }}>{error}</div>;

  return (
          <>
            <SEO title="Leaderboard" description="CodeGoLive Arena global XP leaderboard." robots="noindex, nofollow" />
      <div style={{ maxWidth: 1300, margin: "0 auto", padding: "1.75rem 2.5rem 3rem", width: "100%", boxSizing: "border-box" }}>
      <style>{ARENA_THEME_CSS}{ORBITRON}</style>
      <div style={{ marginBottom: "1.5rem" }}>
        <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".6rem",letterSpacing:".16em",color:"#00C8FF",marginBottom:4 }}>ARENA</div>
        <h1 style={{ fontFamily:"'Orbitron',sans-serif",fontSize:"clamp(1.2rem,3vw,1.6rem)",fontWeight:700,margin:0,color:"var(--ah-text)" }}>📊 Leaderboard</h1>
        <p style={{ color:"var(--ah-text2)",margin:".3rem 0 0",fontSize:".82rem" }}>Top 50 by Arena XP</p>
      </div>

      {/* My rank card */}
      {myEntry && (
        <div style={{ background:"var(--ah-bg)",border:"1px solid rgba(0,200,255,.35)",borderLeft:"3px solid #00C8FF",borderRadius:6,padding:"1rem 1.25rem",marginBottom:"1.25rem",display:"flex",alignItems:"center",gap:"1rem",boxShadow:"0 0 20px rgba(0,200,255,.1)" }}>
          <div style={{ fontFamily:"'Orbitron',monospace",fontSize:"1.4rem",fontWeight:800,color:"#00C8FF",minWidth:40,textAlign:"center" }}>#{myRank||"—"}</div>
          <div style={{ flex:1 }}>
            <div style={{ fontWeight:600,color:"var(--ah-text)" }}>{myEntry.display_name} <span style={{ fontSize:".7rem",color:"#00C8FF" }}>(you)</span></div>
            <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".6rem",color:getTier(myEntry.arena_xp||0).color,marginTop:2 }}>{getTier(myEntry.arena_xp||0).emoji} {getTier(myEntry.arena_xp||0).label.toUpperCase()}</div>
          </div>
          <div style={{ textAlign:"right" }}>
            <div style={{ fontFamily:"'Orbitron',monospace",fontWeight:700,color:"#00C8FF" }}>{(myEntry.arena_xp||0).toLocaleString()} XP</div>
            <div style={{ fontSize:".72rem",color:"var(--ah-text2)" }}>{myEntry.arena_wins||0} wins</div>
          </div>
        </div>
      )}

      {/* List */}
      <div style={{ background:"var(--ah-bg)",border:"1px solid rgba(0,200,255,.12)",borderRadius:8,overflow:"hidden" }}>
        {entries.length === 0 ? (
          <div style={{ padding:"3rem",textAlign:"center",color:"var(--ah-text2)" }}>
            <div style={{ fontSize:"2rem",marginBottom:".5rem" }}>🎯</div>
            <p style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".72rem" }}>No entries yet. Be the first!</p>
          </div>
        ) : entries.map((e, i) => {
          const tier = getTier(e.arena_xp||0);
          const isMe = e.id === user?.id;
          return (
            <div key={e.id} style={{
              display:"flex",alignItems:"center",gap:".75rem",
              padding:".7rem 1rem",
              borderBottom: i < entries.length-1 ? "1px solid rgba(0,200,255,.07)" : "none",
              background: isMe ? "rgba(0,200,255,.04)" : "transparent",
            }}>
              <div style={{ width:28,textAlign:"center",fontFamily:"'Orbitron',monospace",fontWeight:700,fontSize:i<3?"1rem":".8rem",color:i<3?["#FFB300","#94A3B8","#CD7F32"][i]:"var(--ah-text3)" }}>
                {i<3 ? ["🥇","🥈","🥉"][i] : `${i+1}`}
              </div>
              <div style={{ width:30,height:30,borderRadius:"50%",background:`${tier.color}22`,border:`1px solid ${tier.color}55`,display:"flex",alignItems:"center",justifyContent:"center",fontSize:".68rem",fontWeight:700,color:tier.color,flexShrink:0,fontFamily:"'Orbitron',sans-serif" }}>
                {getInitials(e.display_name)}
              </div>
              <div style={{ flex:1,minWidth:0 }}>
                <div style={{ fontWeight:isMe?700:500,fontSize:".88rem",color:"var(--ah-text)",overflow:"hidden",textOverflow:"ellipsis",whiteSpace:"nowrap" }}>
                  {e.display_name||"Anonymous"} {isMe&&<span style={{ fontSize:".68rem",color:"#00C8FF" }}>(you)</span>}
                </div>
                <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".58rem",color:tier.color,marginTop:1 }}>{tier.emoji} {tier.label.toUpperCase()}</div>
              </div>
              <div style={{ textAlign:"right",flexShrink:0 }}>
                <div style={{ fontFamily:"'Orbitron',monospace",fontWeight:600,fontSize:".88rem",color:"#00C8FF" }}>{(e.arena_xp||0).toLocaleString()} <span style={{ fontSize:".6rem",color:"var(--ah-text2)" }}>XP</span></div>
                <div style={{ fontSize:".68rem",color:"var(--ah-text2)" }}>{e.arena_wins||0}W · {e.arena_ap||0} AP</div>
              </div>
            </div>
          );
        })}
      </div>

      <div style={{ marginTop:"1.25rem",display:"flex",gap:".75rem",flexWrap:"wrap" }}>
        <Link to="/arena" style={{ padding:".5rem 1rem",background:"var(--ah-bg)",border:"1px solid rgba(0,200,255,.18)",borderRadius:4,color:"var(--ah-text)",textDecoration:"none",fontFamily:"'Orbitron',sans-serif",fontSize:".62rem",letterSpacing:".08em" }}>← ARENA HUB</Link>
        <Link to="/arena/lobby" style={{ padding:".5rem 1rem",background:"#00C8FF",color:"#070B16",border:"none",borderRadius:4,textDecoration:"none",fontFamily:"'Orbitron',sans-serif",fontSize:".62rem",fontWeight:700,letterSpacing:".08em" }}>⚔️ BATTLE NOW</Link>
      </div>
    </div>
    </>
  );
}
