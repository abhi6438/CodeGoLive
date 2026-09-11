import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../lib/AuthContext';
import { api } from '../lib/api';
import SEO from "../components/SEO";

const ORBITRON = `@import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@400;600;700;900&display=swap');`;

const TOPIC_LABELS = {
  'sap-btp': 'SAP BTP',
  'sap-ai':  'SAP AI',
};

const RESULT_CONFIG = {
  win:       { label: 'WIN',       bg: 'rgba(0,230,118,.15)',  border: '#00E676', color: '#00E676', icon: '🏆' },
  loss:      { label: 'LOSS',      bg: 'rgba(255,87,34,.12)',  border: '#FF5722', color: '#FF5722', icon: '💀' },
  draw:      { label: 'DRAW',      bg: 'rgba(255,179,0,.12)',  border: '#FFB300', color: '#FFB300', icon: '🤝' },
  cancelled: { label: 'CANCELLED', bg: 'rgba(123,141,176,.1)', border: '#3A4A68', color: '#7B8DB0', icon: '✖' },
};

function fmt(iso) {
  if (!iso) return '—';
  const d = new Date(iso);
  const now = new Date();
  const diff = (now - d) / 1000;
  if (diff < 60)   return 'just now';
  if (diff < 3600) return `${Math.floor(diff/60)}m ago`;
  if (diff < 86400)return `${Math.floor(diff/3600)}h ago`;
  if (diff < 604800) return `${Math.floor(diff/86400)}d ago`;
  return d.toLocaleDateString(undefined, { month:'short', day:'numeric', year:'numeric' });
}

function Accuracy({ correct, total }) {
  if (!total) return <span style={{ color:'#3A4A68' }}>—</span>;
  const pct = Math.round((correct / total) * 100);
  return <span>{correct}/{total} <span style={{ color:'#7B8DB0', fontSize:'.72em' }}>({pct}%)</span></span>;
}

