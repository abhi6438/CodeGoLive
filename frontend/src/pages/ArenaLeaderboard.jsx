import { useState, useEffect } from 'react';
import { useAuth } from '../lib/AuthContext';
import { api } from '../lib/api';
import { Link } from 'react-router-dom';
import SEO from "../components/SEO";

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
  if (error) return <div style={{ maxWidth:1000,margin:"2rem auto",padding:"1rem",color:"#FF5722" }}>{error}</div>;

  return (
          <SEO title="Leaderboard" description="CodeGoLive Arena global XP leaderboard." robots="noindex, nofollow" />
      <div style={{ maxWidth: 1300, margin: "0 auto", padding: "1.75rem 2.5rem 3rem", width: "100%", boxSizing: "border-box" }}>
      <style>{ORBITRON}</style>
      <div style={{ marginBottom: "1.5rem" }}>
        <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".6rem",letterSpacing:".16em",color:"#00C8FF",marginBottom:4 }}>ARENA</div>
        <h1 style={{ fontFamily:"'Orbitron',sans-serif",fontSize:"clamp(1.2rem,3vw,1.6rem)",fontWeight:700,margin:0,color:"#E8EEFF" }}>📊 Leaderboard</h1>
        <p style={{ color:"#7B8DB0",margin:".3rem 0 0",fontSize:".82rem" }}>Top 50 by Arena XP</p>
      </div>

      {/* My rank card */}
      {myEntry && (
        <div style={{ background:"#0C1220",border:"1px solid rgba(0,200,255,.35)",borderLeft:"3px solid #00C8FF",borderRadius:6,padding:"1rem 1.25rem",marginBottom:"1.25rem",display:"flex",alignItems:"center",gap:"1rem",boxShadow:"0 0 20px rgba(0,200,255,.1)" }}>
          <div style={{ fontFamily:"'Orbitron',monospace",fontSize:"1.4rem",fontWeight:800,color:"#00C8FF",minWidth:40,textAlign:"center" }}>#{myRank||"—"}</div>
          <div style={{ flex:1 }}>
            <div style={{ fontWeight:600,color:"#E8EEFF" }}>{myEntry.display_name} <span style={{ fontSize:".7rem",color:"#00C8FF" }}>(you)</span></div>
            <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".6rem",color:getTier(myEntry.arena_xp||0).color,marginTop:2 }}>{getTier(myEntry.arena_xp||0).emoji} {getTier(myEntry.arena_xp||0).label.toUpperCase()}</div>
          </div>
          <div style={{ textAlign:"right" }}>
            <div style={{ fontFamily:"'Orbitron',monospace",fontWeight:700,color:"#00C8FF" }}>{(myEntry.arena_xp||0).toLocaleString()} XP</div>
            <div style={{ fontSize:".72rem",color:"#7B8DB0" }}>{myEntry.arena_wins||0} wins</div>
          </div>
        </div>
      )}

      {/* List */}
      <div style={{ background:"#0C1220",border:"1px solid rgba(0,200,255,.12)",borderRadius:8,overflow:"hidden" }}>
        {entries.length === 0 ? (
          <div style={{ padding:"3rem",textAlign:"center",color:"#7B8DB0" }}>
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
              <div style={{ width:28,textAlign:"center",fontFamily:"'Orbitron',monospace",fontWeight:700,fontSize:i<3?"1rem":".8rem",color:i<3?["#FFB300","#94A3B8","#CD7F32"][i]:"#3A4A68" }}>
                {i<3 ? ["🥇","🥈","🥉"][i] : `${i+1}`}
              </div>
              <div style={{ width:30,height:30,borderRadius:"50%",background:`${tier.color}22`,border:`1px solid ${tier.color}55`,display:"flex",alignItems:"center",justifyContent:"center",fontSize:".68rem",fontWeight:700,color:tier.color,flexShrink:0,fontFamily:"'Orbitron',sans-serif" }}>
                {getInitials(e.display_name)}
              </div>
              <div style={{ flex:1,minWidth:0 }}>
                <div style={{ fontWeight:isMe?700:500,fontSize:".88rem",color:"#E8EEFF",overflow:"hidden",textOverflow:"ellipsis",whiteSpace:"nowrap" }}>
                  {e.display_name||"Anonymous"} {isMe&&<span style={{ fontSize:".68rem",color:"#00C8FF" }}>(you)</span>}
                </div>
                <div style={{ fontFamily:"'Orbitron',sans-serif",fontSize:".58rem",color:tier.color,marginTop:1 }}>{tier.emoji} {tier.label.toUpperCase()}</div>
              </div>
              <div style={{ textAlign:"right",flexShrink:0 }}>
                <div style={{ fontFamily:"'Orbitron',monospace",fontWeight:600,fontSize:".88rem",color:"#00C8FF" }}>{(e.arena_xp||0).toLocaleString()} <span style={{ fontSize:".6rem",color:"#7B8DB0" }}>XP</span></div>
                <div style={{ fontSize:".68rem",color:"#7B8DB0" }}>{e.arena_wins||0}W · {e.arena_ap||0} AP</div>
              </div>
            </div>
          );
        })}
      </div>

      <div style={{ marginTop:"1.25rem",display:"flex",gap:".75rem",flexWrap:"wrap" }}>
        <Link to="/arena" style={{ padding:".5rem 1rem",background:"#0C1220",border:"1px solid rgba(0,200,255,.18)",borderRadius:4,color:"#E8EEFF",textDecoration:"none",fontFamily:"'Orbitron',sans-serif",fontSize:".62rem",letterSpacing:".08em" }}>← ARENA HUB</Link>
        <Link to="/arena/lobby" style={{ padding:".5rem 1rem",background:"#00C8FF",color:"#070B16",border:"none",borderRadius:4,textDecoration:"none",fontFamily:"'Orbitron',sans-serif",fontSize:".62rem",fontWeight:700,letterSpacing:".08em" }}>⚔️ BATTLE NOW</Link>
      </div>
    </div>
  );
}
