export const BASE_XP = 20;
export const BASE_AP = 10;

export const TIERS = [
  { min: 27, key: 'LIGHTNING', label: '⚡ LIGHTNING', mult: 5,   color: '#00C8FF' },
  { min: 24, key: 'SWIFT',     label: '🎯 SWIFT',     mult: 3,   color: '#00E676' },
  { min: 18, key: 'SHARP',     label: '✓ SHARP',      mult: 2,   color: '#FFB300' },
  { min: 8,  key: 'STEADY',    label: '— STEADY',     mult: 1,   color: '#A0B8D0' },
  { min: 1,  key: 'SLOW',      label: '🐢 SLOW',      mult: 0.5, color: '#607080' },
  { min: 0,  key: 'MISS',      label: '✗ MISS',       mult: 0,   color: '#3A4A68' },
];

export function getTimeTier(timeRemaining) {
  for (const tier of TIERS) {
    if (timeRemaining >= tier.min) return tier;
  }
  return TIERS[TIERS.length - 1];
}

export function getComboMultiplier(streak) {
  if (streak >= 5) return 2.0;
  if (streak >= 3) return 1.5;
  return 1.0;
}

export function getComboLabel(streak) {
  if (streak >= 5) return '⚡ INFERNO';
  if (streak >= 3) return '🔥 CHAIN';
  return null;
}

export function calcEarned(timeRemaining, streak, correct) {
  const tier = getTimeTier(timeRemaining);
  if (!correct || tier.key === 'MISS') {
    return { xp: 0, ap: 0, timeMult: 0, comboMult: 1, tier, comboLabel: null };
  }
  const newStreak = streak + 1;
  const comboMult = getComboMultiplier(newStreak);
  const comboLabel = getComboLabel(newStreak);
  return {
    xp: Math.round(BASE_XP * tier.mult * comboMult),
    ap: Math.round(BASE_AP * tier.mult * comboMult),
    timeMult: tier.mult,
    comboMult,
    tier,
    comboLabel,
    newStreak,
  };
}
