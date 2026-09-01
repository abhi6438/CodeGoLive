import PropTypes from "prop-types";

/**
 * QuoteBanner — contextual motivational callout for CodeGoLive.
 *
 * Props:
 *   quote   {string}  — the quote text (use a QUOTES.* constant)
 *   variant {string}  — "default" | "success" | "warning" | "error"
 *   emoji   {string}  — optional leading emoji
 */
export default function QuoteBanner({ quote, variant = "default", emoji, className = "" }) {
  if (!quote) return null;
  return (
    <div className={`qb-banner qb-banner--${variant} ${className}`} role="status" aria-live="polite">
      {emoji && <span className="qb-emoji" aria-hidden="true">{emoji}</span>}
      <span className="qb-text">{quote}</span>
    </div>
  );
}

QuoteBanner.propTypes = {
  quote:     PropTypes.string.isRequired,
  variant:   PropTypes.oneOf(["default", "success", "warning", "error"]),
  emoji:     PropTypes.string,
  className: PropTypes.string,
};
