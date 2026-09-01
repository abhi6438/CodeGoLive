/**
 * QuoteCard — premium motivational quote component for CodeGoLive.
 * Props: quote (string), variant ("default"|"success"|"warning"|"error"|"hero"),
 *        emoji (string, optional), className (string), style (object)
 */
export default function QuoteCard({
  quote,
  variant = "default",
  emoji,
  className = "",
  style,
}) {
  if (!quote) return null;

  const variantClass =
    variant !== "default" ? ` qc--${variant}` : "";

  return (
    <div
      className={`qc${variantClass} ${className}`.trim()}
      style={style}
      role="note"
      aria-label="Motivational quote"
    >
      <span className="qc-mark" aria-hidden="true">&ldquo;</span>
      <p className="qc-quote">{quote}</p>
      <div className="qc-footer">
        {emoji && (
          <span className="qc-emoji" aria-hidden="true">
            {emoji}
          </span>
        )}
        <div className="qc-rule" />
        <span className="qc-brand">CodeGoLive</span>
      </div>
    </div>
  );
}
