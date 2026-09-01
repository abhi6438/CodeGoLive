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
