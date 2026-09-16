import { useState, useEffect, useRef, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { api } from '../lib/api';
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


const PRIZES = [
  { key: 'ap_50',     label: '+50 AP',      color: '#00C8FF', prob: .25 },
  { key: 'ap_150',    label: '+150 AP',     color: '#FFB300', prob: .20 },
  { key: 'powerup',   label: 'Time Freeze', color: '#00E676', prob: .20 },
  { key: 'cosmetic',  label: 'Cosmetic',    color: '#A855F7', prob: .15 },
  { key: 'xp_100',    label: '+100 XP',     color: '#00C8FF', prob: .10 },
  { key: 'ap_2x',     label: '2x AP Next',  color: '#FF5722', prob: .06 },
  { key: 'jackpot',   label: 'JACKPOT!',    color: '#FFB300', prob: .02 },
  { key: 'try_again', label: 'Try Again',   color: 'var(--ah-text3)', prob: .02 },
];
const SEG_ANGLE = 360 / 8; // 45deg per segment

function hexToRgba(hex, alpha) {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return `rgba(${r},${g},${b},${alpha})`;
}

function prizeEmoji(key) {
  const map = {
    ap_50: '💰', ap_150: '💰', powerup: '❄️', cosmetic: '✨',
    xp_100: '⚡', ap_2x: '🔥', ap_2x_next: '🔥', jackpot: '🎰', try_again: '🔄',
  };
  return map[key] || '🎁';
}

function formatCountdown(ms) {
  if (ms <= 0) return null;
  const totalSec = Math.floor(ms / 1000);
  const h = Math.floor(totalSec / 3600);
  const m = Math.floor((totalSec % 3600) / 60);
  return `${h}h ${m}m`;
}

function useCountUp(target, duration = 1200, active) {
  const [val, setVal] = useState(0);
  useEffect(() => {
    if (!active || !target) return;
    setVal(0);
    const start = performance.now();
    let raf;
    function step(now) {
      const p = Math.min((now - start) / duration, 1);
      setVal(Math.round(p * target));
      if (p < 1) raf = requestAnimationFrame(step);
    }
    raf = requestAnimationFrame(step);
    return () => cancelAnimationFrame(raf);
  }, [target, active, duration]);
  return val;
}

export default function ArenaSpinWheel() {
  const navigate = useNavigate();
  const canvasRef = useRef(null);
  const rotationRef = useRef(0);
  const rafRef = useRef(null);
  // Synchronous guard against rapid double-clicks before React state updates
  const isSpinningRef = useRef(false);

  const [hasFreeSpin, setHasFreeSpin] = useState(false);
  const [nextFreeSpinAt, setNextFreeSpinAt] = useState(null);
  const [history, setHistory] = useState([]);
  const [isSpinning, setIsSpinning] = useState(false);
  // Short cooldown after each spin so the button can't be re-clicked immediately
  const [spinCooldown, setSpinCooldown] = useState(false);
  // Inline AP-cost confirmation before a paid spin fires
  const [showApConfirm, setShowApConfirm] = useState(false);
  const [lastPrize, setLastPrize] = useState(null);
  const [showResult, setShowResult] = useState(false);
  const [countdown, setCountdown] = useState('');
  const [error, setError] = useState(null);

  const prizeNumber = lastPrize
    ? parseInt((lastPrize.amount || lastPrize.value || '0').toString().replace(/\D/g, ''), 10) || 0
    : 0;
  const countUp = useCountUp(prizeNumber, 1200, showResult);

  const fetchStatus = useCallback(() => {
    api.get('/api/arena/spin/status')
      .then(d => {
        const s = d.spin_status || d;
        setHasFreeSpin(s.has_free_spin);
        setNextFreeSpinAt(s.next_free_spin_at ? new Date(s.next_free_spin_at) : null);
        setHistory((d.history || []).slice(0, 5));
      })
      .catch(() => {});
  }, []);

  useEffect(() => {
    fetchStatus();
  }, [fetchStatus]);

  // Countdown to next free spin
  useEffect(() => {
    if (!nextFreeSpinAt) { setCountdown(''); return; }
    function tick() {
      const diff = nextFreeSpinAt - Date.now();
      const cd = formatCountdown(diff);
      setCountdown(cd || '');
      if (diff <= 0) { fetchStatus(); }
    }
    tick();
    const id = setInterval(tick, 30000);
    return () => clearInterval(id);
  }, [nextFreeSpinAt, fetchStatus]);

  // Draw wheel
  const drawWheel = useCallback((rotationAngle) => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const W = canvas.width;
    const H = canvas.height;
    const cx = W / 2;
    const cy = H / 2;
    const R = cx - 8;

    ctx.clearRect(0, 0, W, H);

    // Outer ring
    ctx.beginPath();
    ctx.arc(cx, cy, R + 4, 0, Math.PI * 2);
    ctx.strokeStyle = '#1E3050';
    ctx.lineWidth = 3;
    ctx.stroke();

    PRIZES.forEach((prize, i) => {
      const startAngle = ((i * SEG_ANGLE + rotationAngle) * Math.PI) / 180;
      const endAngle = startAngle + (SEG_ANGLE * Math.PI) / 180;

      // Segment fill
      ctx.beginPath();
      ctx.moveTo(cx, cy);
      ctx.arc(cx, cy, R, startAngle, endAngle);
      ctx.closePath();
      ctx.fillStyle = hexToRgba(prize.color, 0.6);
      ctx.fill();
      ctx.strokeStyle = '#1E3050';
      ctx.lineWidth = 1.5;
      ctx.stroke();

      // Label
      const midAngle = startAngle + (SEG_ANGLE * Math.PI) / 180 / 2;
      const tx = cx + Math.cos(midAngle) * 110;
      const ty = cy + Math.sin(midAngle) * 110;

      ctx.save();
      ctx.translate(tx, ty);
      ctx.rotate(midAngle + Math.PI / 2);
      ctx.fillStyle = '#FFFFFF';
      ctx.font = 'bold 10px Inter, sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      // Word wrap at ~10 chars
      const words = prize.label.split(' ');
      if (words.length > 1) {
        ctx.fillText(words[0], 0, -6);
        ctx.fillText(words.slice(1).join(' '), 0, 6);
      } else {
        ctx.fillText(prize.label, 0, 0);
      }
      ctx.restore();
    });

    // Center circle
    ctx.beginPath();
    ctx.arc(cx, cy, 30, 0, Math.PI * 2);
    ctx.fillStyle = 'var(--ah-bg)';
    ctx.fill();
    ctx.strokeStyle = '#00C8FF';
    ctx.lineWidth = 2;
    ctx.stroke();

    ctx.fillStyle = '#00C8FF';
    ctx.font = 'bold 11px Orbitron, Inter, sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('SPIN', cx, cy);
  }, []);

  useEffect(() => {
    drawWheel(rotationRef.current);
  }, [drawWheel]);

  const doSpin = useCallback(async () => {
    // Use a ref for the immediate guard — React state updates are async so
    // rapid double-clicks can both pass the isSpinning state check before
    // the first setIsSpinning(true) has been applied.
    if (isSpinningRef.current) return;
    isSpinningRef.current = true;
    setIsSpinning(true);
    setShowResult(false);
    setShowApConfirm(false);
    setLastPrize(null);
    setError(null);

    let result;
    try {
      result = await api.post('/api/arena/spin', { is_free: hasFreeSpin });
    } catch (e) {
      setError(e.message || 'Spin failed. Try again.');
      isSpinningRef.current = false;
      setIsSpinning(false);
      return;
    }

    // Find prize index
    const prizeKey = result.prize?.key || result.prize_key || 'try_again';
    const prizeIdx = PRIZES.findIndex(p => p.key === prizeKey);
    const safePrizeIdx = prizeIdx >= 0 ? prizeIdx : 0;

    // Calculate target rotation so that the winning segment faces the pointer (top = 270deg)
    // Pointer is at top => angle 270deg. Segment center = safePrizeIdx * SEG_ANGLE + SEG_ANGLE/2
    // We need: (safePrizeIdx * SEG_ANGLE + SEG_ANGLE/2 + finalRotation) % 360 = 270
    const segCenter = safePrizeIdx * SEG_ANGLE + SEG_ANGLE / 2;
    const targetAngle = (270 - segCenter + 360) % 360;
    const extraRotations = (5 + Math.floor(Math.random() * 4)) * 360; // 5-8 full spins
    const startRot = rotationRef.current % 360;
    const endRot = rotationRef.current - (rotationRef.current % 360) + extraRotations + targetAngle;

    const duration = 3500;
    const startTime = performance.now();

    function easeOut(progress) {
      return 1 - Math.pow(1 - progress, 4);
    }

    function animate(now) {
      const elapsed = now - startTime;
      const rawProgress = Math.min(elapsed / duration, 1);
      const progress = easeOut(rawProgress);
      const currentRot = startRot + (endRot - startRot) * progress;
      rotationRef.current = currentRot;
      drawWheel(currentRot);

      if (rawProgress < 1) {
        rafRef.current = requestAnimationFrame(animate);
      } else {
        rotationRef.current = endRot % 360;
        drawWheel(rotationRef.current);
        setLastPrize(result.prize || { key: prizeKey, label: PRIZES[safePrizeIdx].label });
        // Optimistically mark free spin as used so the button is immediately
        // disabled after a free spin — fetchStatus() will confirm the real state.
        if (hasFreeSpin) setHasFreeSpin(false);
        isSpinningRef.current = false;
        setIsSpinning(false);
        setShowResult(true);
        // 2.5 s cooldown before the button re-enables — prevents accidental rapid re-spins
        setSpinCooldown(true);
        setTimeout(() => setSpinCooldown(false), 2500);
        fetchStatus();
      }
    }

    if (rafRef.current) cancelAnimationFrame(rafRef.current);
    rafRef.current = requestAnimationFrame(animate);
  }, [isSpinning, hasFreeSpin, drawWheel, fetchStatus]);

  useEffect(() => {
    return () => { if (rafRef.current) cancelAnimationFrame(rafRef.current); };
  }, []);

  const btnDisabled = isSpinning || isSpinningRef.current || spinCooldown;
  const spinButtonStyle = hasFreeSpin
    ? {
        background: '#00C8FF',
        color: 'var(--ah-bg)',
        border: 'none',
        padding: '14px 36px',
        borderRadius: 12,
        fontSize: 17,
        fontWeight: 800,
        cursor: btnDisabled ? 'not-allowed' : 'pointer',
        opacity: btnDisabled ? 0.6 : 1,
        fontFamily: "'Orbitron', Inter, sans-serif",
        letterSpacing: 1,
        transition: 'transform .1s, opacity .2s',
        boxShadow: btnDisabled ? 'none' : '0 0 16px rgba(0,200,255,0.5)',
      }
    : {
        background: 'transparent',
        color: '#00C8FF',
        border: '2px solid #00C8FF',
        padding: '13px 32px',
        borderRadius: 12,
        fontSize: 16,
        fontWeight: 700,
        cursor: btnDisabled ? 'not-allowed' : 'pointer',
        opacity: btnDisabled ? 0.6 : 1,
        fontFamily: "'Orbitron', Inter, sans-serif",
        letterSpacing: 1,
        transition: 'transform .1s, opacity .2s',
      };

  const currentPrizeObj = lastPrize
    ? PRIZES.find(p => p.key === (lastPrize.key || lastPrize.prize_key)) || PRIZES[0]
    : null;

  return (
          <>
            <SEO title="Spin Wheel" description="Spin the daily wheel for bonus XP and AP on CodeGoLive Arena." robots="noindex, nofollow" />
      <div className="arena-page" style={{
      minHeight: '100vh',
      background: 'var(--ah-bg)',
      color: 'var(--ah-text)',
      fontFamily: "'Inter', sans-serif",
      padding: '24px 16px 80px',
      maxWidth: 900,
      margin: '0 auto',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
    }}>
      <style>{ARENA_THEME_CSS}{`
        @import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@400;700;800&display=swap');
        @keyframes swFadeIn {
          from { opacity: 0; transform: scale(.9) translateY(10px); }
          to   { opacity: 1; transform: scale(1) translateY(0); }
        }
        @keyframes swGlow {
          0%,100% { box-shadow: 0 0 10px rgba(0,200,255,.3); }
          50%      { box-shadow: 0 0 24px rgba(0,200,255,.7); }
        }
        @keyframes swPop {
          0%   { transform: scale(.7); opacity: 0; }
          70%  { transform: scale(1.08); opacity: 1; }
          100% { transform: scale(1); }
        }
      `}</style>

      <h1 style={{
        fontFamily: "'Orbitron', 'Inter', sans-serif",
        fontSize: 22,
        fontWeight: 700,
        marginBottom: 24,
        textAlign: 'center',
      }}>
        🎰 Spin the Wheel
      </h1>

      {/* Back button */}
      <div style={{ width:'100%',maxWidth:780,display:'flex',alignItems:'center',marginBottom:'1.25rem' }}>
        <button onClick={() => navigate('/arena')} style={{ display:'flex',alignItems:'center',gap:'.4rem',background:'transparent',border:'1px solid rgba(0,200,255,.2)',borderRadius:4,padding:'.35rem .85rem',color:'var(--ah-text2)',fontFamily:"'Orbitron', sans-serif",fontSize:'.58rem',letterSpacing:'.08em',cursor:'pointer' }}>← ARENA HUB</button>
      </div>

      {/* Pointer triangle above canvas */}
      <div style={{ position: 'relative', marginBottom: 4 }}>
        <div style={{ display:'flex',justifyContent:'center',marginBottom:4 }}>
          <svg width="28" height="24" viewBox="0 0 28 24" style={{ filter: 'drop-shadow(0 0 6px #00C8FF)' }}>
            <polygon points="14,24 0,0 28,0" fill="#00C8FF" />
          </svg>
        </div>

        <canvas
          ref={canvasRef}
          width={300}
          height={300}
          style={{
            display: 'block',
            borderRadius: '50%',
            boxShadow: isSpinning
              ? '0 0 32px rgba(0,200,255,.6), 0 0 64px rgba(0,200,255,.2)'
              : '0 0 16px rgba(0,200,255,.2)',
            transition: 'box-shadow .3s',
          }}
        />
      </div>

      {/* Spin Button */}
      <div style={{ marginTop: 24, textAlign: 'center' }}>
        <button
          style={spinButtonStyle}
          onClick={() => {
            if (hasFreeSpin) {
              doSpin();
            } else {
              // Show AP cost confirmation before deducting
              setShowApConfirm(true);
            }
          }}
          disabled={btnDisabled}
        >
          {isSpinning
            ? 'Spinning…'
            : hasFreeSpin
              ? '🎰 FREE SPIN'
              : '🎰 SPIN (50 AP)'}
        </button>

        {/* AP-cost confirmation banner */}
        {showApConfirm && !isSpinning && (
          <div style={{
            marginTop: 12,
            padding: '12px 16px',
            background: 'rgba(255,179,0,0.10)',
            border: '1px solid rgba(255,179,0,0.35)',
            borderRadius: 10,
            fontSize: 13,
            color: '#FFB300',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            gap: 10,
          }}>
            <span>⚡ This spin will cost <strong>50 AP</strong> from your balance.</span>
            <div style={{ display: 'flex', gap: 10 }}>
              <button
                onClick={() => { setShowApConfirm(false); doSpin(); }}
                style={{
                  background: '#FFB300', color: 'var(--ah-bg)', border: 'none',
                  padding: '7px 20px', borderRadius: 8, fontWeight: 700,
                  fontSize: 13, cursor: 'pointer',
                }}
              >
                Yes, spend 50 AP
              </button>
              <button
                onClick={() => setShowApConfirm(false)}
                style={{
                  background: 'transparent', color: 'var(--ah-text2)',
                  border: '1px solid var(--ah-text2)', padding: '7px 16px',
                  borderRadius: 8, fontWeight: 600, fontSize: 13, cursor: 'pointer',
                }}
              >
                Cancel
              </button>
            </div>
          </div>
        )}

        {!hasFreeSpin && countdown && !isSpinning && !showApConfirm && (
          <p style={{
            marginTop: 8,
            fontSize: 12,
            color: 'var(--ah-text2)',
          }}>
            Free spin resets in {countdown}
          </p>
        )}
      </div>

      {error && (
        <p style={{
          marginTop: 14,
          color: '#ff5555',
          fontSize: 13,
          textAlign: 'center',
        }}>
          {error}
        </p>
      )}

      {/* Prize Result Card */}
      {showResult && lastPrize && currentPrizeObj && (
        <div style={{
          marginTop: 28,
          width: '100%',
          maxWidth: 460,
          background: `linear-gradient(135deg, ${hexToRgba(currentPrizeObj.color, 0.12)} 0%, rgba(7,11,22,0.95) 100%)`,
          border: `1px solid ${hexToRgba(currentPrizeObj.color, 0.4)}`,
          borderRadius: 16,
          padding: '24px 20px',
          textAlign: 'center',
          animation: 'swPop .45s cubic-bezier(.34,1.56,.64,1)',
          boxShadow: `0 0 24px ${hexToRgba(currentPrizeObj.color, 0.25)}`,
        }}>
          <div style={{ fontSize: 48, lineHeight: 1, marginBottom: 8 }}>
            {prizeEmoji(lastPrize.key || lastPrize.prize_key)}
          </div>
          <div style={{
            fontFamily: "'Orbitron', 'Inter', sans-serif",
            fontSize: 22,
            fontWeight: 800,
            color: currentPrizeObj.color,
            marginBottom: 4,
          }}>
            {currentPrizeObj.label}
          </div>
          {prizeNumber > 0 && (
            <div style={{
              fontFamily: "'Orbitron', monospace",
              fontSize: 32,
              fontWeight: 800,
              color: currentPrizeObj.color,
              marginBottom: 4,
            }}>
              {countUp.toLocaleString()}
            </div>
          )}
          <div style={{
            fontSize: 12,
            color: 'var(--ah-text2)',
            marginTop: 6,
          }}>
            Added to your balance!
          </div>
        </div>
      )}

      {/* Spin History */}
      {history.length > 0 && (
        <div style={{
          marginTop: 28,
          width: '100%',
          maxWidth: 500,
        }}>
          <p style={{
            fontSize: 11,
            color: 'var(--ah-text2)',
            textTransform: 'uppercase',
            letterSpacing: 1,
            marginBottom: 8,
            textAlign: 'center',
          }}>
            Recent Spins
          </p>
          <div style={{
            display: 'flex',
            justifyContent: 'center',
            flexWrap: 'wrap',
            gap: 8,
          }}>
            {history.map((spin, i) => {
              // Backend history rows use prize_type as the key field
              const key = spin.prize?.key || spin.prize_type || spin.prize_key || spin.key || 'try_again';
              const p = PRIZES.find(x => x.key === key) || PRIZES[PRIZES.length - 1];
              return (
                <div key={i} style={{
                  background: hexToRgba(p.color, 0.12),
                  border: `1px solid ${hexToRgba(p.color, 0.3)}`,
                  borderRadius: 20,
                  padding: '4px 12px',
                  fontSize: 12,
                  color: p.color,
                  fontWeight: 600,
                  display: 'flex',
                  alignItems: 'center',
                  gap: 4,
                }}>
                  <span>{prizeEmoji(key)}</span>
                  <span>{spin.prize_label || p.label}</span>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
    </>
  );
}