export default function ArenaHistory() {
  const navigate = useNavigate();
  const [matches, setMatches] = useState([]);
  const [loading, setLoading]  = useState(true);
  const [error,   setError]    = useState(null);

  useEffect(() => {
    api.get('/api/arena/history')
      .then(data => { setMatches(data || []); setLoading(false); })
      .catch(() => { setError('Failed to load match history.'); setLoading(false); });
  }, []);

  const wins   = matches.filter(m => m.result === 'win').length;
  const losses = matches.filter(m => m.result === 'loss').length;
  const draws  = matches.filter(m => m.result === 'draw').length;
  const total  = wins + losses + draws;
  const winRate = total ? Math.round((wins / total) * 100) : 0;

  if (loading) return (
          <>
            <SEO title="Match History" description="Your CodeGoLive Arena match history and stats." robots="noindex, nofollow" />
      <div style={{ display:'flex', alignItems:'center', justifyContent:'center', minHeight:'60vh' }}>
      <div style={{ fontFamily:"'Orbitron',sans-serif", color:'#00C8FF', fontSize:'.8rem', letterSpacing:'.12em' }}>
        LOADING HISTORY…
      </div>
    </div>
  );

  if (error) return (
    <div style={{ maxWidth:900, margin:'2rem auto', padding:'1rem', color:'#FF5722' }}>{error}</div>
  );

  return (
    <div style={{ maxWidth:1000, margin:'0 auto', padding:'1.75rem 2rem 3rem', width:'100%', boxSizing:'border-box' }}>
      <style>{ORBITRON}</style>

      {/* Header */}
      <div style={{ marginBottom:'1.5rem' }}>
        <div style={{ fontFamily:"'Orbitron',sans-serif", fontSize:'.6rem', letterSpacing:'.16em', color:'#00C8FF', marginBottom:4 }}>ARENA</div>
        <h1 style={{ fontFamily:"'Orbitron',sans-serif", fontSize:'clamp(1.2rem,3vw,1.6rem)', fontWeight:700, margin:0, color:'#E8EEFF' }}>
          ⚔️ Match History
        </h1>
        <p style={{ color:'#7B8DB0', margin:'.3rem 0 0', fontSize:'.82rem' }}>Your last 50 completed matches</p>
      </div>

      {/* Summary cards */}
      {total > 0 && (
        <div style={{ display:'grid', gridTemplateColumns:'repeat(auto-fit, minmax(130px, 1fr))', gap:'.75rem', marginBottom:'1.5rem' }}>
          {[
            { label:'Matches', val: total,    color:'#E8EEFF' },
            { label:'Wins',    val: wins,     color:'#00E676' },
            { label:'Losses',  val: losses,   color:'#FF5722' },
            { label:'Draws',   val: draws,    color:'#FFB300' },
            { label:'Win Rate',val: winRate+'%', color: winRate >= 50 ? '#00E676' : '#FF5722' },
          ].map(({ label, val, color }) => (
            <div key={label} style={{ background:'#0C1220', border:'1px solid rgba(0,200,255,.12)', borderRadius:6, padding:'.75rem 1rem' }}>
              <div style={{ fontFamily:"'Orbitron',sans-serif", fontSize:'.56rem', letterSpacing:'.1em', color:'#7B8DB0', marginBottom:4 }}>{label.toUpperCase()}</div>
              <div style={{ fontFamily:"'Orbitron',monospace", fontSize:'1.4rem', fontWeight:700, color }}>{val}</div>
            </div>
          ))}
        </div>
      )}

      {/* Match list */}
      {matches.length === 0 ? (
        <div style={{ background:'#0C1220', border:'1px solid rgba(0,200,255,.12)', borderRadius:8, padding:'3rem', textAlign:'center' }}>
          <div style={{ fontSize:'2.5rem', marginBottom:'1rem' }}>🎯</div>
          <p style={{ fontFamily:"'Orbitron',sans-serif", fontSize:'.72rem', color:'#7B8DB0', letterSpacing:'.1em' }}>NO MATCHES YET</p>
          <p style={{ color:'#3A4A68', fontSize:'.82rem', marginTop:'.5rem' }}>Complete your first battle to see history here.</p>
          <Link to="/arena/lobby" style={{ display:'inline-block', marginTop:'1.25rem', padding:'.6rem 1.4rem', background:'#00C8FF', color:'#070B16', borderRadius:4, textDecoration:'none', fontFamily:"'Orbitron',sans-serif", fontSize:'.65rem', fontWeight:700, letterSpacing:'.1em' }}>
            ⚔️ FIND A MATCH
          </Link>
        </div>
      ) : (
        <div style={{ display:'flex', flexDirection:'column', gap:'.6rem' }}>
          {matches.map((m) => {
            const cfg = RESULT_CONFIG[m.result] || RESULT_CONFIG.cancelled;
            const topic = TOPIC_LABELS[m.topic_id] || m.topic_id || 'Unknown';
            const canViewResult = m.result !== 'cancelled';

            return (
              <div
                key={m.match_id}
                onClick={() => canViewResult && navigate(`/arena/result/${m.match_id}`)}
                style={{
                  background:'#0C1220',
                  border:`1px solid ${canViewResult ? 'rgba(0,200,255,.12)' : 'rgba(58,74,104,.4)'}`,
                  borderLeft:`3px solid ${cfg.border}`,
                  borderRadius:6,
                  padding:'.85rem 1rem',
                  cursor: canViewResult ? 'pointer' : 'default',
                  transition:'background .15s',
                  display:'flex',
                  alignItems:'center',
                  gap:'1rem',
                  flexWrap:'wrap',
                }}
                onMouseEnter={e => { if (canViewResult) e.currentTarget.style.background = '#111827'; }}
                onMouseLeave={e => { e.currentTarget.style.background = '#0C1220'; }}
              >
                {/* Result badge */}
                <div style={{
                  minWidth:72,
                  padding:'.3rem .5rem',
                  background: cfg.bg,
                  border:`1px solid ${cfg.border}`,
                  borderRadius:4,
                  textAlign:'center',
                  flexShrink:0,
                }}>
                  <div style={{ fontSize:'.9rem' }}>{cfg.icon}</div>
                  <div style={{ fontFamily:"'Orbitron',sans-serif", fontSize:'.55rem', fontWeight:700, color: cfg.color, letterSpacing:'.08em', marginTop:2 }}>{cfg.label}</div>
                </div>

                {/* Opponent */}
                <div style={{ flex:1, minWidth:140 }}>
                  <div style={{ fontSize:'.75rem', color:'#7B8DB0', marginBottom:2 }}>vs</div>
                  <div style={{ fontWeight:600, color:'#E8EEFF', fontSize:'.92rem' }}>{m.opp_name}</div>
                  <div style={{ fontFamily:"'Orbitron',sans-serif", fontSize:'.55rem', color:'#3A4A68', marginTop:2, letterSpacing:'.08em' }}>{topic}</div>
                </div>

                {/* Scores */}
                <div style={{ display:'flex', gap:'1.5rem', flexShrink:0 }}>
                  <div style={{ textAlign:'center' }}>
                    <div style={{ fontFamily:"'Orbitron',sans-serif", fontSize:'.55rem', color:'#7B8DB0', letterSpacing:'.08em', marginBottom:3 }}>MY SCORE</div>
                    <div style={{ fontFamily:"'Orbitron',monospace", fontSize:'.95rem', fontWeight:700, color:'#00C8FF' }}>{m.my_xp} <span style={{ fontSize:'.6rem', color:'#7B8DB0' }}>XP</span></div>
                    <div style={{ fontSize:'.7rem', color:'#7B8DB0', marginTop:2 }}><Accuracy correct={m.my_correct} total={m.my_total} /></div>
                  </div>
                  <div style={{ textAlign:'center' }}>
                    <div style={{ fontFamily:"'Orbitron',sans-serif", fontSize:'.55rem', color:'#7B8DB0', letterSpacing:'.08em', marginBottom:3 }}>THEIR SCORE</div>
                    <div style={{ fontFamily:"'Orbitron',monospace", fontSize:'.95rem', fontWeight:700, color:'#E8EEFF' }}>{m.opp_xp} <span style={{ fontSize:'.6rem', color:'#7B8DB0' }}>XP</span></div>
                    <div style={{ fontSize:'.7rem', color:'#7B8DB0', marginTop:2 }}><Accuracy correct={m.opp_correct} total={m.my_total} /></div>
                  </div>
                </div>

                {/* Date + arrow */}
                <div style={{ textAlign:'right', flexShrink:0 }}>
                  <div style={{ fontSize:'.72rem', color:'#3A4A68' }}>{fmt(m.finished_at)}</div>
                  {canViewResult && (
                    <div style={{ fontFamily:"'Orbitron',sans-serif", fontSize:'.55rem', color:'#00C8FF', marginTop:4, letterSpacing:'.08em' }}>VIEW →</div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Footer nav */}
      <div style={{ marginTop:'1.5rem', display:'flex', gap:'.75rem', flexWrap:'wrap' }}>
        <Link to="/arena" style={{ padding:'.5rem 1rem', background:'#0C1220', border:'1px solid rgba(0,200,255,.18)', borderRadius:4, color:'#E8EEFF', textDecoration:'none', fontFamily:"'Orbitron',sans-serif", fontSize:'.62rem', letterSpacing:'.08em' }}>
          ← ARENA HUB
        </Link>
        <Link to="/arena/lobby" style={{ padding:'.5rem 1rem', background:'#00C8FF', color:'#070B16', border:'none', borderRadius:4, textDecoration:'none', fontFamily:"'Orbitron',sans-serif", fontSize:'.62rem', fontWeight:700, letterSpacing:'.08em' }}>
          ⚔️ BATTLE NOW
        </Link>
        <Link to="/arena/ranks" style={{ padding:'.5rem 1rem', background:'#0C1220', border:'1px solid rgba(0,200,255,.18)', borderRadius:4, color:'#E8EEFF', textDecoration:'none', fontFamily:"'Orbitron',sans-serif", fontSize:'.62rem', letterSpacing:'.08em' }}>
          📊 LEADERBOARD
        </Link>
      </div>
    </div>
    </>
  );
}
