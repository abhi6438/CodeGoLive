/**
 * QuoteCard — compact motivational strip for CodeGoLive.
 * Single-row: mark · quote · [emoji] · rule · brand
 * Props: quote, variant ("default"|"success"|"warning"|"error"|"hero"|"glass"),
 *        emoji, className, style
 */
export default function QuoteCard({
  quote,
  variant = "default",
  emoji,
  className = "",
  style,
}) {
  if (!quote) return null;
  const cls = ["qc", variant !== "default" ? `qc--${variant}` : "", className]
    .filter(Boolean).join(" ");
  return (
    <div className={cls} style={style} role="note" aria-label="Motivational quote">
      <span className="qc-mark" aria-hidden="true">&ldquo;</span>
      <span className="qc-quote">{quote}</span>
      {emoji && <span className="qc-emoji" aria-hidden="true">{emoji}</span>}
      <div className="qc-rule" aria-hidden="true" />
      <span className="qc-brand" aria-hidden="true">CodeGoLive</span>
    </div>
  );
}

/**
 * QuoteBand — full-width motivational strip.
 * Breaks out of any max-width container; arms extend into page margins.
 * Props: quote, className
 */
export function QuoteBand({ quote, className = "" }) {
  if (!quote) return null;
  return (
    <div className={`qb${className ? " " + className : ""}`} role="note" aria-label="Motivational quote">
      <div className="qb-arm qb-arm--l" aria-hidden="true" />
      <div className="qb-inner">
        <span className="qb-open" aria-hidden="true">&ldquo;</span>
        <span className="qb-text">{quote}</span>
        <div className="qb-dot" aria-hidden="true" />
        <span className="qb-brand" aria-hidden="true">CodeGoLive</span>
      </div>
      <div className="qb-arm qb-arm--r" aria-hidden="true" />
    </div>
  );
}
