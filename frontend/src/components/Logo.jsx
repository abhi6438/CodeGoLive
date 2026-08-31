/**
 * CodeGoLive Logo mark — a terminal ">" prompt with a cursor underscore
 * inside a rounded-square gradient badge. Size is controlled by the
 * `size` prop (default 32). Pass `textSize` to show wordmark next to it.
 */
export default function Logo({ size = 32, showText = false, textClass = "" }) {
  const id = `cgl-grad-${size}`;
  return (
    <span style={{ display: "inline-flex", alignItems: "center", gap: size * 0.28 + "px", lineHeight: 1 }}>
      <svg
        width={size}
        height={size}
        viewBox="0 0 32 32"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        aria-hidden="true"
        style={{ flexShrink: 0, borderRadius: size * 0.22 + "px", display: "block" }}
      >
        <defs>
          <linearGradient id={id} x1="0" y1="0" x2="32" y2="32" gradientUnits="userSpaceOnUse">
            <stop offset="0%" stopColor="#7c7dfa" />
            <stop offset="100%" stopColor="#3730a3" />
          </linearGradient>
        </defs>

        {/* Background */}
        <rect width="32" height="32" rx="7" fill={`url(#${id})`} />

        {/* Subtle inner glow at top-left */}
        <ellipse cx="8" cy="7" rx="10" ry="8" fill="white" fillOpacity="0.07" />

        {/* ">" terminal chevron */}
        <path
          d="M9.5 11.5 L17.5 16 L9.5 20.5"
          stroke="white"
          strokeWidth="2.6"
          strokeLinecap="round"
          strokeLinejoin="round"
        />

        {/* Cursor underscore — the "live" indicator */}
        <rect x="19.5" y="19" width="5" height="2.6" rx="1.3" fill="white" fillOpacity="0.85" />

        {/* Small live dot — top-right, pulsing feel */}
        <circle cx="25.5" cy="7.5" r="2.2" fill="#a5f3fc" fillOpacity="0.9" />
      </svg>

      {showText && (
        <span className={textClass} style={{ fontWeight: 700, letterSpacing: "-0.01em" }}>
          CodeGoLive
        </span>
      )}
    </span>
  );
}
