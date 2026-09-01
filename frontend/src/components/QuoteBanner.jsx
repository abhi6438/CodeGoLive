export default function QuoteBanner({ quote, variant = "default", emoji, className = "" }) {
  if (!quote) return null;
  return (
    <div className={`qb-banner qb-banner--${variant} ${className}`} role="status" aria-live="polite">
      {emoji && <span className="qb-emoji" aria-hidden="true">{emoji}</span>}
      <span className="qb-text">{quote}</span>
    </div>
  );
}
